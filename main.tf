#    Copyright 2022 Leonardo Andres Morales

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

locals {
  resouce_name    = var.name_prefix != null ? "${var.name_prefix}-log-fw" : "log-fw"
  source_type     = split("/", var.source_id)[0]
  source_id       = split("/", var.source_id)[1]
  writer_identity = concat([for i in google_logging_organization_sink.forwarded_logs : i.writer_identity], [for i in google_logging_folder_sink.forwarded_logs : i.writer_identity])[0]
}

# Zip compress the Cloud Function code
data "archive_file" "gcf_log_proxy" {
  type        = "zip"
  source_dir  = "${path.module}/service"
  output_path = ".terraform/.tmp/log_proxy.zip"
}

# Create a bucket to store the Cloud Function zipped code
resource "google_storage_bucket" "cloud_functions" {
  project  = var.target_project_id
  name     = "${var.target_project_id}-${local.resouce_name}"
  location = var.region
}

# Upload the Cloud Function zipped code
# OBS: use MD5 to enforce recreation if it has changed
resource "google_storage_bucket_object" "cloud_function" {
  name   = "log_proxy.${filemd5(data.archive_file.gcf_log_proxy.output_path)}.zip"
  bucket = google_storage_bucket.cloud_functions.name
  source = data.archive_file.gcf_log_proxy.output_path
}

# Create a Service Account to run the service
resource "google_service_account" "agent" {
  project      = var.target_project_id
  account_id   = "${local.resouce_name}-agent"
  display_name = "Logs Forwarder Agent"
}

# Create the Cloud Function
resource "google_cloudfunctions_function" "function" {
  project               = var.target_project_id
  name                  = local.resouce_name
  description           = "Forward Logs to a Project"
  entry_point           = "proxy_log_entry"
  runtime               = "python39"
  region                = var.region
  trigger_http          = true
  service_account_email = google_service_account.agent.email
  source_archive_bucket = google_storage_bucket.cloud_functions.name
  source_archive_object = google_storage_bucket_object.cloud_function.name
  environment_variables = {
    TARGET_PROJECT_ID = var.target_project_id
    LOGGER_NAME       = var.logger_name
  }
}

# Create the topic to receive the forwarded logs
resource "google_pubsub_topic" "forwarded_logs" {
  project = var.target_project_id
  name    = local.resouce_name
}

# Create the subscription that will send the logs to the function
resource "google_pubsub_subscription" "forwarded_logs" {
  project              = var.target_project_id
  name                 = local.resouce_name
  topic                = google_pubsub_topic.forwarded_logs.name
  ack_deadline_seconds = 20
  push_config {
    push_endpoint = google_cloudfunctions_function.function.https_trigger_url
    oidc_token {
      service_account_email = google_service_account.agent.email
    }
  }
}

# Organization Sink
resource "google_logging_organization_sink" "forwarded_logs" {
  count            = local.source_type == "organizations" ? 1 : 0
  name             = local.resouce_name
  description      = "Forward logs to ${var.target_project_id} project"
  org_id           = local.source_id
  destination      = "pubsub.googleapis.com/${google_pubsub_topic.forwarded_logs.id}"
  filter           = var.log_filter
  include_children = var.include_children
}

# Folder Sink
resource "google_logging_folder_sink" "forwarded_logs" {
  count            = local.source_type == "folders" ? 1 : 0
  name             = local.resouce_name
  description      = "Forward logs to ${var.target_project_id} project"
  folder           = local.source_id
  destination      = "pubsub.googleapis.com/${google_pubsub_topic.forwarded_logs.id}"
  filter           = var.log_filter
  include_children = var.include_children
}

###################### IAM ######################

# Grant Log Writer permissions to the Cloud Function Service Account
resource "google_project_iam_member" "cloud_function_log_writer" {
  project = var.target_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.agent.email}"
}

# Grant Cloud Function execution
resource "google_cloudfunctions_function_iam_member" "cloud_function_invoker" {
  project        = var.target_project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.agent.email}"
}

# Grant permission to write to the pubsub topic
resource "google_pubsub_topic_iam_member" "forwarded_logs" {
  project = var.target_project_id
  topic   = google_pubsub_topic.forwarded_logs.name
  role    = "roles/pubsub.publisher"
  member  = local.writer_identity
}

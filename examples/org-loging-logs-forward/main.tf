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

module "logging_project" {
  source            = "terraform-google-modules/project-factory/google"
  version           = "~> 13.0"
  name              = "my-org-logging-project"
  random_project_id = true
  org_id            = var.org_id
  billing_account   = var.billing_account
  activate_apis     = ["pubsub.googleapis.com", "cloudfunctions.googleapis.com", "cloudbuild.googleapis.com"]
}

module "login_logs_org_forwarder" {
  source            = "../../"
  source_id         = "organizations/${var.org_id}"
  target_project_id = module.logging_project.project_id
  name_prefix       = "login-logs"
  region            = "us-central1"
  log_filter        = "protoPayload.serviceName=login.googleapis.com"
}

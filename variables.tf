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

variable "source_id" {
  description = "Organization or Folder ID where logs are generated (format: organizations/<ID> or folders/<ID>)"
  type        = string
}

variable "target_project_id" {
  description = "Target Project ID where the Organization logs will be written to Cloud Logging"
  type        = string
}

variable "region" {
  description = "Region where resources to forward the logs will be created (check https://cloud.google.com/compute/docs/regions-zones)"
  type        = string
}

variable "name_prefix" {
  description = "Resources prefix"
  type        = string
  default     = null
}

variable "log_filter" {
  description = "Filter for the logs that will be forwarded (default: same as _Required)"
  type        = string
  default     = <<-EOT
    LOG_ID("cloudaudit.googleapis.com/activity") 
    OR LOG_ID("externalaudit.googleapis.com/activity") 
    OR LOG_ID("cloudaudit.googleapis.com/system_event") 
    OR LOG_ID("externalaudit.googleapis.com/system_event") 
    OR LOG_ID("cloudaudit.googleapis.com/access_transparency") 
    OR LOG_ID("externalaudit.googleapis.com/access_transparency")
  EOT
}

variable "include_children" {
  description = "Forward children logs (ATTENTION: this may create a recursive forwarding)"
  type        = bool
  default     = false
}

variable "logger_name" {
  description = "Name for the logger that will write log entries in the target Project's cloud logging"
  type        = string
  default     = "logsforward"
}

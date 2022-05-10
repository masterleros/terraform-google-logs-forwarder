## Requirements

| Name | Version |
|------|---------|
| archive | 2.2.0 |
| google | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| archive | 2.2.0 |
| google | ~> 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| include\_children | Forward children logs (ATTENTION: this may create a recursive forwarding) | `bool` | `false` | no |
| log\_filter | Filter for the logs that will be forwarded (default: same as \_Required) | `string` | `"LOG_ID(\"cloudaudit.googleapis.com/activity\") \nOR LOG_ID(\"externalaudit.googleapis.com/activity\") \nOR LOG_ID(\"cloudaudit.googleapis.com/system_event\") \nOR LOG_ID(\"externalaudit.googleapis.com/system_event\") \nOR LOG_ID(\"cloudaudit.googleapis.com/access_transparency\") \nOR LOG_ID(\"externalaudit.googleapis.com/access_transparency\")\n"` | no |
| logger\_name | Name for the logger that will write log entries in the target Project's cloud logging | `string` | `"logsforward"` | no |
| name\_prefix | Resources prefix | `string` | `null` | no |
| region | Region where resources to forward the logs will be created (check https://cloud.google.com/compute/docs/regions-zones) | `string` | n/a | yes |
| source\_id | Organization or Folder ID where logs are generated (format: organizations/<ID> or folders/<ID>) | `string` | n/a | yes |
| target\_project\_id | Target Project ID where the Organization logs will be written to Cloud Logging | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| logger\_name | Name for the logger that writes log entries in the target Project's cloud logging |
| service\_account | Service Account created to run the proxy service |
| writer\_identity | Writer Identity used for the log forwarder |


# ----------------------------------------
# General Configuration
# ----------------------------------------

variable "region" {
  description = "AWS region for the provider. Defaults to ap-southeast-2 if not specified."
  type        = string
  default     = "ap-southeast-2"

  validation {
    condition     = can(regex("^([a-z]{2}-[a-z]+-\\d{1})$", var.region))
    error_message = "Invalid AWS region format. Example: 'us-east-1', 'ap-southeast-2'."
  }
}

variable "name" {
  description = "Name for the associated resources"
  type        = string
}

variable "suffix" {
  description = "Optional suffix for resource names"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# ----------------------------------------
# Logging Configuration
# ----------------------------------------

variable "log_retention_days" {
  description = "Retention period for CloudWatch logs in days"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3650
    error_message = "log_retention_days must be between 1 and 3650."
  }
}

# ----------------------------------------
# SQS Configuration
# ----------------------------------------

variable "sqs_message_retention_seconds" {
  description = "Retention period for messages in the SQS queue (in seconds)"
  type        = number
  default     = 86400 # 1 day (24 hours)
}

# ----------------------------------------
# CloudWatch Alarm Configuration
# ----------------------------------------

variable "metric_alarms" {
  description = "A list of CloudWatch metric alarms. Supports both standard and metric query-based alarms."
  type = list(object({
    alarm_name          = string
    alarm_description   = optional(string)
    actions_enabled     = optional(bool, true)
    comparison_operator = string
    evaluation_periods  = number
    threshold           = optional(number)
    unit                = optional(string)
    treat_missing_data  = optional(string)
    datapoints_to_alarm = optional(number)
    threshold_metric_id = optional(string)

    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])

    dimensions                            = optional(map(string), {})
    evaluate_low_sample_count_percentiles = optional(string)

    metric_name        = optional(string)
    namespace          = optional(string)
    statistic          = optional(string)
    extended_statistic = optional(string)
    period             = optional(number)

    metric_query = optional(list(object({
      id          = string
      expression  = optional(string)
      label       = optional(string)
      return_data = optional(bool, false)

      metric = optional(object({
        metric_name = string
        namespace   = string
        period      = number
        stat        = string
        unit        = optional(string)
        dimensions  = optional(map(string), {})
      }))
    })))
  }))

  default = []
}

# ----------------------------------------
# Slack Notification Configuration
# ----------------------------------------

variable "slack_webhook_url" {
  description = "Slack Webhook URL for sending notifications"
  type        = string
}

variable "message_title" {
  description = "Title of the message sent to Slack"
  type        = string
}

variable "message_fields" {
  description = "Comma-separated list of message fields"
  type        = string
}

variable "status_colors" {
  description = "Mapping of status to Slack colors"
  type        = string
}

variable "status_field" {
  description = "Field in the message that represents status"
  type        = string
}

variable "status_mapping" {
  description = "Mapping of status values to general categories"
  type        = string
}

# ----------------------------------------
# AWS Secrets Manager Configuration
# ----------------------------------------

variable "secrets_recovery_window" {
  description = "Number of days before the secret is permanently deleted. Set to 0 for immediate deletion."
  type        = number
  default     = 7
}

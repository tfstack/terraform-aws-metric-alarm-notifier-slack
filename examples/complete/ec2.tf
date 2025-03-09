module "ec2_high_cpu_usage" {
  source = "../.."

  region = data.aws_region.current.name
  name   = "${local.name}-ec2-high-cpu-usage"
  suffix = random_string.suffix.result

  metric_alarms = [
    {
      alarm_name          = "high-cpu-usage"
      alarm_description   = "Triggered when CPU utilization exceeds threshold"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 2
      threshold           = 80
      period              = 120
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      statistic           = "Average"

      insufficient_data_actions = []
      dimensions                = { InstanceId = module.vpc.jumphost_instance_id }
    }
  ]

  slack_webhook_url = var.slack_webhook_url
  message_title     = "High CPU Usage Alert"
  message_fields = join(",", [
    "time",
    "region",
    "accountId",
    "alarmData.alarmName",
    "alarmData.state.value",
    "alarmData.previousState.value",
    "alarmData.configuration.metrics"
  ])
  status_colors = join(",", [
    "CPU_OVER_THRESHOLD:#E01E5A",
    "CPU_NORMAL:#2EB67D"
  ])
  status_field = "alarmData.state.value"
  status_mapping = join(",", [
    "ALARM:CPU_OVER_THRESHOLD",
    "OK:CPU_NORMAL"
  ])
  secrets_recovery_window = 0
}

module "ec2_status_check" {
  source = "../.."

  region = data.aws_region.current.name
  name   = "${local.name}-ec2-status-check"
  suffix = random_string.suffix.result

  metric_alarms = [
    {
      alarm_name          = "ec2-status-check"
      alarm_description   = "Triggered when EC2 status check fails"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 2
      threshold           = 1
      period              = 300
      metric_name         = "StatusCheckFailed"
      namespace           = "AWS/EC2"
      statistic           = "Maximum"
      unit                = "Count"

      insufficient_data_actions = []
      dimensions                = { InstanceId = module.vpc.jumphost_instance_id }

      treat_missing_data = "breaching"
    }
  ]

  slack_webhook_url = var.slack_webhook_url
  message_title     = "System Status Checks"
  message_fields = join(",", [
    "time",
    "region",
    "accountId",
    "alarmData.alarmName",
    "alarmData.state.value",
    "alarmData.previousState.value",
    "alarmData.configuration.metrics"
  ])
  status_colors = join(",", [
    "SYSTEM_CRITICAL:#E01E5A",
    "SYSTEM_OK:#2EB67D"
  ])
  status_field = "alarmData.state.value"
  status_mapping = join(",", [
    "ALARM:SYSTEM_CRITICAL",
    "OK:SYSTEM_OK"
  ])
  secrets_recovery_window = 0
}

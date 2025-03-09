module "ebs_throughput_alarm" {
  source = "../.."

  region = data.aws_region.current.name
  name   = "${local.name}-ebs-throughput-alert"
  suffix = random_string.suffix.result

  metric_alarms = [
    {
      alarm_name          = "ebs-throughput-alert"
      alarm_description   = "Alarm when EBS volume exceeds 100MB throughput"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 3
      threshold           = 100000000 # 100MB threshold (100MB = 100,000,000 bytes)
      period              = 300       # 5-minute period
      metric_name         = "VolumeReadBytes"
      namespace           = "AWS/EBS"
      statistic           = "Average"
      unit                = "Bytes"

      dimensions = {
        VolumeId = data.aws_ebs_volume.jumphost.volume_id
      }

      insufficient_data_actions = []
    }
  ]

  slack_webhook_url = var.slack_webhook_url
  message_title     = "EBS Throughput Alert"
  message_fields = join(",", [
    "time",
    "region",
    "accountId",
    "alarmData.alarmName",
    "alarmData.state.value",
    "alarmData.configuration.metrics"
  ])
  status_colors = join(",", [
    "THROUGHPUT_HIGH:#E01E5A",
    "THROUGHPUT_NORMAL:#2EB67D"
  ])
  status_field = "alarmData.state.value"
  status_mapping = join(",", [
    "ALARM:THROUGHPUT_HIGH",
    "OK:THROUGHPUT_NORMAL"
  ])
  secrets_recovery_window = 0
}

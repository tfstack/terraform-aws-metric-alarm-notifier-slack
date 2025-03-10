module "lb_latency_alarm" {
  source = "../.."

  region = data.aws_region.current.name
  name   = "${local.name}-lb-latency-alert"
  suffix = random_string.suffix.result

  metric_alarms = [
    {
      alarm_name          = "lb-latency-alert"
      alarm_description   = "Alarm when Load Balancer Latency exceeds 100 seconds"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 3
      threshold           = 100
      period              = 60
      metric_name         = "Latency"
      namespace           = "AWS/ELB"
      statistic           = "Average"
      unit                = "Seconds"

      dimensions = {
        LoadBalancerName = "alb_name"
      }
    }
  ]

  slack_webhook_url = var.slack_webhook_url
  message_title     = "Load Balancer Latency Alert"
  message_fields = join(",", [
    "time",
    "region",
    "accountId",
    "alarmData.alarmName",
    "alarmData.state.value",
    "alarmData.configuration.metrics"
  ])
  status_colors = join(",", [
    "LATENCY_HIGH:#E01E5A",
    "LATENCY_NORMAL:#2EB67D"
  ])
  status_field = "alarmData.state.value"
  status_mapping = join(",", [
    "ALARM:LATENCY_HIGH",
    "OK:LATENCY_NORMAL"
  ])
  secrets_recovery_window = 0
}

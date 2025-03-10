module "billing_alert" {
  source = "../.."

  region = "us-east-1" # billing metrics only available in us-east-1
  name   = "${local.name}-billing-alert"
  suffix = random_string.suffix.result

  metric_alarms = [
    {
      alarm_name          = "unusual-spending-increase"
      alarm_description   = "Triggered when AWS spending increases unusually"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      threshold           = 200
      period              = 21600
      metric_name         = "EstimatedCharges"
      namespace           = "AWS/Billing"
      statistic           = "Maximum"
      unit                = "None"

      insufficient_data_actions = []
      dimensions                = { Currency = "USD" } # only in USD
    }
  ]

  slack_webhook_url = var.slack_webhook_url
  message_title     = "Unusual AWS Spending Alert"
  message_fields = join(",", [
    "time",
    "region",
    "accountId",
    "alarmData.alarmName",
    "alarmData.configuration.metrics[0].metricStat.stat",
    "alarmData.previousState.value",
    "alarmData.configuration.metrics"
  ])
  status_colors = join(",", [
    "SPENDING_HIGH:#E01E5A",
    "SPENDING_NORMAL:#2EB67D"
  ])
  status_field = "alarmData.state.value"
  status_mapping = join(",", [
    "ALARM:SPENDING_HIGH",
    "OK:SPENDING_NORMAL"
  ])
  secrets_recovery_window = 0
}

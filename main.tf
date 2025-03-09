# ----------------------------------------
# Data Sources
# ----------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ----------------------------------------
# Local Variables
# ----------------------------------------
locals {
  base_name    = length(var.suffix) > 0 ? "${var.name}-${var.suffix}" : var.name
  files_notify = fileset("${path.module}/external/notify", "**")
  hash_notify  = md5(join("", [for f in local.files_notify : "${f}:${filemd5("${path.module}/external/notify/${f}")}"]))
}

# ----------------------------------------
# AWS Secrets Manager
# ----------------------------------------
resource "aws_secretsmanager_secret" "this" {
  name                    = "${local.base_name}-slack-webhook-url"
  description             = "Stores the Slack webhook URL for CloudWatch alarm notifications"
  recovery_window_in_days = var.secrets_recovery_window

  tags = merge(var.tags, { Name = "${local.base_name}-slack-webhook-url" })
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({ webhook_url = var.slack_webhook_url })
}

# ----------------------------------------
# AWS SQS Dead Letter Queue (DLQ)
# ----------------------------------------
resource "aws_sqs_queue" "dlq" {
  name                      = "${local.base_name}-cloudwatch-slack-dlq"
  message_retention_seconds = var.sqs_message_retention_seconds

  tags = merge(var.tags, { Name = "${local.base_name}-cloudwatch-slack-dlq" })
}

# ----------------------------------------
# AWS Lambda Function for Slack Notifications
# ----------------------------------------
resource "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/external/notify"
  output_path = "${path.module}/external/notify.zip"
}

resource "aws_lambda_function" "this" {
  function_name = "${local.base_name}-slack-notify"
  runtime       = "python3.13"
  handler       = "handler.lambda_handler"
  timeout       = 30
  role          = aws_iam_role.lambda.arn

  environment {
    variables = {
      SECRET_NAME    = aws_secretsmanager_secret.this.name
      DLQ_URL        = aws_sqs_queue.dlq.url
      MESSAGE_TITLE  = var.message_title
      MESSAGE_FIELDS = var.message_fields
      STATUS_COLORS  = var.status_colors
      STATUS_FIELD   = var.status_field
      STATUS_MAPPING = var.status_mapping
    }
  }

  filename         = archive_file.this.output_path
  source_code_hash = local.hash_notify

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  depends_on = [
    archive_file.this,
    aws_cloudwatch_log_group.lambda
  ]

  tags = merge(var.tags, { Name = "${local.base_name}-slack-notify" })
}

# ----------------------------------------
# AWS IAM Roles and Policies
# ----------------------------------------
resource "aws_iam_role" "lambda" {
  name = local.base_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, { Name = local.base_name })
}

resource "aws_iam_policy" "lambda" {
  name = local.base_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.this.arn
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.dlq.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

# ----------------------------------------
# CloudWatch Metric Alarm and Permissions
# ----------------------------------------
resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = length(var.metric_alarms) > 0 ? { for alarm in var.metric_alarms : alarm.alarm_name => alarm } : {}

  alarm_name          = "${local.base_name}-${each.value.alarm_name}"
  alarm_description   = lookup(each.value, "alarm_description", null)
  actions_enabled     = lookup(each.value, "actions_enabled", true)
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  threshold           = lookup(each.value, "threshold", null)
  unit                = lookup(each.value, "unit", null)
  treat_missing_data  = lookup(each.value, "treat_missing_data", null)
  datapoints_to_alarm = lookup(each.value, "datapoints_to_alarm", null)
  threshold_metric_id = lookup(each.value, "threshold_metric_id", null)

  alarm_actions = [aws_lambda_function.this.arn]
  ok_actions    = [aws_lambda_function.this.arn]

  insufficient_data_actions = lookup(each.value, "insufficient_data_actions", [])

  dimensions = lookup(each.value, "metric_query", null) == null ? lookup(each.value, "dimensions", {}) : null

  evaluate_low_sample_count_percentiles = lookup(each.value, "evaluate_low_sample_count_percentiles", null)

  period             = lookup(each.value, "metric_query", null) == null ? each.value.period : null
  metric_name        = lookup(each.value, "metric_query", null) == null ? each.value.metric_name : null
  namespace          = lookup(each.value, "metric_query", null) == null ? each.value.namespace : null
  statistic          = lookup(each.value, "metric_query", null) == null ? lookup(each.value, "statistic", null) : null
  extended_statistic = lookup(each.value, "metric_query", null) == null ? lookup(each.value, "extended_statistic", null) : null

  dynamic "metric_query" {
    for_each = lookup(each.value, "metric_query", null) != null ? each.value.metric_query : []
    content {
      id          = metric_query.value.id
      expression  = lookup(metric_query.value, "expression", null)
      label       = lookup(metric_query.value, "label", null)
      return_data = lookup(metric_query.value, "return_data", false)

      dynamic "metric" {
        for_each = lookup(metric_query.value, "metric", null) != null ? [metric_query.value.metric] : []
        content {
          metric_name = metric.value.metric_name
          namespace   = metric.value.namespace
          period      = metric.value.period
          stat        = metric.value.stat
          unit        = lookup(metric.value, "unit", null)
          dimensions  = lookup(metric.value, "dimensions", {})
        }
      }
    }
  }

  tags = merge(var.tags, { Name = "${local.base_name}-${each.value.alarm_name}" })
}

resource "aws_lambda_permission" "cw_invoke" {
  for_each = aws_cloudwatch_metric_alarm.this

  statement_id  = "AllowExecutionFromCloudWatch-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = each.value.arn
}

# ----------------------------------------
# CloudWatch Logs
# ----------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.base_name}-slack-notify"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, { Name = "${local.base_name}-slack-notify" })
}

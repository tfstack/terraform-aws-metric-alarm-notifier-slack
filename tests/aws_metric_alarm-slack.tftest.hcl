run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "test_ec2_high_cpu_usage" {
  variables {
    region = run.setup.region
    name   = "test-ec2-high-cpu-usage"
    suffix = run.setup.suffix

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
        dimensions                = { InstanceId = "i-0a359e9400257884d" }
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

    tags = {
      Environment = "test"
      Project     = "example-project"
    }
  }

  assert {
    condition     = aws_sqs_queue.dlq.name == "test-ec2-high-cpu-usage-${run.setup.suffix}-cloudwatch-slack-dlq"
    error_message = "SQS DLQ name does not match expected value."
  }

  assert {
    condition     = fileexists(archive_file.this.output_path)
    error_message = "The expected ZIP file does not exist at ${archive_file.this.output_path}."
  }

  assert {
    condition     = filesha256(archive_file.this.output_path) != ""
    error_message = "The ZIP file exists but appears to be empty or corrupted."
  }

  assert {
    condition     = archive_file.this.output_path == "${path.module}/external/notify.zip"
    error_message = "The output ZIP file path does not match the expected path."
  }

  assert {
    condition     = aws_lambda_function.this.function_name == "test-ec2-high-cpu-usage-${run.setup.suffix}-slack-notify"
    error_message = "Lambda function name does not match expected value."
  }

  assert {
    condition     = aws_iam_role.lambda.name == "test-ec2-high-cpu-usage-${run.setup.suffix}"
    error_message = "IAM role name does not match expected value."
  }

  assert {
    condition     = aws_iam_policy.lambda.name == "test-ec2-high-cpu-usage-${run.setup.suffix}"
    error_message = "IAM policy name does not match expected value."
  }

  assert {
    condition     = length(keys(aws_cloudwatch_metric_alarm.this)) > 0
    error_message = "No CloudWatch Metric Alarms were created. Ensure 'metric_alarms' is set correctly."
  }

  assert {
    condition = length(keys(aws_lambda_permission.cw_invoke)) > 0 ? anytrue([
      for key, permission in aws_lambda_permission.cw_invoke :
      permission.function_name == aws_lambda_function.this.function_name
    ]) : true
    error_message = "Lambda permission function name does not match expected value."
  }

  assert {
    condition     = aws_cloudwatch_log_group.lambda.name == "/aws/lambda/test-ec2-high-cpu-usage-${run.setup.suffix}-slack-notify"
    error_message = "CloudWatch log group for Lambda does not match expected value."
  }

  assert {
    condition     = aws_secretsmanager_secret.this.name == "test-ec2-high-cpu-usage-${run.setup.suffix}-slack-webhook-url"
    error_message = "Secrets Manager secret name does not match expected value."
  }

  assert {
    condition     = can(aws_secretsmanager_secret.this.name)
    error_message = "Secrets Manager secret was not created."
  }

  assert {
    condition     = can(aws_secretsmanager_secret_version.this.secret_id) && aws_secretsmanager_secret_version.this.secret_id == aws_secretsmanager_secret.this.id
    error_message = "Secrets Manager secret version does not match the expected secret."
  }
}

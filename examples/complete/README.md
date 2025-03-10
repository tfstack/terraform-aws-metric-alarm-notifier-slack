# Terraform Module: AWS CloudWatch Metric Alarm Notifier

## Overview

This Terraform module provisions AWS CloudWatch metric alarms and integrates them with AWS Lambda to send notifications to Slack. It sets up the required AWS resources, including CloudWatch alarms, Lambda functions, IAM roles, CloudWatch log groups, and AWS Secrets Manager for secure storage.

## Features

- Deploys **CloudWatch metric alarms** to monitor AWS resources.
- Integrates with **AWS Lambda** to process alarm events and send alerts to Slack.
- Uses **AWS Secrets Manager** for securely storing the Slack webhook URL.
- Provides **IAM roles and policies** with necessary permissions.
- Configures **CloudWatch Logs** for monitoring alarm notifications.

## Supported Metric Alarms

This module can monitor and trigger notifications for various AWS services, including:

- **EBS Throughput Alarm** (`ebs_throughput_alarm`): Alerts when EBS volume throughput exceeds a defined threshold.
- **EC2 High CPU Usage Alarm** (`ec2_high_cpu_usage`): Triggers when EC2 instance CPU utilization surpasses a specified limit.
- **EC2 Status Check Alarm** (`ec2_status_check`): Notifies when an EC2 instance fails its status check.
- **Load Balancer Latency Alarm** (`lb_latency_alarm`): Detects high latency on an application load balancer.

## Usage

```hcl
module "aws_metric_alarm_notifier" {
  source = "../.."

  region = data.aws_region.current.name
  name   = "ec2-high-cpu-usage"
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

  log_retention_days = 1
  secrets_recovery_window = 0

  tags = {
    Environment = "prod"
    Project     = "example-project"
  }
}
```

## Inputs

| Name                   | Type           | Description |
|------------------------|---------------|-------------|
| `region`              | string        | AWS region for deployment. |
| `name`                | string        | Base name for all resources. |
| `suffix`              | string        | Unique suffix for resource names. |
| `slack_webhook_url`   | string        | Slack webhook URL for notifications. |
| `message_title`       | string        | Title of the Slack message. |
| `message_fields`      | string        | Comma-separated list of fields to include in the message. |
| `status_colors`       | string        | Mapping of status values to Slack colors. |
| `status_field`        | string        | JSON field used to determine status. |
| `status_mapping`      | string        | Mapping of event states to status labels. |
| `log_retention_days`  | number        | Retention period for CloudWatch logs (default: `30`). |
| `secrets_recovery_window` | number   | Days before secret deletion (default: `7`). |
| `tags`               | map(string)   | Additional tags to apply to resources. |

## Outputs

| Name                        | Description |
|-----------------------------|-------------|
| `cloudwatch_alarm_arn`      | ARN of the CloudWatch metric alarm. |
| `lambda_function_arn`       | ARN of the Lambda function handling notifications. |
| `secretsmanager_secret_arn` | ARN of the AWS Secrets Manager secret storing the Slack webhook URL. |
| `cloudwatch_log_group`      | CloudWatch log group for Lambda logs. |

## Resources Created

- **AWS CloudWatch Metric Alarms**: Monitors AWS resources and triggers notifications.
- **AWS Lambda Function**: Processes alarm events and sends alerts to Slack.
- **AWS Secrets Manager**: Securely stores the Slack webhook URL.
- **IAM Roles and Policies**: Provides necessary permissions to Lambda and CloudWatch.
- **CloudWatch Logs**: Captures Lambda execution logs for monitoring.

## Notes

- CloudWatch metric alarms must be **defined by the user**.
- AWS Secrets Manager is **used for secure webhook storage**.
- The Lambda function is deployed using **Python 3.13** and expects a valid `handler.lambda_handler` entry point.

## License

MIT License

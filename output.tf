# ----------------------------------------
# CloudWatch Metric Alarm Outputs
# ----------------------------------------

output "cloudwatch_alarm_arns" {
  description = "ARNs of the created CloudWatch metric alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.arn }
}

output "cloudwatch_alarm_names" {
  description = "Names of the created CloudWatch metric alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.alarm_name }
}

# ----------------------------------------
# Lambda Function Outputs
# ----------------------------------------

output "lambda_function_arn" {
  description = "ARN of the Lambda function handling notifications"
  value       = aws_lambda_function.this.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function handling notifications"
  value       = aws_lambda_function.this.function_name
}

# ----------------------------------------
# CloudWatch Log Group Outputs
# ----------------------------------------

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for Lambda logs"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for Lambda logs"
  value       = aws_cloudwatch_log_group.lambda.arn
}

# ----------------------------------------
# SQS Dead Letter Queue (DLQ) Outputs
# ----------------------------------------

output "sqs_dlq_arn" {
  description = "ARN of the SQS Dead Letter Queue (DLQ)"
  value       = aws_sqs_queue.dlq.arn
}

output "sqs_dlq_url" {
  description = "URL of the SQS Dead Letter Queue (DLQ)"
  value       = aws_sqs_queue.dlq.url
}

# ----------------------------------------
# AWS Secrets Manager Outputs
# ----------------------------------------

output "secretsmanager_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret storing the Slack webhook URL"
  value       = aws_secretsmanager_secret.this.arn
}

output "secretsmanager_secret_name" {
  description = "Name of the AWS Secrets Manager secret storing the Slack webhook URL"
  value       = aws_secretsmanager_secret.this.name
}

# ----------------------------------------
# IAM Role and Policy Outputs
# ----------------------------------------

output "iam_role_lambda_arn" {
  description = "ARN of the IAM role assigned to the Lambda function"
  value       = aws_iam_role.lambda.arn
}

output "iam_policy_lambda_arn" {
  description = "ARN of the IAM policy assigned to the Lambda function"
  value       = aws_iam_policy.lambda.arn
}

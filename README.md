# terraform-aws-metric-alarm-notifier-slack

Terraform module to create a generic metric-based Slack notification system using CloudWatch Alarms

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.84.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.7.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.84.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [archive_file.this](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/resources/file) | resource |
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.this](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_iam_policy.lambda](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.cw_invoke](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/lambda_permission) | resource |
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.this](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/secretsmanager_secret_version) | resource |
| [aws_sqs_queue.dlq](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/resources/sqs_queue) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/5.84.0/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Retention period for CloudWatch logs in days | `number` | `30` | no |
| <a name="input_message_fields"></a> [message\_fields](#input\_message\_fields) | Comma-separated list of message fields | `string` | n/a | yes |
| <a name="input_message_title"></a> [message\_title](#input\_message\_title) | Title of the message sent to Slack | `string` | n/a | yes |
| <a name="input_metric_alarms"></a> [metric\_alarms](#input\_metric\_alarms) | A list of CloudWatch metric alarms. Supports both standard and metric query-based alarms. | <pre>list(object({<br/>    alarm_name          = string<br/>    alarm_description   = optional(string)<br/>    actions_enabled     = optional(bool, true)<br/>    comparison_operator = string<br/>    evaluation_periods  = number<br/>    threshold           = optional(number)<br/>    unit                = optional(string)<br/>    treat_missing_data  = optional(string)<br/>    datapoints_to_alarm = optional(number)<br/>    threshold_metric_id = optional(string)<br/><br/>    alarm_actions             = optional(list(string), [])<br/>    ok_actions                = optional(list(string), [])<br/>    insufficient_data_actions = optional(list(string), [])<br/><br/>    dimensions                            = optional(map(string), {})<br/>    evaluate_low_sample_count_percentiles = optional(string)<br/><br/>    metric_name        = optional(string)<br/>    namespace          = optional(string)<br/>    statistic          = optional(string)<br/>    extended_statistic = optional(string)<br/>    period             = optional(number)<br/><br/>    metric_query = optional(list(object({<br/>      id          = string<br/>      expression  = optional(string)<br/>      label       = optional(string)<br/>      return_data = optional(bool, false)<br/><br/>      metric = optional(object({<br/>        metric_name = string<br/>        namespace   = string<br/>        period      = number<br/>        stat        = string<br/>        unit        = optional(string)<br/>        dimensions  = optional(map(string), {})<br/>      }))<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the associated resources | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the provider. Defaults to ap-southeast-2 if not specified. | `string` | `"ap-southeast-2"` | no |
| <a name="input_secrets_recovery_window"></a> [secrets\_recovery\_window](#input\_secrets\_recovery\_window) | Number of days before the secret is permanently deleted. Set to 0 for immediate deletion. | `number` | `7` | no |
| <a name="input_slack_webhook_url"></a> [slack\_webhook\_url](#input\_slack\_webhook\_url) | Slack Webhook URL for sending notifications | `string` | n/a | yes |
| <a name="input_sqs_message_retention_seconds"></a> [sqs\_message\_retention\_seconds](#input\_sqs\_message\_retention\_seconds) | Retention period for messages in the SQS queue (in seconds) | `number` | `86400` | no |
| <a name="input_status_colors"></a> [status\_colors](#input\_status\_colors) | Mapping of status to Slack colors | `string` | n/a | yes |
| <a name="input_status_field"></a> [status\_field](#input\_status\_field) | Field in the message that represents status | `string` | n/a | yes |
| <a name="input_status_mapping"></a> [status\_mapping](#input\_status\_mapping) | Mapping of status values to general categories | `string` | n/a | yes |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | Optional suffix for resource names | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_alarm_arns"></a> [cloudwatch\_alarm\_arns](#output\_cloudwatch\_alarm\_arns) | ARNs of the created CloudWatch metric alarms |
| <a name="output_cloudwatch_alarm_names"></a> [cloudwatch\_alarm\_names](#output\_cloudwatch\_alarm\_names) | Names of the created CloudWatch metric alarms |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch log group for Lambda logs |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of the CloudWatch log group for Lambda logs |
| <a name="output_iam_policy_lambda_arn"></a> [iam\_policy\_lambda\_arn](#output\_iam\_policy\_lambda\_arn) | ARN of the IAM policy assigned to the Lambda function |
| <a name="output_iam_role_lambda_arn"></a> [iam\_role\_lambda\_arn](#output\_iam\_role\_lambda\_arn) | ARN of the IAM role assigned to the Lambda function |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the Lambda function handling notifications |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the Lambda function handling notifications |
| <a name="output_secretsmanager_secret_arn"></a> [secretsmanager\_secret\_arn](#output\_secretsmanager\_secret\_arn) | ARN of the AWS Secrets Manager secret storing the Slack webhook URL |
| <a name="output_secretsmanager_secret_name"></a> [secretsmanager\_secret\_name](#output\_secretsmanager\_secret\_name) | Name of the AWS Secrets Manager secret storing the Slack webhook URL |
| <a name="output_sqs_dlq_arn"></a> [sqs\_dlq\_arn](#output\_sqs\_dlq\_arn) | ARN of the SQS Dead Letter Queue (DLQ) |
| <a name="output_sqs_dlq_url"></a> [sqs\_dlq\_url](#output\_sqs\_dlq\_url) | URL of the SQS Dead Letter Queue (DLQ) |

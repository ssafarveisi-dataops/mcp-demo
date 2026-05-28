output "sfn_role_arn" {
  description = "ARN of the Step Functions execution role"
  value       = aws_iam_role.sfn_role.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role that allows triggering the step function"
  value       = aws_iam_role.lambda_role.arn
}

output "sqs_eventbridge_policy" {
  description = "IAM policy that allows EventBridge to send messages to the SQS queue"
  value       = data.aws_iam_policy_document.queue.json
}

output "eventbridge_role_arn" {
  description = "ARN of the role that allows EventBridge to send messages to SQS"
  value       = aws_iam_role.eventbridge_role.arn
}

output "agentcore_lambda_role_arn" {
  description = "IAM of the lambda execution role that allows invoking the Bedrock AgenCore Runtime"
  value       = aws_iam_role.agentcore_runtime_lambda.arn
}

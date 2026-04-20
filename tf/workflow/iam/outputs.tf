output "sfn_role_arn" {
  description = "ARN of the Step Functions execution role"
  value       = aws_iam_role.sfn_policy.arn
}

output "pipe_role_arn" {
  description = "ARN of the Pipes execution role"
  value       = aws_iam_role.pipes_sqs_role.arn
}

output "bucket_notification_policy" {
  description = "The SQS queue policy for S3 bucket notifications"
  value       = data.aws_iam_policy_document.queue.json
}

output "sfn_role_arn" {
  description = "ARN of the Step Functions execution role"
  value       = aws_iam_role.sfn_policy.arn
}

output "eventbridge_sfn_role_arn" {
  description = "ARN of the EventBridge role for Step Functions"
  value       = aws_iam_role.eventbridge_sfn_role.arn
}

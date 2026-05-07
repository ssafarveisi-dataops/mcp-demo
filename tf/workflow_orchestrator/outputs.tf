output "metaflow_eventbridge_role_arn" {
  value       = aws_iam_role.eventbridge_role.arn
  description = "IAM role for Amazon EventBridge to access AWS Step Functions."
}

output "metaflow_step_functions_dynamodb_policy" {
  value       = data.aws_iam_policy_document.step_functions_dynamodb.json
  description = "Policy json allowing access to the step functions dynamodb table."
}

output "metaflow_step_functions_dynamodb_table_arn" {
  value       = aws_dynamodb_table.step_functions_state_table.arn
  description = "AWS DynamoDB table arn for tracking AWS Step Functions execution metadata."
}

output "metaflow_step_functions_dynamodb_table_name" {
  value       = aws_dynamodb_table.step_functions_state_table.name
  description = "AWS DynamoDB table name for tracking AWS Step Functions execution metadata."
}

output "metaflow_step_functions_role_arn" {
  value       = aws_iam_role.step_functions_role.arn
  description = "IAM role for AWS Step Functions to access AWS resources (AWS Batch, AWS DynamoDB)."
}

output "metaflow_datastore_bucket_name" {
  value       = aws_s3_bucket.metaflow.bucket
  description = "Name of the bucket where we store metaflow data"
}

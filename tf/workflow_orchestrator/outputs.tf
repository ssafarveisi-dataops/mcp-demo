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

output "database_password" {
  value       = random_password.this.result
  description = "The database password"
  sensitive   = true
}

output "rds_master_instance_endpoint" {
  value       = aws_db_instance.this.endpoint
  description = "The database connection endpoint in address:port format"
}

output "network_load_balancer_dns_name" {
  value       = aws_lb.this.dns_name
  description = "The DNS addressable name for the Network Load Balancer that accepts requests and forwards them to our Fargate MetaData service instance(s)"
}

output "METAFLOW_SERVICE_INTERNAL_URL" {
  value       = "http://${aws_lb.this.dns_name}/"
  description = "URL for Metadata Service (Accessible in VPC)"
}

output "METAFLOW_SERVICE_URL" {
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.eu-west-1.amazonaws.com/api/"
  description = "URL for Metadata Service (Open to Public Access)"
}

output "migration_function_arn" {
  value       = aws_lambda_function.db_migrate_lambda.arn
  description = "ARN of DB Migration Function"
}

output "METAFLOW_DEFAULT_METADATA" {
  value       = "service"
  description = "Default metadata provider for Metaflow. This is used by the Metaflow client to determine which metadata provider to use if one is not explicitly specified in the code."
}

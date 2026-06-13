output "metadata_service_sg_id" {
  value = aws_security_group.metadata_service_security_group.id
}

output "metadata_service_rds_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "metadata_service_rds_password" {
  value     = random_password.this.result
  sensitive = true
}

output "metadata_service_rds_db_name" {
  value = var.metadata_service_rds_db_name
}

output "metadata_service_rds_username" {
  value = var.metadata_service_rds_username
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

variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID for the VPC where the resources are deployed"
  type        = string
}

variable "cidr_blocks" {
  description = "CIDR blocks to be set in SG ingress rules"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnets where the load balancer is deployed"
  type        = list(string)
}

variable "ecs_task_role_arn" {
  description = "ARN for the ECS task role"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ARN for the ECS execution role"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN for the application load balancer listener"
  type        = string
}

variable "metadata_service_sg_id" {
  description = "ID for the metadata service security group"
  type        = string
}

variable "metadata_service_rds_db_name" {
  description = "The DB name for the metadata service RDS"
  type        = string
}

variable "metadata_service_rds_username" {
  description = "The username for the metadata service RDS"
  type        = string
}

variable "metadata_service_rds_endpoint" {
  description = "Endpoint for the metadata service RDS"
  type        = string
}

variable "metadata_service_rds_password" {
  description = "Password for the metadata service RDS"
  type        = string
  sensitive   = true
}

variable "metaflow_datastore_root" {
  description = "S3 metaflow datastore root. Example: s3://bucket/metaflow"
  type        = string
}

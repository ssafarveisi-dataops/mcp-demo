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

variable "metadata_service_rds_username" {
  description = "Username for the metadata service RDS"
  type        = string
  default     = "metaflow"
}

variable "metadata_service_rds_db_name" {
  description = "Name for the metadata service RDS's db name"
  type        = string
  default     = "metaflow"
}

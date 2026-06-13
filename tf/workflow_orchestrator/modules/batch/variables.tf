variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID for the VPC where the resources are deployed"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnets where the load balancer is deployed"
  type        = list(string)
}

variable "batch_ecs_instance_profile_arn" {
  description = "ECS instance profile ARN for batch jobs"
  type        = string
}

variable "batch_spot_fleet_role_arn" {
  description = "ARN for the spot fleet role"
  type        = string
}

variable "batch_service_role_arn" {
  description = "ARN for the batch service role"
  type        = string
}

variable "batch_instance_types" {
  type        = list(string)
  description = "EC2 instance types to use for AWS batch jobs"
  default     = ["c4.large", "c4.xlarge", "g4dn.xlarge", "g4dn.2xlarge"]
}

variable "batch_max_vcpu" {
  type        = string
  description = "maximum number of vCPUs to use on a batch job; defaults to 32"
  default     = 32
}

variable "batch_min_vcpu" {
  type        = string
  description = "minimum number of vCPUs to use on a batch job; defaults to 2"
  default     = 2
}


variable "bid_percentage" {
  type        = string
  description = "Spot bid percentage for AWS Batch compute"
  default     = "100"
}

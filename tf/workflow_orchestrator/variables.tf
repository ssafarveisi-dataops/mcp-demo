variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "bucket_name_prefix" {
  type        = string
  description = "Naming prefix of an S3 bucket for metaflow data"
  default     = "metaflow"
}

variable "dynamodb_name" {
  type        = string
  description = "name of the AWS Dynamo DB"
  default     = "metaflow"
}

variable "eventbridge_role_name" {
  type        = string
  description = "name of the eventbridge role"
  default     = "metaflow_eventbridge_role"
}

variable "step_functions_role_name" {
  type        = string
  description = "name of the step function role"
  default     = "metaflow_step_functions_role"
}

variable "ecs_instance_role_name" {
  type        = string
  description = "Name of the ECS IAM instance role"
  default     = "metaflow_ecs_instance_role"
}

variable "batch_security_group_name" {
  type        = string
  description = "Name of the security group used for tasks in the AWS batch compute environment"
  default     = "metaflow_batch_compute_security_group"
}

variable "batch_service_role_name" {
  type        = string
  description = "Name of the AWS batch service IAM role"
  default     = "aws_batch_service_role"
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

variable "batch_queue_name" {
  type        = string
  description = "Name of AWS batch queue"
  default     = "metaflow"
}

variable "bid_percentage" {
  type        = string
  description = "Spot bid percentage for AWS Batch compute"
  default     = "100"
}

variable "arbitrary_s3_bucket_name" {
  description = "Name of the S3 bucket where the raw data for the Metaflow workflow exists"
  type        = string
  default     = "demo-data-lake-glue-etl"
}

variable "metaflow_iam_role_name" {
  description = "Name of the metaflow IAM role that allows interacting with S3, ECR, etc."
  type        = string
  default     = "metaflow_iam_role"
}

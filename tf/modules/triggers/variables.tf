variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "input_bucket_name" {
  description = "Name of the S3 input bucket"
  type        = string
}

variable "eventbridge_sfn_role" {
  description = "ARN of the EventBridge SFN role"
  type        = string
}

variable "sfn_workflow_arn" {
  description = "ARN of the Step Functions workflow"
  type        = string
}
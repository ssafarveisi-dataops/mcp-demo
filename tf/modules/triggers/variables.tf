variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "pipe_role_arn" {
  description = "ARN of the IAM role that allows EventBridge to invoke the Step Functions workflow"
  type        = string
}

variable "pipe_source_arn" {
  description = "ARN of the SQS queue that serves as the source for the EventBridge pipe"
  type        = string
}

variable "pipe_target_arn" {
  description = "ARN of the Step Functions workflow"
  type        = string
}

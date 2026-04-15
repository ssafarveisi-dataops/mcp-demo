variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "log_retention_in_days" {
  description = "Log retention in days"
  type        = number
  default     = 7
}

variable "max_concurrency" {
  description = "Max AgentCore concurrency"
  type        = number
  default     = 10
}

variable "role_arn" {
  description = "Role ARN for the state machine"
  type        = string
}

variable "output_bucket" {
  description = "Output bucket name for the state machine"
  type        = string
}


variable "execution_role_arn" {
  description = "Execution role ARN for the state machine"
  type        = string
}

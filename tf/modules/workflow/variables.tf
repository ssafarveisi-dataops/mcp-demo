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

variable "execution_role_arn" {
  description = "Execution role ARN for the state machine"
  type        = string
}

variable "lambda_role_arn" {
  description = "The lambda role that allows creating the cloud watch group and invoking Bedrock AgentCore Runtime"
  type        = string
}

variable "agent_runtime_arn" {
  description = "ARN for the Bedrock AgentCore Runtime"
  type        = string
}

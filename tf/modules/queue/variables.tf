variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "sqs_eventbridge_policy" {
  description = "IAM policy that allows EventBridge to send messages to the SQS queue"
  type        = string
}

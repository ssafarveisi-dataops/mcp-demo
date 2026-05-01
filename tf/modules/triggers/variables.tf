variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN for the role that enables the lambda function to invoke a step function"
  type        = string
}

variable "sqs_queue_url" {
  description = "URL of the SQS queue get the messages from"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS to send messages to"
  type        = string
}

variable "state_machine_arn" {
  description = "ARN of the Step Function to be triggered by the Lambda function"
  type        = string
}

variable "input_bucket_name" {
  description = "Name of the S3 input bucket"
  type        = string
}

variable "eventbridge_role_arn" {
  description = "ARN of the role that allows EventBridge to send messages to SQS"
  type        = string
}

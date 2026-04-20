variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "bucket_notification_policy" {
  description = "The S3 notification policy for the SQS queue"
  type        = string
}

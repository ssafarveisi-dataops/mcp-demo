resource "aws_sqs_queue" "queue" {
  name   = "${var.resource_prefix}-s3-event-notification-queue"
  policy = var.bucket_notification_policy
}

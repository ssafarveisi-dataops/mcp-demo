resource "aws_sqs_queue" "queue" {
  name                        = "${var.resource_prefix}-s3-event-notification-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = var.sqs_eventbridge_policy
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${local.resource_prefix}-s3-event-notification-queue.fifo"
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/${local.resource_prefix}-s3-upload-trigger"
      ]
    }
  }
}

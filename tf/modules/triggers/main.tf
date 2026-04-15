resource "aws_cloudwatch_event_rule" "s3_upload_trigger" {
  name        = "${var.resource_prefix}-s3-upload-trigger"
  description = "Trigger Step Functions workflow when .jsonl file is uploaded to input bucket"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.input_bucket_name]
      }
      object = {
        key = [{
          suffix = ".jsonl"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "workflow_trigger" {
  rule       = aws_cloudwatch_event_rule.s3_upload_trigger.name
  target_id  = "${var.resource_prefix}-workflow-trigger"
  arn        = var.sfn_workflow_arn
  role_arn   = var.eventbridge_sfn_role
  input_path = "$.detail"
}
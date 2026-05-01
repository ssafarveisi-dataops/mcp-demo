resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.resource_prefix}-invoke-step-function"
  retention_in_days = 7
}

data "archive_file" "this" {
  type        = "zip"
  source_file = "${path.module}/lambda/sfn_trigger_lambda.py"
  output_path = "${path.module}/lambda/sfn_trigger_lambda.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = "${var.resource_prefix}-invoke-step-function"
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  handler          = "sfn_trigger_lambda.lambda_handler"
  runtime          = "python3.12"
  architectures    = ["x86_64"]

  # General
  description                    = "Lambda function to trigger the Step Function execution every 5 minutes"
  memory_size                    = 128
  timeout                        = 30
  reserved_concurrent_executions = 1
  role                           = var.lambda_role_arn

  logging_config {
    log_format = "JSON"
  }

  environment {
    variables = {
      SQS_QUEUE_URL     = var.sqs_queue_url
      STATE_MACHINE_ARN = var.state_machine_arn
    }
  }
  depends_on = [aws_cloudwatch_log_group.lambda_log_group]
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = "${aws_lambda_function.this.function_name}-errors"
  alarm_description   = "Monitors Lambda Errors metric for ${aws_lambda_function.this.function_name}"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  actions_enabled = false

  # Avoid false alarms when the function doesn't run for a while.
  treat_missing_data = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
}

resource "aws_cloudwatch_event_rule" "lambda_trigger" {
  name                = "${var.resource_prefix}-trigger"
  description         = "Triggers a Lambda function on a schedule"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.lambda_trigger.name
  target_id = "${var.resource_prefix}-invoke-step-function-lambda"
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_trigger.arn
}

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
  target_id  = "${var.resource_prefix}-send-sqs-message-trigger"
  role_arn   = var.eventbridge_role_arn
  arn        = var.sqs_queue_arn
  input_path = "$.detail"

  sqs_target {
    message_group_id = "default"
  }
}

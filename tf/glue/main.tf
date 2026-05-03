# Upload the spark application source code to S3
resource "aws_s3_object" "source_code" {
  bucket = var.source_code_bucket
  key    = "jobs/transform_events.py"
  source = "${path.module}/scripts/transform_events.py"
  etag   = filemd5("${path.module}/scripts/transform_events.py")
}

resource "aws_glue_job" "transform_events" {
  name     = "${local.resource_prefix}-transform-events"
  role_arn = aws_iam_role.glue.arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.source_code_bucket}/jobs/transform_events.py"
    python_version  = "3"
  }

  glue_version      = "4.0"
  execution_class   = "FLEX"
  worker_type       = "G.1X" # 4 vCPU, 16 GB RAM per worker
  number_of_workers = 2
  timeout           = 60 # minutes
  max_retries       = 0

  default_arguments = {
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = "s3://${var.source_code_bucket}/spark-logs/"
    "--job-language"                     = "python"
    "--TempDir"                          = "s3://${var.source_code_bucket}/temp/"
    "--output_path"                      = "s3://${var.data_lake_bucket}/transformed/events/"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  tags = {
    Environment = "dev"
    Pipeline    = "event-processing"
  }
}

resource "aws_cloudwatch_log_group" "sfn_log_group" {
  name              = "/aws/vendedlogs/states/${local.resource_prefix}-workflow"
  retention_in_days = 7
}

# Step function
resource "aws_sfn_state_machine" "this" {
  name     = "${local.resource_prefix}-workflow"
  role_arn = aws_iam_role.sfn_role.arn
  definition = templatefile("${path.module}/files/state_machine.json.tpl", {
    glue_job_name = aws_glue_job.transform_events.name
  })
  type = "STANDARD"

  tracing_configuration {
    enabled = true
  }

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn_log_group.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}

resource "aws_cloudwatch_event_rule" "s3_upload_trigger" {
  name        = "${local.resource_prefix}-s3-upload-trigger"
  description = "Trigger Step Functions workflow when .jsonl file is uploaded to input bucket"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.data_lake_bucket]
      }
      object = {
        key = [
          {
            wildcard = "raw/events/event_year=*/event_month=*/event_day=*/*.csv"
          }
        ]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "workflow_trigger" {
  rule       = aws_cloudwatch_event_rule.s3_upload_trigger.name
  target_id  = "${local.resource_prefix}-trigger-step-function"
  role_arn   = aws_iam_role.eventbridge_role.arn
  arn        = aws_sfn_state_machine.this.arn
  input_path = "$.detail"
}

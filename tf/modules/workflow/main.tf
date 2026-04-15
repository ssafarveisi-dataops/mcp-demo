resource "aws_cloudwatch_log_group" "sfn_log_group" {
  name              = "/aws/vendedlogs/states/${var.resource_prefix}-workflow"
  retention_in_days = var.log_retention_in_days
}

resource "aws_sfn_state_machine" "this" {
  name     = "${var.resource_prefix}-workflow"
  role_arn = var.execution_role_arn
  definition = templatefile("${path.module}/files/state_machine.json.tpl", {
    max_concurrency = var.max_concurrency
    output_bucket   = var.output_bucket
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
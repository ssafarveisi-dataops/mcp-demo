resource "aws_cloudwatch_log_group" "pipe_log_group" {
  name = "/aws/vendedlogs/pipes/${var.resource_prefix}-eventbridge-to-sfn"
}

resource "aws_pipes_pipe" "event_bridge_to_sfn" {
  name     = "${var.resource_prefix}-pipe-eventbridge-to-sfn"
  role_arn = var.pipe_role_arn
  source   = var.pipe_source_arn
  target   = var.pipe_target_arn
  log_configuration {
    include_execution_data = ["ALL"]
    level                  = "ERROR"
    cloudwatch_logs_log_destination {
      log_group_arn = aws_cloudwatch_log_group.pipe_log_group.arn
    }
  }
  target_parameters {
    step_function_state_machine_parameters {
      invocation_type = "FIRE_AND_FORGET"
    }
  }
}

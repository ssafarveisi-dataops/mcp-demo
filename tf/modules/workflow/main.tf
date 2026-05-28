resource "aws_cloudwatch_log_group" "sfn_log_group" {
  name              = "/aws/vendedlogs/states/${var.resource_prefix}-workflow"
  retention_in_days = var.log_retention_in_days
}

resource "aws_sfn_state_machine" "this" {
  name     = "${var.resource_prefix}-workflow"
  role_arn = var.execution_role_arn
  definition = templatefile("${path.module}/files/state_machine.json.tpl", {
    max_concurrency = var.max_concurrency
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

# ---------------------------------------------------------------------------
# Lambda function for wrapping Bedrock AgentCore Runtime calls
# ---------------------------------------------------------------------------

data "archive_file" "invoke_agent_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/invoke_agentcore_runtime.py"
  output_path = "${path.module}/invoke_agentcore_runtime.zip"
}

resource "aws_cloudwatch_log_group" "invoke_agent_lambda" {
  name              = "/aws/lambda/${var.resource_prefix}-invoke-agent"
  retention_in_days = var.log_retention_in_days
}

resource "aws_lambda_function" "invoke_agent" {
  # Source Code
  function_name = "${var.resource_prefix}-invoke-agent"
  filename      = data.archive_file.invoke_agent_lambda.output_path
  code_sha256   = data.archive_file.invoke_agent_lambda.output_base64sha256
  handler       = "invoke_agentcore_runtime.lambda_handler"

  runtime       = "python3.14"
  architectures = ["arm64"]

  # General
  description                    = "Wraps Bedrock AgentCore Runtime invocations to support long-running executions (up to 900s)"
  memory_size                    = 128
  timeout                        = 900
  reserved_concurrent_executions = -1


  role = var.lambda_role_arn

  environment {
    variables = {
      AGENT_RUNTIME_ARN = var.agent_runtime_arn
    }
  }

  # Depends on log group being created first
  depends_on = [aws_cloudwatch_log_group.invoke_agent_lambda]
}

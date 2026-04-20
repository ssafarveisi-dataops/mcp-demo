# Trust policy for Step Functions to assume the role and execute the state machine
resource "aws_iam_role" "sfn_policy" {
  name = "${local.resource_prefix}-strands-agent-policy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# S3 permissions for reading input data and writing output data
resource "aws_iam_role_policy" "sfn_s3_policy" {
  name = "${local.resource_prefix}-strands-agent-s3-policy"
  role = aws_iam_role.sfn_policy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.resource_prefix}-input",
          "arn:aws:s3:::${local.resource_prefix}-input/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "arn:aws:s3:::${local.resource_prefix}-output",
          "arn:aws:s3:::${local.resource_prefix}-output/*"
        ]
      }
    ]
  })
}

# Bedrock AgentCore Runtime permissions for invoking and managing agent sessions
resource "aws_iam_role_policy" "sfn_bedrock_policy" {
  name = "${local.resource_prefix}-strands-agent-bedrock-policy"
  role = aws_iam_role.sfn_policy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:InvokeAgentRuntime",
          "bedrock-agentcore:StopRuntimeSession",
        ]
        Resource = [
          "arn:aws:bedrock-agentcore:${var.aws_region}:${data.aws_caller_identity.current.account_id}:runtime/strands_agent-*"
        ]
      }
    ]
  })
}

# CloudWatch Logs permissions for Step Functions logging
resource "aws_iam_role_policy" "sfn_cloudwatch_logs_policy" {
  name = "${local.resource_prefix}-strands-agent-logs-policy"
  role = aws_iam_role.sfn_policy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vendedlogs/states/${local.resource_prefix}-*",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vendedlogs/states/${local.resource_prefix}-*:*"
        ]
      }
    ]
  })
}

# X-Ray permissions for distributed tracing
resource "aws_iam_role_policy" "sfn_xray_policy" {
  name = "${local.resource_prefix}-strands-agent-xray-policy"
  role = aws_iam_role.sfn_policy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# Step Functions execution permissions for Distributed Map state
resource "aws_iam_role_policy" "sfn_execution_policy" {
  name = "${local.resource_prefix}-strands-agent-execution-policy"
  role = aws_iam_role.sfn_policy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution",
          "states:DescribeExecution",
          "states:StopExecution"
        ]
        Resource = [
          "arn:aws:states:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stateMachine:${local.resource_prefix}-*",
          "arn:aws:states:${var.aws_region}:${data.aws_caller_identity.current.account_id}:execution:${local.resource_prefix}-*:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "pipes_sqs_role" {
  name = "${local.resource_prefix}-pipes-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "pipes.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for Pipes to read from SQS
resource "aws_iam_role_policy" "source" {
  role = aws_iam_role.pipes_sqs_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage",
        ],
        Resource = [
          "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${local.resource_prefix}-*",
        ]
      },
    ]
  })
}

# Permissions for Pipes to start Step Functions executionons when processing messages from SQS
resource "aws_iam_role_policy" "target" {
  role = aws_iam_role.pipes_sqs_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = [
          "arn:aws:states:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stateMachine:${local.resource_prefix}-*"
        ]
      }
    ]
  })
}

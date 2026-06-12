resource "aws_iam_role" "spot_fleet_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "spotfleet.amazonaws.com"
          ]
        }
      }
    ]
  })
}

# Create IAM role for ECS instances
resource "aws_iam_role" "ecs_instance_role" {
  name = var.ecs_instance_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "spot_fleet_role" {
  role       = aws_iam_role.spot_fleet_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = var.ecs_instance_role_name
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "aws_batch_service_role" {
  name = var.batch_service_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "batch.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = aws_iam_role.aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_iam_role" "iam_metaflow_access_role" {
  name = var.metaflow_iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "ecs.amazonaws.com",
            "ecs-tasks.amazonaws.com",
            "batch.amazonaws.com"
          ]
        }
      }
    ]
  })
  tags = {
    Metaflow = "true"
  }
}

resource "aws_iam_role_policy" "iam_metaflow_access_policy" {
  name = "metaflow_s3_access"
  role = aws_iam_role.iam_metaflow_access_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListObjectsInMetaflowBucket"
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          aws_s3_bucket.metaflow.arn,
          "${aws_s3_bucket.metaflow.arn}/*"
        ]
      },
      {
        Sid    = "ListObjectsInArbitraryBucket"
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::${var.arbitrary_s3_bucket_name}",
          "arn:aws:s3:::${var.arbitrary_s3_bucket_name}/*"
        ]
      },
      {
        Sid    = "ECRTokenAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPullAccess"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = [
          "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/science-dev-demo-metaflow-gpu"
        ]
      }
    ]
  })
}

data "aws_iam_policy_document" "eventbridge_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      identifiers = [
        "events.amazonaws.com"
      ]
      type = "Service"
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy_document" "eventbridge_step_functions_policy" {
  statement {
    actions = [
      "states:StartExecution"
    ]

    resources = [
      "arn:aws:states:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stateMachine:*"
    ]
  }
}

resource "aws_iam_role" "eventbridge_role" {
  name               = var.eventbridge_role_name
  description        = "IAM role for Amazon EventBridge to access AWS Step Functions."
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role_policy.json

  tags = {
    Metaflow = "true"
  }
}

resource "aws_iam_role_policy" "eventbridge_step_functions_policy" {
  name   = "step_functions"
  role   = aws_iam_role.eventbridge_role.id
  policy = data.aws_iam_policy_document.eventbridge_step_functions_policy.json
}

data "aws_iam_policy_document" "step_functions_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      identifiers = [
        "states.amazonaws.com"
      ]
      type = "Service"
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy_document" "step_functions_batch_policy" {
  statement {
    actions = [
      "batch:TerminateJob",
      "batch:DescribeJobs",
      "batch:DescribeJobDefinitions",
      "batch:DescribeJobQueues",
      "batch:RegisterJobDefinition",
      "batch:TagResource"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "batch:SubmitJob"
    ]

    resources = [
      aws_batch_job_queue.metaflow_batch_job_queue.arn,
      "arn:aws:batch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:job-definition/*"
    ]
  }
}

data "aws_iam_policy_document" "step_functions_cloudwatch" {
  statement {
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]

    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "step_functions_eventbridge" {
  statement {
    actions = [
      "events:PutTargets",
      "events:DescribeRule"
    ]

    resources = [
      "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForBatchJobsRule",
    ]
  }

  statement {
    actions = [
      "events:PutRule"
    ]

    resources = [
      "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForBatchJobsRule"
    ]

    condition {
      test     = "StringEquals"
      variable = "events:detail-type"
      values   = ["Batch Job State Change"]
    }
  }
}

data "aws_iam_policy_document" "step_functions_dynamodb" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem"
    ]

    resources = [
      aws_dynamodb_table.step_functions_state_table.arn
    ]
  }
}

resource "aws_iam_role" "step_functions_role" {
  name               = var.step_functions_role_name
  description        = "IAM role for AWS Step Functions to access AWS resources (AWS Batch, AWS DynamoDB)."
  assume_role_policy = data.aws_iam_policy_document.step_functions_assume_role_policy.json

  tags = {
    Metaflow = "true"
  }
}

resource "aws_iam_role_policy" "step_functions_batch" {
  name   = "aws_batch"
  role   = aws_iam_role.step_functions_role.id
  policy = data.aws_iam_policy_document.step_functions_batch_policy.json
}

resource "aws_iam_role_policy" "step_functions_cloudwatch" {
  name   = "cloudwatch"
  role   = aws_iam_role.step_functions_role.id
  policy = data.aws_iam_policy_document.step_functions_cloudwatch.json
}

resource "aws_iam_role_policy" "step_functions_eventbridge" {
  name   = "event_bridge"
  role   = aws_iam_role.step_functions_role.id
  policy = data.aws_iam_policy_document.step_functions_eventbridge.json
}

resource "aws_iam_role_policy" "step_functions_dynamodb" {
  name   = "dynamodb"
  role   = aws_iam_role.step_functions_role.id
  policy = data.aws_iam_policy_document.step_functions_dynamodb.json
}

data "aws_iam_policy_document" "metadata_svc_ecs_task_assume_role" {
  statement {
    effect = "Allow"

    principals {
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
      type = "Service"
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "metadata_svc_ecs_task_role" {
  name               = "${local.resource_prefix}-metadata-ecs-task"
  description        = "This role is passed to AWS ECS' task definition as the `task_role`. This allows the running of the Metaflow Metadata Service to have the proper permissions to speak to other AWS resources."
  assume_role_policy = data.aws_iam_policy_document.metadata_svc_ecs_task_assume_role.json

  tags = {
    Metaflow = "true"
  }
}

data "aws_iam_policy_document" "custom_s3_batch" {
  statement {
    sid = "ObjectAccessMetadataService"

    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.metaflow.arn,
      "${aws_s3_bucket.metaflow.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "deny_presigned_batch" {
  statement {
    sid = "DenyPresignedBatch"

    effect = "Deny"

    actions = [
      "s3:*"
    ]

    resources = [
      "*"
    ]

    condition {
      test = "StringNotEquals"
      values = [
        "REST-HEADER"
      ]
      variable = "s3:authType"
    }
  }
}

resource "aws_iam_role_policy" "grant_custom_s3_batch" {
  name   = "custom_s3"
  role   = aws_iam_role.metadata_svc_ecs_task_role.name
  policy = data.aws_iam_policy_document.custom_s3_batch.json
}

resource "aws_iam_role_policy" "grant_deny_presigned_batch" {
  name   = "deny_presigned"
  role   = aws_iam_role.metadata_svc_ecs_task_role.name
  policy = data.aws_iam_policy_document.deny_presigned_batch.json
}

data "aws_iam_policy_document" "ecs_execution_role_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    effect = "Allow"

    principals {
      identifiers = [
        "ec2.amazonaws.com",
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com",
        "batch.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "${local.resource_prefix}-ecs-execution"
  description        = "This role is passed to our AWS ECS' task definition as the `execution_role`. This allows things like the correct image to be pulled and logs to be stored."
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_role_assume_role.json

  tags = {
    Metaflow = "true"
  }
}

data "aws_iam_policy_document" "ecs_task_execution_policy" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    # The `"Resource": "*"` is not a concern and the policy that Amazon suggests using
    # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "grant_ecs_access" {
  name   = "ecs_access"
  role   = aws_iam_role.ecs_execution_role.name
  policy = data.aws_iam_policy_document.ecs_task_execution_policy.json
}

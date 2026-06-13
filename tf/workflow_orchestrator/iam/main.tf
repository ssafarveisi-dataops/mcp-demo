resource "aws_iam_role" "batch_spot_fleet_role" {
  name        = "${local.resource_prefix}-batch-spot-fleet"
  description = "IAM role used by AWS Batch Spot Fleet."

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

resource "aws_iam_role" "batch_ecs_instance_role" {
  name        = "${local.resource_prefix}-batch-ecs-instance"
  description = "IAM role used by ECS instances managed by AWS Batch."

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

resource "aws_iam_role_policy_attachment" "batch_spot_fleet_role_policy" {
  role       = aws_iam_role.batch_spot_fleet_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

resource "aws_iam_role_policy_attachment" "batch_ecs_instance_role_policy" {
  role       = aws_iam_role.batch_ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "batch_ecs_instance_profile" {
  name = "${local.resource_prefix}-batch-ecs-instance"
  role = aws_iam_role.batch_ecs_instance_role.name
}

resource "aws_iam_role" "batch_service_role" {
  name        = "${local.resource_prefix}-batch-service"
  description = "IAM service role used by AWS Batch."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "batch.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_service_role_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_iam_role" "metaflow_access_role" {
  name        = "${local.resource_prefix}-access"
  description = "IAM role used by Metaflow compute resources to access required AWS services."

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

resource "aws_iam_role_policy" "metaflow_access_role_policy" {
  name = "${local.resource_prefix}-access"
  role = aws_iam_role.metaflow_access_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MetaflowDatastoreAccess"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::${var.metaflow_s3_datastore_root_bucket_name}",
          "arn:aws:s3:::${var.metaflow_s3_datastore_root_bucket_name}/*"
        ]
      },
      {
        Sid    = "ArbitraryBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
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
          "arn:aws:ecr:eu-west-1:463470983643:repository/science-dev-*"
        ]
      }
    ]
  })
}

data "aws_iam_policy_document" "eventbridge_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
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
      "arn:aws:states:eu-west-1:463470983643:stateMachine:*"
    ]
  }
}

resource "aws_iam_role" "eventbridge_role" {
  name               = "${local.resource_prefix}-eventbridge"
  description        = "IAM role used by Amazon EventBridge to start AWS Step Functions executions."
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role_policy.json

  tags = {
    Metaflow = "true"
  }
}

resource "aws_iam_role_policy" "eventbridge_role_policy" {
  name   = "${local.resource_prefix}-eventbridge"
  role   = aws_iam_role.eventbridge_role.id
  policy = data.aws_iam_policy_document.eventbridge_step_functions_policy.json
}

data "aws_iam_policy_document" "step_functions_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "states.amazonaws.com"
      ]
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
      "arn:aws:batch:eu-west-1:463470983643:job-queue/${local.resource_prefix}*",
      "arn:aws:batch:eu-west-1:463470983643:job-definition/${local.resource_prefix}*"
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
      "arn:aws:events:eu-west-1:463470983643:rule/StepFunctionsGetEventsForBatchJobsRule"
    ]
  }

  statement {
    actions = [
      "events:PutRule"
    ]

    resources = [
      "arn:aws:events:eu-west-1:463470983643:rule/StepFunctionsGetEventsForBatchJobsRule"
    ]

    condition {
      test     = "StringEquals"
      variable = "events:detail-type"
      values = [
        "Batch Job State Change"
      ]
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
      "arn:aws:dynamodb:eu-west-1:463470983643:table/${local.resource_prefix}*"
    ]
  }
}

resource "aws_iam_role" "step_functions_role" {
  name               = "${local.resource_prefix}-step-functions"
  description        = "IAM role used by AWS Step Functions to access AWS Batch, DynamoDB, CloudWatch Logs, and EventBridge."
  assume_role_policy = data.aws_iam_policy_document.step_functions_assume_role_policy.json

  tags = {
    Metaflow = "true"
  }
}

resource "aws_iam_role_policy" "step_functions_role_batch_policy" {
  name   = "${local.resource_prefix}-step-functions-batch"
  role   = aws_iam_role.step_functions_role.id
  policy = data.aws_iam_policy_document.step_functions_batch_policy.json
}

resource "aws_iam_role_policy" "step_functions_role_cloudwatch_policy" {
  name   = "${local.resource_prefix}-step-functions-cloudwatch"
  role   = aws_iam_role.step_functions_role.id
  policy = data.aws_iam_policy_document.step_functions_cloudwatch.json
}

resource "aws_iam_role_policy" "step_functions_role_eventbridge_policy" {
  name   = "${local.resource_prefix}-step-functions-eventbridge"
  role   = aws_iam_role.step_functions_role.id
  policy = data.aws_iam_policy_document.step_functions_eventbridge.json
}

resource "aws_iam_role_policy" "step_functions_role_dynamodb_policy" {
  name   = "${local.resource_prefix}-step-functions-dynamodb"
  role   = aws_iam_role.step_functions_role.id
  policy = data.aws_iam_policy_document.step_functions_dynamodb.json
}

data "aws_iam_policy_document" "metadata_svc_ecs_task_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "metadata_svc_ecs_task_role" {
  name               = "${local.resource_prefix}-metadata-ecs-task"
  description        = "IAM task role used by the Metaflow Metadata Service running on ECS."
  assume_role_policy = data.aws_iam_policy_document.metadata_svc_ecs_task_assume_role.json

  tags = {
    Metaflow = "true"
  }
}

data "aws_iam_policy_document" "metadata_svc_ecs_task_role_custom_s3" {
  statement {
    sid    = "MetadataServiceS3ReadAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.metaflow_s3_datastore_root_bucket_name}",
      "arn:aws:s3:::${var.metaflow_s3_datastore_root_bucket_name}/*"
    ]
  }
}

data "aws_iam_policy_document" "metadata_svc_ecs_task_role_deny_presigned" {
  statement {
    sid    = "DenyPresignedRequests"
    effect = "Deny"

    actions = [
      "s3:*"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringNotEquals"
      variable = "s3:authType"
      values = [
        "REST-HEADER"
      ]
    }
  }
}

resource "aws_iam_role_policy" "metadata_svc_ecs_task_role_custom_s3_batch_policy" {
  name   = "${local.resource_prefix}-metadata-svc-ecs-task-custom-s3"
  role   = aws_iam_role.metadata_svc_ecs_task_role.name
  policy = data.aws_iam_policy_document.metadata_svc_ecs_task_role_custom_s3.json
}

resource "aws_iam_role_policy" "metadata_svc_ecs_task_role_deny_presigned_policy" {
  name   = "${local.resource_prefix}-metadata-svc-ecs-task-deny-presigned"
  role   = aws_iam_role.metadata_svc_ecs_task_role.name
  policy = data.aws_iam_policy_document.metadata_svc_ecs_task_role_deny_presigned.json
}

data "aws_iam_policy_document" "metadata_svc_ecs_task_execution_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com",
        "batch.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "metadata_svc_ecs_task_execution_role" {
  name               = "${local.resource_prefix}-ecs-task-execution"
  description        = "IAM execution role used by ECS tasks to pull container images and publish logs."
  assume_role_policy = data.aws_iam_policy_document.metadata_svc_ecs_task_execution_assume_role.json

  tags = {
    Metaflow = "true"
  }
}

data "aws_iam_policy_document" "metadata_svc_ecs_task_execution_access" {
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

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_task_execution_access_policy" {
  name   = "${local.resource_prefix}-ecs-task-execution"
  role   = aws_iam_role.metadata_svc_ecs_task_execution_role.name
  policy = data.aws_iam_policy_document.metadata_svc_ecs_task_execution_access.json
}

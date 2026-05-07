resource "aws_iam_role" "spot_fleet_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "spotfleet.amazonaws.com"
        ]
      }
    }
  ]
}
EOF
}

# Create IAM role for ECS instances
resource "aws_iam_role" "ecs_instance_role" {
  name = var.ecs_instance_role_name

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
        "Service": "ec2.amazonaws.com"
        }
    }
    ]
}
EOF
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

# Create a S3 bucket for storing metaflow data
resource "aws_s3_bucket" "metaflow" {
  bucket_prefix = var.bucket_name_prefix

  tags = {
    Metaflow = "true"
  }
}

resource "aws_s3_bucket_public_access_block" "input_bucket" {
  bucket                  = aws_s3_bucket.metaflow.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "aws_batch_service_role" {
  name = var.batch_service_role_name

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": [
            "batch.amazonaws.com",
            "s3.amazonaws.com"
          ]
        }
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = aws_iam_role.aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_security_group" "metaflow_batch" {
  name   = var.batch_security_group_name
  vpc_id = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Metaflow = "true"
  }
}

resource "aws_batch_compute_environment" "metaflow_batch" {
  compute_environment_name = var.compute_environment_name

  compute_resources {
    instance_role = aws_iam_instance_profile.ecs_instance_role.arn

    instance_type       = var.batch_instance_types
    allocation_strategy = "SPOT_CAPACITY_OPTIMIZED"

    max_vcpus = var.batch_max_vcpu
    min_vcpus = var.batch_min_vcpu

    security_group_ids = [
      aws_security_group.metaflow_batch.id,
    ]

    subnets = [for subnet in local.private_subnet_list : subnet]

    type                = "SPOT"
    spot_iam_fleet_role = aws_iam_role.spot_fleet_role.arn
    bid_percentage      = var.bid_percentage

    tags = {
      Metaflow = "true"
    }
  }

  service_role = aws_iam_role.aws_batch_service_role.arn
  type         = "MANAGED"
  depends_on   = [aws_iam_role_policy_attachment.aws_batch_service_role]
}

# Create the Batch Job Queue
resource "aws_batch_job_queue" "metaflow_batch_job_queue" {
  name     = var.batch_queue_name
  state    = "ENABLED"
  priority = 1
  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.metaflow_batch.arn
  }
}

resource "aws_iam_role" "iam_s3_access_role" {
  name               = "metaflow_iam_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com",
          "ecs.amazonaws.com",
          "ecs-tasks.amazonaws.com",
          "batch.amazonaws.com",
          "s3.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Metaflow = "true"
  }
}

resource "aws_iam_role_policy" "iam_metaflow_s3_access_policy" {
  name = "metaflow_s3_access"
  role = aws_iam_role.iam_s3_access_role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "ListObjectsInMetaflowBucket",
        "Effect": "Allow",
        "Action": ["s3:*"],
        "Resource": ["${aws_s3_bucket.metaflow.arn}", "${aws_s3_bucket.metaflow.arn}/*"]
    },
    {
        "Sid": "ListObjectsInArbitraryBucket",
        "Effect": "Allow",
        "Action": ["s3:*"],
        "Resource": ["arn:aws:s3:::${var.arbitrary_s3_bucket_name}", "arn:aws:s3:::${var.arbitrary_s3_bucket_name}/*"]
    }
  ]
}
EOF
}

resource "aws_dynamodb_table" "step_functions_state_table" {
  name         = var.dynamodb_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pathspec"

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = false
  }

  attribute {
    name = "pathspec"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Metaflow = "true"
  }
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

data "aws_iam_policy_document" "step_functions_s3" {
  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.metaflow.arn
    ]
  }

  statement {
    actions = [
      "s3:*Object"
    ]

    resources = [
      aws_s3_bucket.metaflow.arn, "${aws_s3_bucket.metaflow.arn}/*"
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

resource "aws_iam_role_policy" "step_functions_s3" {
  name   = "s3"
  role   = aws_iam_role.step_functions_role.id
  policy = data.aws_iam_policy_document.step_functions_s3.json
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

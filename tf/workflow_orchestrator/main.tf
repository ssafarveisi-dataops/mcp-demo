# Create a S3 bucket for storing metaflow data
resource "aws_s3_bucket" "metaflow" {
  bucket_prefix = var.bucket_name_prefix
  force_destroy = true
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
  compute_environment_name_prefix = "metaflow-batch-"

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

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_iam_role_policy_attachment.aws_batch_service_role]
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

# resource "aws_cloudwatch_event_rule" "s3_upload_trigger" {
#   name        = "metaflow-sfn-s3-upload-trigger"
#   description = "Trigger Step Functions workflow when a csv file is uploaded to input bucket"

#   event_pattern = jsonencode({
#     source      = ["aws.s3"]
#     detail-type = ["Object Created"]
#     detail = {
#       bucket = {
#         name = ["demo-data-lake-glue-etl"]
#       }
#       object = {
#         key = [
#           {
#             wildcard = "transformed/events/event_year=*/event_month=*/event_day=*/*.csv"
#           }
#         ]
#       }
#     }
#   })
# }

# resource "aws_cloudwatch_event_target" "workflow_trigger" {
#   rule      = aws_cloudwatch_event_rule.s3_upload_trigger.name
#   target_id = "trigger-step-function"
#   role_arn  = aws_iam_role.sfn_eventbridge_role.arn
#   arn       = "arn:aws:states:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stateMachine:DemoMetaflowWorkflow"

#   input_transformer {
#     input_paths = {
#       bucket = "$.detail.bucket.name"
#       key    = "$.detail.object.key"
#     }

#     input_template = <<EOF
# {
#   "Parameters": "{\"bucket\":\"<bucket>\",\"key\":\"<key>\"}"
# }
# EOF
#   }
# }

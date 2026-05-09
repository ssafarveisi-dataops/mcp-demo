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

resource "aws_security_group" "metaflow_batch" {
  name   = "${var.resource_prefix}-batch-sg"
  vpc_id = var.vpc_id

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
  name = "metaflow-batch"

  compute_resources {
    instance_role = var.batch_ecs_instance_profile_arn # batch_ecs_instance_profile in IAM module

    instance_type       = var.batch_instance_types
    allocation_strategy = "SPOT_CAPACITY_OPTIMIZED"

    max_vcpus = var.batch_max_vcpu
    min_vcpus = var.batch_min_vcpu

    security_group_ids = [
      aws_security_group.metaflow_batch.id,
    ]

    subnets             = var.private_subnets
    type                = "SPOT"
    spot_iam_fleet_role = var.batch_spot_fleet_role_arn # batch_spot_fleet_role in IAM module
    bid_percentage      = var.bid_percentage

    tags = {
      Metaflow = "true"
    }
  }

  service_role = var.batch_service_role_arn # batch_service_role in IAM module
  type         = "MANAGED"

  lifecycle {
    create_before_destroy = true
  }

}

# Create the Batch Job Queue
resource "aws_batch_job_queue" "metaflow_batch_job_queue" {
  name     = var.resource_prefix
  state    = "ENABLED"
  priority = 1
  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.metaflow_batch.arn
  }
}

resource "aws_dynamodb_table" "step_functions_state_table" {
  name         = var.resource_prefix
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

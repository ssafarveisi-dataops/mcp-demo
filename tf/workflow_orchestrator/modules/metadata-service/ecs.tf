resource "aws_cloudwatch_log_group" "this" {
  name = "${var.resource_prefix}-metadata"

  tags = {
    Metaflow = "true"
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${var.resource_prefix}-metadata-service-cluster"

  tags = {
    Metaflow = "true"
  }
}

resource "aws_ecs_task_definition" "this" {
  family = "${var.resource_prefix}-service" # Unique name for task definition

  container_definitions = jsonencode(
    [
      {
        "name" : "${var.resource_prefix}-service",
        "image" : "netflixoss/metaflow_metadata_service:v2.3.0",
        "essential" : true,
        "cpu" : 512,
        "memory" : 1024,
        "portMappings" : [
          {
            "containerPort" : 8080,
            "hostPort" : 8080
          },
          {
            "containerPort" : 8082,
            "hostPort" : 8082
          }
        ],
        "environment" : [
          { "name" : "MF_METADATA_DB_HOST", "value" : "${replace(aws_db_instance.this.endpoint, ":5432", "")}" },
          { "name" : "MF_METADATA_DB_NAME", "value" : "${var.metadata_service_rds_db_name}" },
          { "name" : "MF_METADATA_DB_PORT", "value" : "5432" },
          { "name" : "MF_METADATA_DB_PSWD", "value" : "${random_password.this.result}" },
          { "name" : "MF_METADATA_DB_USER", "value" : "${var.metadata_service_rds_username}" },
          { "name" : "MF_METADATA_DB_SSL_MODE", "value" : "disable" }
        ],
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-group" : "${aws_cloudwatch_log_group.this.name}",
            "awslogs-region" : "eu-west-1",
            "awslogs-stream-prefix" : "metadata"
          }
        }
      }
    ]
  )

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = var.ecs_task_role_arn      # metadata_svc_ecs_task_role from IAM module
  execution_role_arn       = var.ecs_execution_role_arn # ecs_execution_role from IAM module
  cpu                      = 512
  memory                   = 1024

  tags = {
    Metaflow = "true"
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.resource_prefix}-metadata-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.metadata_service_security_group.id]
    assign_public_ip = false
    subnets          = var.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "${var.resource_prefix}-service"
    container_port   = 8080
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.db_migrate.arn
    container_name   = "${var.resource_prefix}-service"
    container_port   = 8082
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Metaflow = "true"
  }
}

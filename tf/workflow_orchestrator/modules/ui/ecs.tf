# Metadata UI ECS Fargate setup

resource "aws_cloudwatch_log_group" "this" {
  name = "${var.resource_prefix}-ui"

  tags = {
    Metaflow = "true"
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${var.resource_prefix}-ui-cluster"

  tags = {
    Metaflow = "true"
  }
}

resource "aws_ecs_task_definition" "ui_backend" {
  family = "${var.resource_prefix}-ui-backend" # Unique name for task definition

  container_definitions = jsonencode([
    {
      name      = "${var.resource_prefix}-ui-backend"
      image     = "netflixoss/metaflow_metadata_service:v2.3.0"
      essential = true
      cpu       = 2048
      memory    = 16384
      portMappings = [
        {
          containerPort = 8083
          hostPort      = 8083
        }
      ]
      environment = [
        { name = "MF_METADATA_DB_HOST", value = "${replace(var.metadata_service_rds_endpoint, ":5432", "")}" },
        { name = "MF_METADATA_DB_NAME", value = "${var.metadata_service_rds_db_name}" },
        { name = "MF_METADATA_DB_PORT", value = "5432" },
        { name = "MF_METADATA_DB_PSWD", value = "${var.metadata_service_rds_password}" },
        { name = "MF_METADATA_DB_USER", value = "${var.metadata_service_rds_username}" },
        { name = "MF_METADATA_DB_SSL_MODE", value = "disable" },
        { name = "PATH_PREFIX", value = "/api" },
        { name = "MF_DATASTORE_ROOT", value = "${var.metaflow_datastore_root}" },
        { name = "METAFLOW_DATASTORE_SYSROOT_S3", value = "${var.metaflow_datastore_root}" },
        { name = "LOGLEVEL", value = "DEBUG" },
        { name = "METAFLOW_SERVICE_URL", value = "http://localhost:8083/api/metadata" },
        { name = "METAFLOW_DEFAULT_DATASTORE", value = "s3" },
        { name = "METAFLOW_DEFAULT_METADATA", value = "service" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" : "${aws_cloudwatch_log_group.this.name}"
          "awslogs-region" : "eu-west-1"
          "awslogs-stream-prefix" : "ui-backend"
        }
      }
      command = [
        "/opt/latest/bin/python3",
        "-m",
        "services.ui_backend_service.ui_server"
      ]
    }
  ])

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = var.ecs_task_role_arn      # metadata_svc_ecs_task_role from IAM module
  execution_role_arn       = var.ecs_execution_role_arn # ecs_execution_role from IAM module
  cpu                      = 2048
  memory                   = 16384

  ephemeral_storage {
    size_in_gib = 100
  }

  tags = {
    Metaflow = "true"
  }
}

resource "aws_ecs_service" "ui_backend" {
  name            = "${var.resource_prefix}-ui-backend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.ui_backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [
      aws_security_group.fargate_security_group.id,
      var.metadata_service_sg_id # metadata_service_security_group id from metadata-service module
    ]
    assign_public_ip = true
    subnets          = var.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ui_backend.arn
    container_name   = "${var.resource_prefix}-ui-backend"
    container_port   = 8083
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Metaflow = "true"
  }
}


resource "aws_ecs_task_definition" "ui_static" {
  family = "${var.resource_prefix}-ui-static" # Unique name for task definition

  container_definitions = jsonencode([
    {
      name      = "${var.resource_prefix}-ui-static"
      image     = "public.ecr.aws/outerbounds/metaflow_ui:v1.1.2"
      essential = true
      cpu       = 512
      memory    = 1024
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" : "${aws_cloudwatch_log_group.this.name}"
          "awslogs-region" : "eu-west-1"
          "awslogs-stream-prefix" : "ui-static"
        }
      }
    }
  ])

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

resource "aws_ecs_service" "ui_static" {
  name            = "${var.resource_prefix}-ui-static"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.ui_static.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.fargate_security_group.id]
    assign_public_ip = true
    subnets          = var.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ui_static.arn
    container_name   = "${var.resource_prefix}-ui-static"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Metaflow = "true"
  }
}

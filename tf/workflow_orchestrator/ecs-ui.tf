# Metadata UI ECS Fargate setup

resource "aws_cloudwatch_log_group" "ui_logs" {
  name = "${local.resource_prefix}-ui"

  tags = {
    Metaflow = "true"
  }
}

resource "aws_ecs_cluster" "ui_cluster" {
  name = "${local.resource_prefix}-ui-cluster"

  tags = {
    Metaflow = "true"
  }
}

resource "aws_ecs_task_definition" "ui_backend" {
  family = "${local.resource_prefix}-ui-backend" # Unique name for task definition

  container_definitions = jsonencode([
    {
      name      = "${local.resource_prefix}-ui-backend"
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
        { name = "MF_METADATA_DB_HOST", value = "${replace(aws_db_instance.this.endpoint, ":5432", "")}" },
        { name = "MF_METADATA_DB_NAME", value = "metaflow" },
        { name = "MF_METADATA_DB_PORT", value = "5432" },
        { name = "MF_METADATA_DB_PSWD", value = "${random_password.this.result}" },
        { name = "MF_METADATA_DB_USER", value = "metaflow" },
        { name = "MF_METADATA_DB_SSL_MODE", value = "disable" },
        { name = "PATH_PREFIX", value = "/api" },
        { name = "MF_DATASTORE_ROOT", value = "s3://metaflow-s3-dataops-demo/metaflow" },
        { name = "METAFLOW_DATASTORE_SYSROOT_S3", value = "s3://metaflow-s3-dataops-demo/metaflow" },
        { name = "LOGLEVEL", value = "DEBUG" },
        { name = "METAFLOW_SERVICE_URL", value = "http://localhost:8083/api/metadata" },
        { name = "METAFLOW_DEFAULT_DATASTORE", value = "s3" },
        { name = "METAFLOW_DEFAULT_METADATA", value = "service" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" : "${aws_cloudwatch_log_group.ui_logs.name}"
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
  task_role_arn            = aws_iam_role.metadata_svc_ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
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
  name            = "${local.resource_prefix}-ui-backend"
  cluster         = aws_ecs_cluster.ui_cluster.id
  task_definition = aws_ecs_task_definition.ui_backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [
      aws_security_group.fargate_security_group.id,
      aws_security_group.metadata_service_security_group.id
    ]
    assign_public_ip = true
    subnets          = local.private_subnet_list
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ui_backend.arn
    container_name   = "${local.resource_prefix}-ui-backend"
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
  family = "${local.resource_prefix}-ui-static" # Unique name for task definition

  container_definitions = jsonencode([
    {
      name      = "${local.resource_prefix}-ui-static"
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
          "awslogs-group" : "${aws_cloudwatch_log_group.ui_logs.name}"
          "awslogs-region" : "eu-west-1"
          "awslogs-stream-prefix" : "ui-static"
        }
      }
    }
  ])

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.metadata_svc_ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  cpu                      = 512
  memory                   = 1024

  tags = {
    Metaflow = "true"
  }
}

resource "aws_ecs_service" "ui_static" {
  name            = "${local.resource_prefix}-ui-static"
  cluster         = aws_ecs_cluster.ui_cluster.id
  task_definition = aws_ecs_task_definition.ui_static.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.fargate_security_group.id]
    assign_public_ip = true
    subnets          = local.private_subnet_list
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ui_static.arn
    container_name   = "${local.resource_prefix}-ui-static"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Metaflow = "true"
  }
}

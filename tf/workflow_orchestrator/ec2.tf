# Metadata service

resource "aws_security_group" "metadata_service_security_group" {
  name        = "${local.resource_prefix}-metadata-service-sg"
  description = "Security Group for Fargate which runs the Metadata Service."
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = local.vpc_cidr
    description = "Allow API calls internally"
  }

  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = local.vpc_cidr
    description = "Allow API calls internally"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
    description = "Internal communication"
  }

  # egress to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all external communication"
  }

  tags = {
    Metaflow = "true"
  }
}

resource "aws_lb" "this" {
  name               = "${local.resource_prefix}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = local.private_subnet_list

  tags = {
    Metaflow = "true"
  }
}

resource "aws_lb_target_group" "this" {
  name        = "${local.resource_prefix}-mdtg"
  port        = 8080
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    protocol            = "TCP"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Metaflow = "true"
  }
}

resource "aws_lb_target_group" "db_migrate" {
  name        = "${local.resource_prefix}-dbtg"
  port        = 8082
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    protocol            = "TCP"
    port                = 8080
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Metaflow = "true"
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }
}

resource "aws_lb_listener" "db_migrate" {
  load_balancer_arn = aws_lb.this.arn
  port              = "8082"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.db_migrate.id
  }
}

# Metaflow UI

resource "aws_security_group" "fargate_security_group" {
  name        = "${local.resource_prefix}-ui-backend-sg"
  description = "Security Group for Fargate which runs the UI Backend."
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = local.vpc_cidr
    description = "Allow all internal traffic"
  }

  # egress to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all external communication"
  }

  tags = {
    Metaflow = "true"
  }
}

resource "aws_lb_target_group" "ui_backend" {
  name        = format("%.32s", "${local.resource_prefix}-ui-backend")
  port        = 8083
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    protocol            = "HTTP"
    port                = 8083
    path                = "/api/ping"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Metaflow = "true"
  }
}

resource "aws_lb_target_group" "ui_static" {
  name        = format("%.32s", "${local.resource_prefix}-ui-static")
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id
  tags = {
    Metaflow = "true"
  }
}

resource "aws_lb_listener_rule" "ui_backend" {
  listener_arn = data.terraform_remote_state.alb.outputs.alb_listener_arn
  priority     = 106

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui_backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "ui_static" {
  listener_arn = data.terraform_remote_state.alb.outputs.alb_listener_arn
  priority     = 107

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui_static.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

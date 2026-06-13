# Metaflow UI

resource "aws_security_group" "fargate_security_group" {
  name        = "${var.resource_prefix}-ui-backend-sg"
  description = "Security Group for Fargate which runs the UI Backend."
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = var.cidr_blocks
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
  name        = format("%.32s", "${var.resource_prefix}-ui-backend")
  port        = 8083
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

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
  name        = format("%.32s", "${var.resource_prefix}-ui-static")
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  tags = {
    Metaflow = "true"
  }
}

resource "aws_lb_listener_rule" "ui_backend" {
  listener_arn = var.alb_listener_arn # alb_listener_arn from alb terraform_remote_state
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
  listener_arn = var.alb_listener_arn # alb_listener_arn from alb terraform_remote_state
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

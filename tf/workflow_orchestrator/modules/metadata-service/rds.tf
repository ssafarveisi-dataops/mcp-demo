resource "aws_db_parameter_group" "this" {
  name   = "${var.resource_prefix}-postgres16-pg"
  family = "postgres16"

  parameter {
    name         = "rds.force_ssl"
    value        = "0"
    apply_method = "immediate"
  }

  tags = {
    Metaflow = "true"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.resource_prefix}-pg-sg"
  subnet_ids = var.private_subnets

  tags = {
    Metaflow = "true"
  }
}

/*
 Define a new firewall for our database instance.
*/
resource "aws_security_group" "rds_security_group" {
  name   = "${var.resource_prefix}-rds-sg"
  vpc_id = var.vpc_id

  # ingress only from port 5432
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.metadata_service_security_group.id]
  }

  # egress to anywhere
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

resource "random_password" "this" {
  length  = 64
  special = true
  # redefines the `special` variable by removing the `@`
  # this documentation https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html
  # shows that the `/`, `"`, `@` and ` ` cannot be used in the password
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_pet" "final_snapshot_id" {}

/*
 Define rds db instance.
*/
resource "aws_db_instance" "this" {
  publicly_accessible       = false
  allocated_storage         = 20    # Allocate 20GB
  storage_type              = "gp2" # general purpose SSD
  storage_encrypted         = false # Change this later
  engine                    = "postgres"
  engine_version            = "16"
  instance_class            = "db.t3.small"
  identifier                = "${var.resource_prefix}-metaflow"
  db_name                   = var.metadata_service_rds_db_name
  username                  = var.metadata_service_rds_username
  password                  = random_password.this.result
  db_subnet_group_name      = aws_db_subnet_group.this.id
  max_allocated_storage     = 1000
  multi_az                  = false
  final_snapshot_identifier = "${var.resource_prefix}-metaflow-final-snapshot-${random_pet.final_snapshot_id.id}" # Snapshot upon delete
  vpc_security_group_ids    = [aws_security_group.rds_security_group.id]
  parameter_group_name      = aws_db_parameter_group.this.name
  tags = {
    Metaflow = "true"
  }
}

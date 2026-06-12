resource "aws_db_parameter_group" "this" {
  name   = "${local.resource_prefix}-postgres16-pg"
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
  name       = "${local.resource_prefix}-pg-sg"
  subnet_ids = local.private_subnet_list

  tags = {
    Metaflow = "true"
  }
}

/*
 Define a new firewall for our database instance.
*/
resource "aws_security_group" "rds_security_group" {
  name   = "${local.resource_prefix}-rds-sg"
  vpc_id = local.vpc_id

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
  storage_encrypted         = false
  engine                    = "postgres"
  engine_version            = "16"
  instance_class            = "db.t3.small"                       # Hardware configuration
  identifier                = "${local.resource_prefix}-metaflow" # used for dns hostname needs to be customer unique in region
  db_name                   = "metaflow"                          # unique id for CLI commands (name of DB table which is why we're not adding the prefix as no conflicts will occur and the API expects this table name)
  username                  = "metaflow"
  password                  = random_password.this.result
  db_subnet_group_name      = aws_db_subnet_group.this.id
  max_allocated_storage     = 1000                                                                                  # Upper limit of automatic scaled storage
  multi_az                  = false                                                                                 # Multiple availability zone?
  final_snapshot_identifier = "${local.resource_prefix}-metaflow-final-snapshot-${random_pet.final_snapshot_id.id}" # Snapshot upon delete
  vpc_security_group_ids    = [aws_security_group.rds_security_group.id]
  parameter_group_name      = aws_db_parameter_group.this.name
  tags = {
    Metaflow = "true"
  }
}

resource "aws_s3_bucket" "input_bucket" {
  bucket        = "${var.resource_prefix}-input"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "input_bucket" {
  bucket = aws_s3_bucket.input_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "input_bucket" {
  bucket      = aws_s3_bucket.input_bucket.id
  eventbridge = true
}

resource "aws_s3_bucket" "output_bucket" {
  bucket        = "${var.resource_prefix}-output"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "output_bucket" {
  bucket = aws_s3_bucket.output_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

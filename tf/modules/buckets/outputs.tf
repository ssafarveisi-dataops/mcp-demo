output "input_bucket_name" {
  value = aws_s3_bucket.input_bucket.bucket
}

output "input_bucket_arn" {
  value = aws_s3_bucket.input_bucket.arn
}

output "output_bucket_name" {
  value = aws_s3_bucket.output_bucket.bucket
}

output "output_bucket_arn" {
  value = aws_s3_bucket.output_bucket.arn
}
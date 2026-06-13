output "METAFLOW_DATATOOLS_S3ROOT" {
  value       = "s3://${aws_s3_bucket.this.bucket}/data"
  description = "Amazon S3 URL for Metaflow DataTools"
}

output "METAFLOW_DATASTORE_SYSROOT_S3" {
  value       = "s3://${aws_s3_bucket.this.bucket}/metaflow"
  description = "Amazon S3 URL for Metaflow DataStore"
}

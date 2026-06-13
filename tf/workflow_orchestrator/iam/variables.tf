variable "arbitrary_s3_bucket_name" {
  description = "Name of the S3 bucket where the raw data for the Metaflow workflow exists"
  type        = string
}

variable "metaflow_s3_datastore_root_bucket_name" {
  description = "Name of the S3 bucket where metaflow's artifacts are stored"
  type        = string
}

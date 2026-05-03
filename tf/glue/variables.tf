variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "data_lake_bucket" {
  description = "Bucket where the raw events are located"
  type        = string
  default     = "demo-data-lake-glue-etl"
}

variable "source_code_bucket" {
  description = "Bucket where the source code the spark ETL application is located"
  type        = string
  default     = "demo-glue-etl-pyspark-scripts"
}

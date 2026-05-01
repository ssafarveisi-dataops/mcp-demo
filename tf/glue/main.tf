resource "aws_glue_catalog_database" "main" {
  name        = "${local.resource_prefix}-data-lake"
  description = "Demo data lake catalog"

  create_table_default_permission {
    permissions = ["ALL"]
    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }
}

resource "aws_glue_catalog_table" "events" {
  name          = "events"
  database_name = aws_glue_catalog_database.main.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification           = "csv"
    "skip.header.line.count" = "1"
  }

  storage_descriptor {
    location      = "s3://demo-data-lake-glue-etl/raw/events/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "csv-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"

      parameters = {
        "separatorChar" = ","
        "quoteChar"     = "\""
      }
    }

    columns {
      name = "event_type"
      type = "string"
    }

    columns {
      name = "event_timestamp"
      type = "string"
    }
  }
}

resource "aws_glue_job" "transform_events" {
  name     = "${local.resource_prefix}-transform-events"
  role_arn = aws_iam_role.glue.arn

  command {
    name            = "glueetl"
    script_location = "s3://demo-glue-etl-pyspark-scripts/jobs/transform_events.py"
    python_version  = "3"
  }

  glue_version      = "4.0"
  worker_type       = "G.1X" # 4 vCPU, 16 GB RAM per worker
  number_of_workers = 2
  timeout           = 60 # minutes
  max_retries       = 1

  default_arguments = {
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = "s3://demo-glue-etl-pyspark-scripts/spark-logs/"
    "--job-language"                     = "python"
    "--TempDir"                          = "s3://demo-glue-etl-pyspark-scripts/temp/"
    "--source_database"                  = aws_glue_catalog_database.main.name
    "--source_table"                     = "events"
    "--output_path"                      = "s3://demo-data-lake-glue-etl/transformed/events/"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  tags = {
    Environment = "dev"
    Pipeline    = "event-processing"
  }
}

# Scheduled trigger - run the transform job every 5 minutes
resource "aws_glue_trigger" "transform_schedule" {
  name     = "${local.resource_prefix}-transform"
  type     = "SCHEDULED"
  schedule = "cron(0/5 * * * ? *)"

  actions {
    job_name = aws_glue_job.transform_events.name
  }
}

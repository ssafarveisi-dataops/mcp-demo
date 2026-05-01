import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql.functions import col, year, month, dayofmonth

# Get job parameters
args = getResolvedOptions(sys.argv, [
    "JOB_NAME",
    "source_database",
    "source_table",
    "output_path"
])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Read from the Glue Data Catalog
datasource = glueContext.create_dynamic_frame.from_catalog(
    database=args["source_database"],
    table_name=args["source_table"]
)

# Convert to Spark DataFrame for easier manipulation
df = datasource.toDF()

# Transform: filter, add date columns, drop nulls
transformed = (
    df.filter(col("event_type").isNotNull())
    .withColumn("event_year", year(col("event_timestamp")))
    .withColumn("event_month", month(col("event_timestamp")))
    .withColumn("event_day", dayofmonth(col("event_timestamp")))
)

# Write partitioned output
transformed.write \
    .mode("overwrite") \
    .partitionBy("event_year", "event_month", "event_day") \
    .csv(args["output_path"], header=True)

# Submit the job
job.commit()
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql.functions import col, when, year, month, dayofmonth

args = getResolvedOptions(sys.argv, [
    "JOB_NAME",
    "output_path",
    "bucket",
    "key"
])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

datasource = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={
        "paths": [f"s3://{args['bucket']}/{args['key']}"]
    },
    format="csv",
    format_options={
        "withHeader": True,
        "separator": ",",
        "quoteChar": '"'
    }
)

df = datasource.toDF()

df = ( 
    df.filter(col("event_type").isNotNull()) 
    .withColumn("event_year", year(col("event_timestamp")))
    .withColumn("event_month", month(col("event_timestamp")))
    .withColumn("event_day", dayofmonth(col("event_timestamp"))) 
)

df = df.withColumn(
    "event_category",
    when(col("event_type").like("%login%"), "authentication")
    .when(col("event_type").like("%signup%"), "authentication")
    .when(col("event_type").like("%upload%"), "data_operation")
    .when(col("event_type").like("%download%"), "data_operation")
    .when(col("event_type").like("%error%"), "system")
    .otherwise("other")
)

df.write \
    .mode("append") \
    .partitionBy("event_year", "event_month", "event_day") \
    .csv(args["output_path"], header=True)

job.commit()
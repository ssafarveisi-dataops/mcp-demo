import sys
from loguru import logger
from metaflow import FlowSpec, step, batch, retry, Parameter, S3
from custom import some_function

logger.remove()

logger.add(
    sys.stderr,
    level="INFO",
    colorize=False,
    format=(
        "{time:YYYY-MM-DD HH:mm:ss} | "
        "{level: <8} | "
        "{name}:{function}:{line} | "
        "{message}"
    ),
)


class MetaflowEvents(FlowSpec):

    # Parameters to send when we invoke the step function via event bridge or from within another step function
    bucket = Parameter('bucket', help='The S3 bucket where the json file is')
    prefix = Parameter('prefix', help='The S3 prefix that points to a json file')

    # Image pushed to AWS ECR (built with linux/amd64 platform)
    @batch(image="463470983643.dkr.ecr.eu-west-1.amazonaws.com/science-dev-demo-metaflow:latest")
    @retry(times=2, minutes_between_retries=1)
    @step(start=True)
    def read_raw_csv_file(self):
        """
        Reads csv files containing raw data from S3
        """
        import pandas as pd

        # Execute some function from a custom module to demonstrate how to include custom code in the image and use it in the step function
        logger.info("Executing some_function from custom module...")
        some_function()
        logger.info("Finished executing some_function.")

        logger.info(
            "MetaflowEvents started with bucket={} and prefix={}",
            self.bucket,
            self.prefix,
        )

        # Read CSV files from S3 (these are hypothetical csv files produced by a glue spark job)
        with S3() as s3:
            files = list(s3.list_recursive([f"s3://{self.bucket}/{self.prefix}"]))
            logger.info("Found {} file(s) under s3://{}/{}", len(files), self.bucket, self.prefix)

            loaded = s3.get_many([f.url for f in files])
            local_tmp_file_paths = [f.path for f in loaded]

            df = pd.DataFrame()

            for path in local_tmp_file_paths:
                logger.info("File downloaded from S3 to local path: {}", path)
                df = pd.concat([df, pd.read_csv(path)])

            self.df = df

        logger.info("Finished reading raw CSV files. DataFrame shape: {}", self.df.shape)

        self.next(self.preprocess)

    @batch(image="python:3.12", cpu=2, memory=5120)
    @step()
    def preprocess(self):
        """
        Runs preprocessing on the raw csv file fetched from S3
        """
        import pandas as pd

        logger.info("Preprocessing pandas DataFrame with shape: {}", self.df.shape)

        df_to_preprocess = self.df

        # Do some preprocessing here (for demonstration purposes)
        self.df_preprocessed = df_to_preprocess.groupby("event_category").count().reset_index()

        logger.info(
            "Preprocessing finished. Preprocessed DataFrame shape: {}",
            self.df_preprocessed.shape,
        )

        self.next(self.end)

    @batch(image="python:3.12")
    @step
    def end(self):
        """
        Last step
        """
        # Demonstrate object persistence across steps via AWS S3
        logger.info("Preprocessed DataFrame preview:\n{}", self.df_preprocessed.head())
        logger.info("MetaflowEvents is finished.")


if __name__ == '__main__':
    MetaflowEvents()

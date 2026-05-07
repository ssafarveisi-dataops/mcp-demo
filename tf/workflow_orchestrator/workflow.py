from metaflow import FlowSpec, step, batch, retry, Parameter, S3


class DemoMetaflowWorkflow(FlowSpec):

    # Parameters to send when we invoke the step function via event bridge or manually
    bucket = Parameter('bucket', help='The S3 bucket where the json file is')
    key = Parameter('key', help='The S3 key that points to a json file')

    # Or the image pushed to AWS ECR
    @batch(image="python:3.12")
    @retry(times=2, minutes_between_retries=1)
    @step(start=True)
    def read_raw_csv_file(self):
        """
        Reads a csv file containing raw data from S3
        """
        from metaflow import get_metadata
        import pandas as pd

        print(
            f"DemoMetaflowWorkflow started with bucket={self.bucket} "
            f"and key={self.key}"
        )
        
        # Read CSV file from S3 (this is the hypothetical csv file produced by a glue spark job)
        with S3() as s3:
            loaded = s3.get(f"s3://{self.bucket}/{self.key}")
            self.df = pd.read_csv(loaded.path)        

        self.next(self.preprocess)

    @batch(image="python:3.12", cpu=2, memory=5120)
    @step()
    def preprocess(self):
        """
        Runs preprocessing on the raw csv file fetched from S3
        """
        import pandas as pd

        print(f"Preprocessing the pandas dataframe of dim: {self.df.shape}")

        df_to_transform = self.df
        df_to_transform["event_timestamp"] = pd.to_datetime(df_to_transform["event_timestamp"], utc=True)
        df_to_transform = df_to_transform.sort_values("event_timestamp").reset_index(drop=True)
        df_to_transform["event_date"] = df_to_transform["event_timestamp"].dt.date
        df_to_transform["event_hour"] = df_to_transform["event_timestamp"].dt.hour
        df_to_transform["day_of_week"] = df_to_transform["event_timestamp"].dt.day_name()
        df_to_transform["event_type_encoded"] = df_to_transform["event_type"].astype("category").cat.codes
        
        self.df_transformed = df_to_transform

        self.next(self.end)

    @batch(image="python:3.12")
    @step
    def end(self):
        """
        The 'end' step is a regular step, so runs locally on the machine from
        which the flow is executed.

        """
        # Demonstrate object persistence across steps via AWS S3
        print(self.df_transformed)
        print("DemoMetaflowWorkflow is finished.")


if __name__ == '__main__':
    DemoMetaflowWorkflow()
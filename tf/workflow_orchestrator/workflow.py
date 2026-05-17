from metaflow import FlowSpec, step, batch, Parameter, S3, environment
from custom import some_function

class MetaflowEvents(FlowSpec):
    """
    A simple Metaflow workflow that demonstrates the use of batch steps with GPU support,
    environment variables, and S3 interactions. Metaflow internally at runtime try to
    install `boto3` and `requests` packages, but since we are using a custom image that
    already has these dependencies installed, we set the environment variable
    `METAFLOW_SKIP_INSTALL_DEPENDENCIES` to 1 to skip this step and avoid
    redundant installations. This also removes the need to install
    pip in the virtual environment created by uv in the custom image.
    """
    bucket = Parameter('bucket', help='The S3 bucket where the json file is')
    prefix = Parameter('prefix', help='The S3 prefix that points to a json file')

    # Share this image across all steps that require it to avoid redundant builds and uploads
    IMAGE = "463470983643.dkr.ecr.eu-west-1.amazonaws.com/science-dev-demo-metaflow-gpu:latest"

    @batch(image=IMAGE, cpu=2, memory=8192)
    @environment(vars={"METAFLOW_SKIP_INSTALL_DEPENDENCIES": 1})
    @step(start=True)
    def import_sklearn(self):
        import sklearn

        print(f"Scikit-learn version: {sklearn.__version__}")

        print("Running some_function()")
        some_function()
        print("Finished some_function()")

        with S3() as s3:
            files = list(s3.list_recursive([f"s3://{self.bucket}/{self.prefix}"]))
            print(f"Found {len(files)} file(s) under s3://{self.bucket}/{self.prefix}")

        self.next(self.import_cuda_torch)

    @batch(image=IMAGE, gpu=1, cpu=2, memory=8192)
    @environment(vars={"METAFLOW_SKIP_INSTALL_DEPENDENCIES": 1})
    @step
    def import_cuda_torch(self):
        try:
            import torch
            print(f"Successfully imported torch version: {torch.__version__}")
            # Check for GPU availability
            if torch.cuda.is_available():
                print("GPU is available. Running a simple tensor operation on GPU.")
                # Print GPU device name
                print(f"GPU Device Name: {torch.cuda.get_device_name(0)}")
                # Perform a simple tensor operation on the GPU to confirm it's working
                device = torch.device("cuda")
                x = torch.tensor([1.0, 2.0, 3.0], device=device)
                y = x * 2
                print(f"Tensor on GPU: {y}")
            else:
                print("GPU is not available. Please check your environment.")
        except ImportError as e:
            print(f"Failed to import torch: {e}")
            raise

        self.next(self.end)

    @step
    def end(self):
        """End step of the workflow."""
        pass

if __name__ == '__main__':
    MetaflowEvents()

from metaflow import FlowSpec, step, batch, Parameter, S3
from custom import some_function

class MetaflowEvents(FlowSpec):

    bucket = Parameter('bucket', help='The S3 bucket where the json file is')
    prefix = Parameter('prefix', help='The S3 prefix that points to a json file')

    # Share this image across all steps that require it to avoid redundant builds and uploads
    IMAGE = "463470983643.dkr.ecr.eu-west-1.amazonaws.com/science-dev-demo-metaflow-gpu:latest"

    @batch(image=IMAGE, cpu=2, memory=8192)
    @step
    def start(self):
        import sklearn

        print(f"Scikit-learn version: {sklearn.__version__}")

        print("Running some_function()")
        some_function()
        print("Finished some_function()")

        with S3() as s3:
            files = list(s3.list_recursive([f"s3://{self.bucket}/{self.prefix}"]))
            print(f"Found {len(files)} file(s) under s3://{self.bucket}/{self.prefix}")

        self.next(self.test_package_installed)

    @batch(image=IMAGE, gpu=1, cpu=2, memory=8192)
    @step
    def test_package_installed(self):
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

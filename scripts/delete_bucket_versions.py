import argparse
import boto3

PROFILE = "cognism-data-mlops-dev"
REGION = "eu-west-1"


def delete_all_versions(bucket_name: str) -> None:
    session = boto3.Session(profile_name=PROFILE)
    s3 = session.resource("s3", region_name=REGION)

    bucket = s3.Bucket(bucket_name)
    confirm = input(f"Delete ALL objects in '{args.bucket}'? (yes/no): ")
    if confirm.lower() != "yes":
        print("Aborted.")
        return

    print(f"Deleting all object versions in bucket: {bucket_name}")
    bucket.object_versions.delete()
    print("Done.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Delete all objects (including versions) from an S3 bucket"
    )

    parser.add_argument("--bucket", required=True, help="Name of the S3 bucket")

    args = parser.parse_args()

    delete_all_versions(args.bucket)

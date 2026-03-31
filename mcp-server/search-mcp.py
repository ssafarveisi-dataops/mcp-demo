from mcp.server.fastmcp import FastMCP
import os
import fnmatch
import boto3
from botocore.exceptions import ClientError

import requests

# Suppress MCP INFO logs to reduce console output
import logging

logging.getLogger("mcp").setLevel(logging.WARNING)

# Create an MCP server
mcp = FastMCP("search-mcp")


# Helper function to centralize file reading logic
def _read_prompt_file(file_path: str) -> str:
    """Read a prompt file with consistent error handling."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Prompt file not found: {file_path}")

    with open(file_path, "r", encoding="utf-8") as f:
        return f.read()


@mcp.prompt()
def system_prompt() -> str:
    """Instructions for Directory Search agent"""
    script_dir = os.path.dirname(__file__)
    prompt_path = os.path.join(script_dir, "prompts", "system_instructions.md")
    return _read_prompt_file(prompt_path)


# Tool: fetch_search_instructions
@mcp.tool()
def fetch_search_instructions(prompt_name: str) -> str:
    """
    Fetch instructions for a given prompt name from the prompts/ directory

    Args:
        prompt_name (str): Name of the prompt to fetch instructions for

    Available prompts:
        - write_summary
        - generate_documentation
        - extract_structured_data
        - report_path_type_check
        - write_post_summary
        - write_s3_file_summary

    Returns:
        str: Instructions for the given prompt
    """
    script_dir = os.path.dirname(__file__)
    prompt_path = os.path.join(script_dir, "prompts", f"{prompt_name}.md")
    return _read_prompt_file(prompt_path)


# Tool: search_directory
@mcp.tool()
def search_directory(path: str, pattern: str = "*") -> str:
    """
    Search for files and directories in a directory matching a pattern

    Args:
        path (str): Directory path to search
        pattern (str): Name pattern (e.g., '*.py', 'data*')

    Returns:
        str: List of matching file and directory paths
    """
    if not os.path.exists(path):
        raise FileNotFoundError(f"Directory '{path}' does not exist")

    # Validate that path is actually a directory
    if not os.path.isdir(path):
        raise NotADirectoryError(f"Path is not a directory: {path}")

    matches = []

    for root, dirs, files in os.walk(path):
        for d in dirs:
            if fnmatch.fnmatch(d, pattern):
                matches.append(f"[DIR] {os.path.join(root, d)}")

        for f in files:
            if fnmatch.fnmatch(f, pattern):
                matches.append(f"[FILE] {os.path.join(root, f)}")

    return "\n".join(matches) if matches else "No matching files or directories found."


# Tool: read_file_content
@mcp.tool()
def read_file_content(file_path: str) -> str:
    """
    Read the content of a file

    Args:
        file_path (str): Path to the file

    Returns:
        str: File content
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File '{file_path}' does not exist")

    with open(file_path, "r", encoding="utf-8") as f:
        return f.read()


# Tool: check_path_type
@mcp.tool()
def check_path_type(paths: list[str]) -> dict:
    """
    Determine whether each given path is a file or a directory.

    Args:
        paths (list[str]): List of paths to check

    Returns:
        dict: Mapping of path -> type ("file", "directory", "not_found", "unknown")
    """
    result = {}

    for path in paths:
        if not os.path.exists(path):
            result[path] = "not_found"
        elif os.path.isfile(path):
            result[path] = "file"
        elif os.path.isdir(path):
            result[path] = "directory"
        else:
            result[path] = "unknown"

    return result


# Tool: fetch_post_by_id
@mcp.tool()
def fetch_post_by_id(post_id: str) -> dict:
    """
    Fetch a post from an external API by ID.

    Args:
        post_id (str): ID of the post

    Returns:
        dict: JSON response containing the post data
    """
    url = f"https://jsonplaceholder.typicode.com/posts/{post_id}"

    try:
        response = requests.get(url, timeout=10)

        if response.status_code == 200:
            return response.json()
        elif response.status_code == 404:
            return {"error": "Post not found", "post_id": post_id}
        else:
            return {
                "error": f"Unexpected status code: {response.status_code}",
                "post_id": post_id,
            }

    except requests.exceptions.RequestException as e:
        return {"error": f"Request failed: {str(e)}", "post_id": post_id}


# Tool: read_s3_file_content
@mcp.tool()
def read_s3_file_content(s3_bucket: str, s3_key: str, aws_profile: str) -> str:
    """
    Read the content of a file from S3

    Args:
        s3_bucket (str): Name of the S3 bucket
        s3_key (str): Key (path) to the file in the bucket
        aws_profile (str): AWS profile name from ~/.aws/config

    Returns:
        str: File content
    """
    try:
        # Create session using the given AWS profile
        session = boto3.Session(profile_name=aws_profile)
        s3_client = session.client("s3")

        # Fetch object from S3
        response = s3_client.get_object(Bucket=s3_bucket, Key=s3_key)

        # Read and decode content
        content = response["Body"].read().decode("utf-8")

        return content

    except ClientError as e:
        raise RuntimeError(
            f"Failed to read s3://{s3_bucket}/{s3_key} using profile '{aws_profile}': {e}"
        )
    except Exception as e:
        raise RuntimeError(f"Unexpected error: {e}")


if __name__ == "__main__":
    mcp.run(transport="stdio")

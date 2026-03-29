from mcp.server.fastmcp import FastMCP
import os
import fnmatch

import requests

# Suppress MCP INFO logs to reduce console output
import logging

logging.getLogger("mcp").setLevel(logging.WARNING)

# Create an MCP server
mcp = FastMCP("search-mcp")


# Create prompt
@mcp.prompt()
def system_prompt() -> str:
    """Instructions for Directory Search agent"""
    script_dir = os.path.dirname(__file__)
    prompt_path = os.path.join(script_dir, "prompts", "system_instructions.md")
    with open(prompt_path, "r") as file:
        return file.read()


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

    Returns:
        str: Instructions for the given prompt
    """
    script_dir = os.path.dirname(__file__)
    prompt_path = os.path.join(script_dir, "prompts", f"{prompt_name}.md")

    if not os.path.exists(prompt_path):
        raise FileNotFoundError(f"Prompt '{prompt_name}' not found")

    with open(prompt_path, "r") as f:
        return f.read()


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

    matches = []

    for root, dirs, files in os.walk(path):
        # Check directories
        for d in dirs:
            if fnmatch.fnmatch(d, pattern):
                full_path = os.path.join(root, d)
                matches.append(f"[DIR] {full_path}")

        # Check files
        for f in files:
            if fnmatch.fnmatch(f, pattern):
                full_path = os.path.join(root, f)
                matches.append(f"[FILE] {full_path}")

    if not matches:
        return "No matching files or directories found."

    return "\n".join(matches)


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


if __name__ == "__main__":
    mcp.run(transport="stdio")

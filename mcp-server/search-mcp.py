from mcp.server.fastmcp import FastMCP
import os
import fnmatch

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
    Search for files in a directory matching a pattern

    Args:
        path (str): Directory path to search
        pattern (str): File pattern (e.g., '*.py', '*.txt')

    Returns:
        str: List of matching file paths
    """
    if not os.path.exists(path):
        raise FileNotFoundError(f"Directory '{path}' does not exist")

    matches = []

    for root, _, files in os.walk(path):
        for name in files:
            if fnmatch.fnmatch(name, pattern):
                full_path = os.path.join(root, name)
                matches.append(full_path)

    if not matches:
        return "No matching files found."

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


if __name__ == "__main__":
    mcp.run(transport="stdio")
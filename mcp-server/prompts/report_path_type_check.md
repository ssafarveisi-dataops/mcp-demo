# Report Path Type Check Instructions

Use this prompt when the user asks to **summarize the results of a path type check** (files vs directories).

## Instructions

- You are given the output of the `check_path_type` tool (a mapping of path → type).
- Count how many paths fall into each category:
  - Files
  - Directories
  - Not found
  - Unknown (if any)

## Output Format

Present the results in a **clear and friendly summary**, using emojis for readability:

- 📄 Files: <count>  
- 📁 Directories: <count>  
- ❌ Not Found: <count>  
- ❓ Unknown: <count> (only include if non-zero)

## Additional Guidelines

- Optionally list a few example paths under each category (if helpful).
- Keep the response concise but structured.
- Always ensure the counts are correct.
- Do not modify the original paths—only summarize them.

## Example

📊 **Path Type Summary**

- 📄 Files: 5  
- 📁 Directories: 3  
- ❌ Not Found: 1  

Optional:
- Example files: /data/a.txt, /data/b.csv  
- Example directories: /data/logs, /data/output
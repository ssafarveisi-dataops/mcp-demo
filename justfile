cd := justfile_directory()

[group: 'mcp']
start-mcp:
    #!/bin/bash
    if [ -f {{cd}}/.env ]; then
        if grep -Eq '^[[:space:]]*OPENAI_API_KEY[[:space:]]*=[[:space:]]*[^[:space:]]+' {{cd}}/.env; then
            echo "OPENAI_API_KEY found, running app..."
            uv run python main.py
        else
            echo "OPENAI_API_KEY missing or empty (whitespace handled)"
        fi
    else
        echo ".env file not found"
    fi
[group: 'mcp']
start-mcp:
    #!/bin/bash
    if [ -f {{justfile_directory()}}/.env ]; then
        if grep -Eq '^[[:space:]]*OPENAI_API_KEY[[:space:]]*=[[:space:]]*[^[:space:]]+' .env; then
            echo "OPENAI_API_KEY found, running app..."
            uv run python main.py
        else
            echo "OPENAI_API_KEY missing or empty (whitespace handled)"
        fi
    else
        echo ".env file not found"
    fi
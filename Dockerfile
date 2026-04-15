FROM python:3.12-slim

# Copy uv binaries
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Environment configuration
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0 \
    UV_NATIVE_TLS=1

WORKDIR /app

# Build argument
ARG BUILD_ENV=production
ENV BUILD_ENV=$BUILD_ENV

# Install certificates (root required)
COPY build/certificates/ /usr/local/share/ca-certificates/

RUN if [ "$BUILD_ENV" = "production" ] ; then \
        echo "production env"; \
    else \
        echo "non-production env: $BUILD_ENV"; \
        update-ca-certificates ; \
    fi

# Copy dependency files first (better caching)
COPY pyproject.toml uv.lock ./

# Install dependencies (still as root)
RUN uv sync --frozen --no-cache

# Copy application code
COPY aws_bedrock_agentcore/dummy_agent.py ./

# ---- Create non-root user ----
RUN useradd -m -u 10001 appuser

# Ensure proper ownership
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Run application
CMD ["uv", "run", "python", "dummy_agent.py"]
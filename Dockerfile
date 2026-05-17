# syntax=docker/dockerfile:1.7

FROM python:3.12-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0 \
    UV_SYSTEM_CERTS=1

WORKDIR /metaflow

# Install custom CA certificates for dependency installation
COPY build/certificates/ /usr/local/share/ca-certificates/

RUN update-ca-certificates

# First install dependencies only.
# This layer is highly cacheable as long as pyproject.toml and uv.lock do not change.
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync \
      --locked \
      --no-install-project \
      --no-dev \
      --only-group workflow

# Copy project metadata and install the project itself if needed
COPY pyproject.toml uv.lock README.md /metaflow/

# UV does not install pip by default.
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync \
      --locked \
      --no-dev \
      --only-group workflow \
    && /metaflow/.venv/bin/python -m ensurepip --upgrade \
    && /metaflow/.venv/bin/python -m pip install --upgrade pip

FROM python:3.12-slim AS runtime

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/metaflow/.venv/bin:${PATH}"

# Create non-root user
RUN groupadd --system --gid 999 nonroot \
    && useradd --system --gid 999 --uid 999 --create-home --home-dir /home/nonroot nonroot

COPY --from=builder --chown=nonroot:nonroot /metaflow /metaflow

USER nonroot

WORKDIR /metaflow

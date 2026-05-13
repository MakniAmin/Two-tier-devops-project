# ─────────────────────────────────────────────────
# Stage 1 — Builder
# Install dependencies in a full image
# ─────────────────────────────────────────────────
FROM python:3.9-slim AS builder

WORKDIR /app

# Install system dependencies needed to build mysql client
RUN apt-get update && apt-get install -y \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
# This is done before copying source code for layer caching:
# If requirements.txt didn't change, Docker reuses this layer
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ─────────────────────────────────────────────────
# Stage 2 — Runtime
# Clean, small image with only what we need to run
# ─────────────────────────────────────────────────
FROM python:3.9-slim

WORKDIR /app

# Install only runtime system dependencies (not build tools)
RUN apt-get update && apt-get install -y \
    default-libmysqlclient-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder stage
COPY --from=builder /root/.local /root/.local

# Copy application source code
COPY . .

# Security: create and switch to non-root user
# Running as root inside a container is a security risk
RUN adduser --disabled-password --gecos '' appuser \
    && chown -R appuser:appuser /app
USER appuser

# Make sure scripts in .local are usable
ENV PATH=/root/.local/bin:$PATH

# Document the port the app listens on
EXPOSE 5000

# Health check so Docker/Kubernetes knows if app is alive
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Use gunicorn (production server) instead of Flask dev server
# workers = (2 x CPU cores) + 1 → 3 workers for a 1-core server
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "3", "--timeout", "120", "app:app"]
# Dockerfile for Jac App with jac-scale (Coolify deployment)
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*


RUN pip install --no-cache-dir jaseci==2.2.13 requests python-dotenv

# Copy JAC application files
COPY main.jac api_walkers.jac auth_walkers.jac payment_walkers.jac credit_walkers.jac content_walkers.jac walkers.jac models.jac errors.jac jac.toml ./


# Create data, cache, and persistent DB directories
RUN mkdir -p /app/data /app/.jac/cache /app/jaseci_db

# Declare volumes so data survives redeployment
VOLUME ["/app/data", "/app/jaseci_db"]

# ==========================================
# CRITICAL: Compile .jac files to bytecode
# ==========================================

# Environment variables
ENV PORT=8000
ENV DEBUG=false
ENV LLM_MODEL=gpt-4o-mini

# ==========================================
# CRITICAL: MongoDB and Redis connection
# Set these in Coolify environment variables!
# ==========================================

# # Create non-root user for security
# RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app

# USER appuser

EXPOSE 8000

# Health check - uses the health_check walker endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=80s --retries=3 \
    CMD curl -f -X POST http://localhost:8000/walker/health_check \
        -H "Content-Type: application/json" \
        -d '{}' || exit 1

# ==========================================
# Production command
# ==========================================
# Note: jac start automatically binds to 0.0.0.0 in Docker
# --host and --no-client flags are not supported in jac 0.9.10
CMD ["sh", "-c", "jac start main.jac --port 8000"]
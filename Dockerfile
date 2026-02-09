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

# Install jaclang v0.10.0 + plugins
RUN pip install --no-cache-dir jaclang==0.10.0 jac-scale==0.1.7 byllm==0.4.18 requests python-dotenv

# Copy JAC application files
COPY main.jac api_walkers.jac auth_walkers.jac payment_walkers.jac credit_walkers.jac content_walkers.jac walkers.jac models.jac errors.jac jac.toml ./

# Create data, cache, and persistent DB directories
RUN mkdir -p /app/data /app/.jac /app/jaseci_db

# Pre-compile jac files (warm up compiler cache)
RUN jac check main.jac

# Declare volumes so data survives redeployment
VOLUME ["/app/data", "/app/jaseci_db"]

# Environment variables
ENV PORT=8000
ENV DEBUG=false
ENV LLM_MODEL=gpt-4o-mini

EXPOSE 8000

# Health check - uses the health_check walker endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=80s --retries=3 \
    CMD curl -f -X POST http://localhost:8000/walker/health_check \
        -H "Content-Type: application/json" \
        -d '{}' || exit 1

# Production command
CMD ["jac", "start", "main.jac", "--port", "8000"]

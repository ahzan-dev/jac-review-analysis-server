# Dockerfile for Jac Review Analyzer
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy JAC application files
COPY main.jac models.jac walkers.jac api_walkers.jac ./

# Create data and cache directories
RUN mkdir -p /app/data /app/.jac/cache

# Set environment variables
ENV PORT=8000
ENV DEBUG=false
ENV LLM_MODEL=gpt-4o-mini

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:$PORT/walker/health_check -X POST -H "Content-Type: application/json" -d '{}' || exit 1

# Run the JAC API server
CMD jac start main.jac --port $PORT

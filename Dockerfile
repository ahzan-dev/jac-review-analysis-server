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


# Alternative: Install from git (if you need latest)
RUN pip install --no-cache-dir \
    "git+https://github.com/Jaseci-Labs/jaseci.git#subdirectory=jaseci-package" 
    

# Install additional Python dependencies
RUN pip install --no-cache-dir requests python-dotenv

# Copy ALL JAC application files
COPY main.jac models.jac walkers.jac api_walkers.jac auth_walkers.jac ./

# Create data and cache directories
RUN mkdir -p /app/data /app/.jac/cache

# ==========================================
# CRITICAL: Compile .jac files to bytecode
# ==========================================
RUN jac build main.jac

# Environment variables
ENV PORT=8000
ENV DEBUG=false
ENV LLM_MODEL=gpt-4o-mini

# ==========================================
# CRITICAL: MongoDB and Redis connection
# Set these in Coolify environment variables!
# ==========================================

# Create non-root user for security
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/docs || exit 1

# ==========================================
# IMPORTANT: Do NOT use --scale flag!
# --scale is for Kubernetes, not Coolify
# ==========================================
CMD ["jac", "start", "main.jac", "--port", "8000"]

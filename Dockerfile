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

# Install Jac ecosystem in correct order
# IMPORTANT: Order matters due to dependencies
# RUN pip install --no-cache-dir \
#     jaclang \
#     jac-byllm \
#     jac-scale

# Alternative: Install from git (if you need latest)
RUN pip install --no-cache-dir \
    "git+https://github.com/Jaseci-Labs/jaseci.git#subdirectory=jac" \
    "git+https://github.com/Jaseci-Labs/jaseci.git#subdirectory=jac-byllm" \
    "git+https://github.com/Jaseci-Labs/jaseci.git#subdirectory=jac-scale"

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
ENV MONGODB_URI=mongodb://root:YJg4ky27Sb2y0q5bDz3kUMJcRXnamxHJcxYKcIgkL3wVfiR4KIScFFs6FiTZaa2Y@ig0ccokwsksks8o4cc4kww8g:27017/?directConnection=true
ENV REDIS_URL=redis://default:Sb7OrlWHl3iN9PBvWJKL53TOoxZkeHEJI5QTRxgq3jxaIH1Lp0i0PqGZP8FDcYIa@isg8k00c4coccs4g480wgwk4:6379/0

# JWT settings (for authentication)
ENV JWT_SECRET=your-super-secret-key-change-this
ENV JWT_EXP_DELTA_DAYS=7
ENV JWT_ALGORITHM=HS256

# Create non-root user for security
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# ==========================================
# IMPORTANT: Do NOT use --scale flag!
# --scale is for Kubernetes, not Coolify
# ==========================================
CMD jac start main.jac --port $PORT

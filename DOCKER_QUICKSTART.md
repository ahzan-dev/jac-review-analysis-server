# Docker Quick Start Guide

## Prerequisites
- Docker installed (version 20.10+)
- Docker Compose installed (optional, but recommended)

## Quick Start

### 1. Set up environment variables

```bash
# Copy the example file
cp .env.example .env

# Edit with your API keys
nano .env
```

Add your API keys:
```
SERPAPI_KEY=your-actual-serpapi-key
OPENAI_API_KEY=your-actual-openai-key
LLM_MODEL=gpt-4o-mini
DEBUG=false
PORT=8000
```

### 2. Build and run with Docker Compose (Recommended)

```bash
# Build and start the service
docker-compose up -d

# View logs
docker-compose logs -f review-analyzer

# Stop the service
docker-compose down
```

### 3. Alternative: Run with Docker directly

```bash
# Build the image
docker build -t review-analyzer:latest .

# Run the container
docker run -p 8000:8000 \
  --env-file .env \
  -v $(pwd)/data:/app/data \
  review-analyzer:latest

# Stop the container
docker stop <container-id>
```

## Testing the API

### Health Check
```bash
curl -X POST http://localhost:8000/walker/health_check \
  -H "Content-Type: application/json" \
  -d '{}'
```

Expected response:
```json
{
  "status": "healthy",
  "service": "review-analyzer",
  "version": "2.0"
}
```

### Test with Mock Data (No API Keys Required)
```bash
curl -X POST http://localhost:8000/walker/AnalyzeUrl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/...",
    "max_reviews": 20,
    "force_mock": true
  }'
```

### Test with Real Data
```bash
curl -X POST http://localhost:8000/walker/AnalyzeUrl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/citizenM+Paris+La+Defense/data=!4m2!3m1!1s0x47e664feaf1091e1:0x46783146292fe3fe",
    "max_reviews": 50,
    "report_type": "deep"
  }'
```

## Data Persistence

Your data is persisted in the following directory:

- **`./data/`** - Database files (main.session.db)

**Note:** The `.jac/` cache directory is NOT mounted as a volume. This ensures fresh bytecode compilation on each deployment and prevents environment variable caching issues. LLM response caching is handled internally by the database.

To backup your data:
```bash
tar -czf backup-$(date +%Y%m%d).tar.gz data
```

To restore:
```bash
tar -xzf backup-YYYYMMDD.tar.gz
```

## Useful Commands

### View container status
```bash
docker-compose ps
```

### View logs
```bash
# All logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100
```

### Restart service
```bash
docker-compose restart
```

### Rebuild after code changes
```bash
docker-compose up -d --build
```

### Remove all data and start fresh
```bash
docker-compose down -v
rm -rf data
docker-compose up -d
```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs review-analyzer

# Check if port 8000 is already in use
sudo lsof -i :8000

# Try rebuilding
docker-compose build --no-cache
docker-compose up -d
```

### API not responding
```bash
# Check if container is running
docker-compose ps

# Check health status
curl http://localhost:8000/walker/health_check -X POST -H "Content-Type: application/json" -d '{}'

# Restart container
docker-compose restart
```

### Out of disk space
```bash
# Clean up Docker system
docker system prune -a

# Remove old images
docker image prune -a
```

## Production Deployment

For production, consider:

1. **Use Docker Secrets** instead of .env file
2. **Set up reverse proxy** (nginx) with SSL
3. **Enable authentication** on API endpoints
4. **Set up monitoring** (Prometheus, Grafana)
5. **Configure log rotation**
6. **Set resource limits** in docker-compose.yml:

```yaml
services:
  review-analyzer:
    # ... other settings ...
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          memory: 1G
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SERPAPI_KEY` | (required*) | SerpAPI key for Google Maps data |
| `OPENAI_API_KEY` | (required*) | OpenAI API key for LLM |
| `LLM_MODEL` | `gpt-4o-mini` | LLM model to use |
| `DEBUG` | `false` | Enable debug mode |
| `PORT` | `8000` | API server port |

*Required for real data analysis. Can use `force_mock=true` for testing without keys.

## Support

If you encounter issues:
1. Check the logs: `docker-compose logs -f`
2. Verify your .env file has correct API keys
3. Ensure ports are not blocked by firewall
4. Try rebuilding: `docker-compose build --no-cache`

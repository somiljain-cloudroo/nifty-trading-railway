# Dockerfile for Baseline V1 Live Trading Agent
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY baseline_v1_live/ ./baseline_v1_live/
COPY data/ ./data/

# Create directories for logs and state
RUN mkdir -p /app/logs /app/state

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Healthcheck (check if process is running)
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import os; exit(0 if os.path.exists('/app/state/live_state.db') else 1)"

# Default command (can be overridden in docker-compose)
CMD ["python", "-m", "baseline_v1_live.baseline_v1_live", "--expiry", "30JAN26", "--atm", "23500"]

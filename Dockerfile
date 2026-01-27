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
# Note: data/ folder excluded - contains 1.3GB historical files not needed for live trading

# Create directories for logs and state
RUN mkdir -p /app/logs /app/state

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV EXPIRY=27JAN26
ENV ATM=24800

# No HEALTHCHECK - Railway handles this, and this is a background worker (no HTTP)
# Railway will detect no port exposed and skip HTTP healthcheck

# Use shell form to expand environment variables
CMD python -m baseline_v1_live.baseline_v1_live --expiry ${EXPIRY} --atm ${ATM}

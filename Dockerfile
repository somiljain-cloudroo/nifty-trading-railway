# Dockerfile for Baseline V1 Live Trading Agent + Monitor Dashboard
# Compatible with Railway, Docker Compose, and local development
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set timezone to IST
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    build-essential \
    tzdata \
    && ln -fs /usr/share/zoneinfo/Asia/Kolkata /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY baseline_v1_live/ ./baseline_v1_live/
# Note: data/ folder excluded - contains 1.3GB historical files not needed for live trading

# Copy start script
COPY start_trading.sh /app/start_trading.sh
RUN chmod +x /app/start_trading.sh && sed -i 's/\r$//' /app/start_trading.sh

# Create directories for logs and state with proper permissions
RUN mkdir -p /app/logs /app/state && chmod -R 755 /app/logs /app/state

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV TZ=Asia/Kolkata

# Expose monitor dashboard port
EXPOSE 8050

# Healthcheck (check if process is running)
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import os; exit(0 if os.path.exists('/app/baseline_v1_live/live_state.db') else 1)"

# Use start script as entrypoint (reads from environment variables)
CMD ["/app/start_trading.sh"]

# Dockerfile for Monitor Dashboard
FROM python:3.11-slim

WORKDIR /app

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy dashboard code
COPY . .

# Create state directory for volume mount
RUN mkdir -p /app/state

# Environment variables
ENV PORT=8050

# Run dashboard (headless mode for Docker)
# Use shell form to expand PORT variable (Railway sets this dynamically)
CMD streamlit run app.py --server.port=$PORT --server.address=0.0.0.0 --server.headless=true

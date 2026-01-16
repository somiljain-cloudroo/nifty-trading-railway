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

# Expose Dash port
EXPOSE 8050

# Run dashboard
CMD ["python", "app.py"]

#!/bin/bash
echo "[Trading Agent] Starting up..."

# ============================================
# ENVIRONMENT VARIABLE HANDLING
# ============================================

# Use environment variables with defaults
EXPIRY_DATE="${EXPIRY:-30JAN26}"
ATM_STRIKE="${ATM:-23500}"

# Railway/Cloud detection - check for RAILWAY_ENVIRONMENT or OPENALGO_HOST
if [ -n "$RAILWAY_ENVIRONMENT" ] || [ -n "$OPENALGO_HOST" ]; then
    echo "[Trading Agent] Cloud environment detected"
    echo "[Trading Agent] OPENALGO_HOST: ${OPENALGO_HOST:-not set}"
    echo "[Trading Agent] OPENALGO_WS_URL: ${OPENALGO_WS_URL:-not set}"
fi

# Log configuration
echo "[Trading Agent] Configuration:"
echo "  - EXPIRY: $EXPIRY_DATE"
echo "  - ATM: $ATM_STRIKE"
echo "  - PAPER_TRADING: ${PAPER_TRADING:-true}"
echo "  - OPENALGO_HOST: ${OPENALGO_HOST:-http://openalgo:5000}"

# ============================================
# DIRECTORY SETUP
# ============================================
mkdir -p /app/logs /app/state 2>/dev/null || true

# ============================================
# WAIT FOR OPENALGO (if in Docker/Railway environment)
# ============================================
OPENALGO_URL="${OPENALGO_HOST:-http://openalgo:5000}"

echo "[Trading Agent] Waiting for OpenAlgo to be ready at $OPENALGO_URL..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if python -c "import urllib.request; urllib.request.urlopen('$OPENALGO_URL', timeout=5)" 2>/dev/null; then
        echo "[Trading Agent] OpenAlgo is ready!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "[Trading Agent] Waiting for OpenAlgo... (attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep 5
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "[Trading Agent] WARNING: Could not connect to OpenAlgo after $MAX_RETRIES attempts"
    echo "[Trading Agent] Proceeding anyway - trading agent will retry connections"
fi

# ============================================
# START MONITOR DASHBOARD (background)
# ============================================
if [ "${ENABLE_MONITOR:-true}" = "true" ]; then
    echo "[Monitor Dashboard] Starting on port 8050..."
    export DB_PATH=/app/baseline_v1_live/live_state.db
    cd /app/baseline_v1_live/monitor_dashboard
    streamlit run app.py \
        --server.port=8050 \
        --server.address=0.0.0.0 \
        --server.headless=true \
        --browser.gatherUsageStats=false \
        > /app/logs/monitor.log 2>&1 &
    MONITOR_PID=$!
    echo "[Monitor Dashboard] Started with PID $MONITOR_PID"
    cd /app
fi

# ============================================
# START TRADING AGENT (foreground)
# ============================================
echo "[Trading Agent] Starting baseline_v1_live with expiry=$EXPIRY_DATE, atm=$ATM_STRIKE"
cd /app

python -m baseline_v1_live.baseline_v1_live \
    --expiry "$EXPIRY_DATE" \
    --atm "$ATM_STRIKE"

# Railway Deployment Guide

## Overview

This guide explains how to deploy the NIFTY Options Trading System to Railway.app with two services:
1. **OpenAlgo** - Broker integration platform (port 5000 + WebSocket 8765)
2. **Trading Agent** - Baseline V1 live trading strategy

## Prerequisites

1. Railway.app account (https://railway.app)
2. GitHub repository connected to Railway
3. DefinEdge broker account with API credentials

## Deployment Steps

### Step 1: Create Railway Project

1. Go to https://railway.app/new
2. Select "Deploy from GitHub repo"
3. Choose `nifty_options_agent` repository
4. Select the `feature/docker-local-working` branch

### Step 2: Deploy OpenAlgo Service

1. In Railway dashboard, click "New Service"
2. Select "GitHub Repo" → Same repository
3. Configure:
   - **Name**: `openalgo`
   - **Root Directory**: `/` (root)
   - **Dockerfile Path**: `Dockerfile.openalgo`
4. Add Environment Variables (Settings → Variables):

```env
# Broker Configuration
BROKER_API_KEY=your_definedge_api_key
BROKER_API_SECRET=your_definedge_api_secret

# Security (generate new random values!)
APP_KEY=generate_random_64_char_hex
API_KEY_PEPPER=generate_random_64_char_hex

# Flask Configuration
FLASK_ENV=production
FLASK_HOST_IP=0.0.0.0
FLASK_PORT=5000

# WebSocket
WEBSOCKET_HOST=0.0.0.0
WEBSOCKET_PORT=8765

# Database
DATABASE_URL=sqlite:///db/openalgo.db

# Generate random keys with:
# python -c "import secrets; print(secrets.token_hex(32))"
```

5. Configure Networking:
   - Enable "Public Networking"
   - Note the generated URL (e.g., `openalgo-production.up.railway.app`)

### Step 3: Deploy Trading Agent Service

1. Click "New Service" again
2. Select same GitHub repo
3. Configure:
   - **Name**: `trading-agent`
   - **Root Directory**: `/` (root)
   - **Dockerfile Path**: `Dockerfile`
4. Add Environment Variables:

```env
# OpenAlgo Connection (use Railway internal URL)
OPENALGO_API_KEY=your_openalgo_api_key
OPENALGO_HOST=http://openalgo.railway.internal:5000
OPENALGO_WS_URL=ws://openalgo.railway.internal:8765

# Trading Configuration
EXPIRY=27JAN26
ATM=24800
PAPER_TRADING=true

# State Persistence
STATE_DB_PATH=/app/state/live_state.db

# Telegram Notifications (optional)
TELEGRAM_ENABLED=false
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
```

5. Configure:
   - No public networking needed (background worker)
   - Add volume for `/app/state` (persistent storage)

### Step 4: Configure Service Communication

Railway provides internal networking between services:

| Service | Internal URL |
|---------|-------------|
| OpenAlgo API | `http://openalgo.railway.internal:5000` |
| OpenAlgo WebSocket | `ws://openalgo.railway.internal:8765` |

### Step 5: Add Persistent Storage

For both services, add volumes:

**OpenAlgo:**
- Mount: `/app/db` (for SQLite databases)

**Trading Agent:**
- Mount: `/app/state` (for live_state.db)

### Step 6: Deploy

1. Push any changes to trigger deployment
2. Or click "Deploy" in Railway dashboard
3. Monitor logs in Railway dashboard

## Environment Variables Reference

### OpenAlgo Service

| Variable | Description | Required |
|----------|-------------|----------|
| `BROKER_API_KEY` | DefinEdge API Key | Yes |
| `BROKER_API_SECRET` | DefinEdge API Secret | Yes |
| `APP_KEY` | OpenAlgo app key (64 hex chars) | Yes |
| `API_KEY_PEPPER` | Security pepper (64 hex chars) | Yes |
| `FLASK_ENV` | `production` | Yes |
| `DATABASE_URL` | SQLite path | Yes |

### Trading Agent Service

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENALGO_API_KEY` | API key from OpenAlgo | Yes |
| `OPENALGO_HOST` | OpenAlgo API URL | Yes |
| `OPENALGO_WS_URL` | OpenAlgo WebSocket URL | Yes |
| `EXPIRY` | Option expiry (e.g., `27JAN26`) | Yes |
| `ATM` | ATM strike price | Yes |
| `PAPER_TRADING` | `true` or `false` | Yes |
| `STATE_DB_PATH` | Path to state database | Yes |

## Monitoring

### View Logs
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# View logs
railway logs -s openalgo
railway logs -s trading-agent
```

### Railway Dashboard
- View real-time logs
- Monitor resource usage
- Check deployment status

## Troubleshooting

### OpenAlgo not connecting to broker
1. Check BROKER_API_KEY and BROKER_API_SECRET
2. Login to OpenAlgo dashboard and authenticate with broker
3. Check logs for authentication errors

### Trading Agent not receiving data
1. Verify OPENALGO_HOST uses internal Railway URL
2. Check WebSocket connection in logs
3. Verify EXPIRY matches current weekly expiry

### Database errors
1. Ensure volumes are mounted correctly
2. Check write permissions in container

## Cost Estimation

Railway pricing (as of 2024):
- **Starter**: $5/month includes $5 usage
- **Pro**: $20/month includes $20 usage

Estimated usage for this system:
- ~$10-15/month for both services running 24/7

## Security Notes

1. **Never commit API keys** - Use Railway environment variables
2. **Generate new security keys** for production
3. **Enable PAPER_TRADING=true** initially
4. **Test thoroughly** before going live

## Going Live Checklist

- [ ] OpenAlgo deployed and accessible
- [ ] Broker authenticated via OpenAlgo dashboard
- [ ] Trading agent connected to OpenAlgo
- [ ] Data flowing (100% coverage in heartbeat)
- [ ] Paper trading verified for 1+ week
- [ ] Change PAPER_TRADING=false
- [ ] Monitor first live session closely

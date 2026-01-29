# Railway Deployment Guide

Deploy the NIFTY Options Trading Agent to Railway for cloud-based automated trading.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Railway Project                          │
│                                                             │
│  ┌──────────────┐     ┌──────────────────┐                │
│  │   OpenAlgo   │◄────┤  Trading Agent   │                │
│  │   Service    │     │     Service      │                │
│  │  (Port 5000) │     │                  │                │
│  │  (Port 8765) │     └──────────────────┘                │
│  └──────────────┘              │                          │
│         │                      │                          │
│         ▼                      ▼                          │
│   Railway Volume         Railway Volume                   │
│   (openalgo_data)       (trading_state)                   │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. Railway account (https://railway.app)
2. GitHub account with this repository
3. Broker API credentials (Zerodha/Angel/etc.)

## Deployment Steps

### Step 1: Create Railway Project

1. Go to https://railway.app/dashboard
2. Click "New Project" → "Deploy from GitHub repo"
3. Select your `nifty_options_agent` repository

### Step 2: Deploy OpenAlgo Service

1. In Railway dashboard, click "New Service" → "GitHub Repo"
2. Select the same repository
3. Configure the service:
   - **Root Directory**: `openalgo-zerodha/openalgo`
   - **Service Name**: `openalgo`

4. Add environment variables (Settings → Variables):

```bash
# Required
HOST_SERVER=https://openalgo-production-xxxx.up.railway.app
REDIRECT_URL=https://openalgo-production-xxxx.up.railway.app/zerodha/callback
BROKER_API_KEY=your_broker_api_key
BROKER_API_SECRET=your_broker_api_secret
APP_KEY=your_64_char_hex_key
API_KEY_PEPPER=your_64_char_hex_pepper

# Flask
FLASK_ENV=production
FLASK_DEBUG=False

# Database
DATABASE_URL=sqlite:///db/openalgo.db

# Security
CSP_UPGRADE_INSECURE_REQUESTS=TRUE
CORS_ENABLED=TRUE
```

5. Add a persistent volume:
   - Mount path: `/app/db`
   - This preserves the SQLite database across deployments

6. Generate a domain:
   - Settings → Networking → Generate Domain
   - Note this URL for the trading agent configuration

### Step 3: Deploy Trading Agent Service

1. Click "New Service" → "GitHub Repo"
2. Select the same repository
3. Configure the service:
   - **Root Directory**: `/` (root of repository)
   - **Service Name**: `trading-agent`

4. Add environment variables:

```bash
# OpenAlgo Connection (use Railway internal networking)
OPENALGO_HOST=http://openalgo.railway.internal:5000
OPENALGO_WS_URL=ws://openalgo.railway.internal:8765

# Get this from OpenAlgo dashboard after first login
OPENALGO_API_KEY=your_openalgo_api_key

# Trading Parameters
EXPIRY=30JAN26
ATM=23500

# CRITICAL: Keep true for testing
PAPER_TRADING=true

# Risk Management
TOTAL_CAPITAL=10000000
R_VALUE=6500
MAX_POSITIONS=5
MAX_LOTS_PER_POSITION=10

# Telegram (optional)
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=

# Logging
LOG_LEVEL=INFO
```

5. Add a persistent volume:
   - Mount path: `/app/state`
   - This preserves the trading state database

### Step 4: Deploy Monitor Dashboard (Optional)

1. Click "New Service" → "GitHub Repo"
2. Select the same repository
3. Configure:
   - **Root Directory**: `baseline_v1_live/monitor_dashboard`
   - **Service Name**: `monitor`

4. Add environment variables:

```bash
DB_PATH=/app/state/live_state.db
```

5. Mount the same volume as trading-agent:
   - Mount path: `/app/state` (read-only)

6. Generate a public domain for dashboard access

## Environment Variables Reference

### OpenAlgo Service

| Variable | Required | Description |
|----------|----------|-------------|
| `HOST_SERVER` | Yes | Your Railway app URL (https://...) |
| `REDIRECT_URL` | Yes | Broker callback URL |
| `BROKER_API_KEY` | Yes | From your broker |
| `BROKER_API_SECRET` | Yes | From your broker |
| `APP_KEY` | Yes | 64-char hex string |
| `API_KEY_PEPPER` | Yes | 64-char hex string |
| `FLASK_ENV` | No | `production` (default) |
| `DATABASE_URL` | No | SQLite path |

### Trading Agent Service

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENALGO_HOST` | Yes | OpenAlgo URL |
| `OPENALGO_WS_URL` | Yes | WebSocket URL |
| `OPENALGO_API_KEY` | Yes | From OpenAlgo dashboard |
| `EXPIRY` | Yes | Option expiry (e.g., `30JAN26`) |
| `ATM` | Yes | ATM strike (e.g., `23500`) |
| `PAPER_TRADING` | Yes | `true` or `false` |
| `TOTAL_CAPITAL` | No | Default: 10000000 |
| `R_VALUE` | No | Default: 6500 |

## Generating Security Keys

Generate APP_KEY and API_KEY_PEPPER:

```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

Run this twice - once for each key.

## First-Time Setup

1. **Deploy OpenAlgo first**
2. **Access OpenAlgo dashboard**: Visit your OpenAlgo URL
3. **Create admin account**: Follow the setup wizard
4. **Connect broker**: Login with your broker credentials
5. **Get API key**: Go to API Keys section and copy the key
6. **Add API key to Trading Agent**: Update `OPENALGO_API_KEY` variable
7. **Deploy Trading Agent**: It will now connect to OpenAlgo

## Monitoring

### View Logs

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# View logs
railway logs -s openalgo
railway logs -s trading-agent
```

### Check Health

- OpenAlgo: Visit `https://your-openalgo-domain.up.railway.app`
- Monitor: Visit `https://your-monitor-domain.up.railway.app`

## Daily Operations

### Update Trading Parameters

1. Go to Railway dashboard
2. Select `trading-agent` service
3. Update variables:
   - `EXPIRY=06FEB26`
   - `ATM=23700`
4. Service will automatically restart

### Go Live (Production Trading)

**WARNING: Only after thorough paper trading!**

1. Verify paper trading results for at least 1 week
2. Update `PAPER_TRADING=false` in trading-agent variables
3. Monitor closely for the first hour
4. Check broker dashboard for actual orders

## Troubleshooting

### OpenAlgo not accessible

1. Check Railway deployment logs
2. Verify environment variables are set
3. Ensure volume is mounted at `/app/db`

### Trading Agent can't connect to OpenAlgo

1. Use internal URL: `http://openalgo.railway.internal:5000`
2. Check OpenAlgo service is healthy
3. Verify OPENALGO_API_KEY is correct

### Database errors

1. Ensure volumes are properly mounted
2. Check volume has sufficient space
3. Railway volumes persist across deployments

### WebSocket connection issues

1. Use internal WebSocket URL
2. Check OpenAlgo WebSocket proxy is running (port 8765)
3. Review logs for connection errors

## Cost Estimation

Railway pricing (as of 2025):
- **Starter Plan**: $5/month base + usage
- **Pro Plan**: $20/month with better resources

Typical usage for this setup:
- 2-3 services running during market hours (9:15 AM - 3:30 PM IST)
- ~6 hours/day × 22 trading days = ~132 hours/month
- Estimated cost: $10-30/month depending on plan

## Security Considerations

1. **Never commit .env files** to git
2. **Use Railway's encrypted variables** for secrets
3. **Restrict OpenAlgo access** - don't expose unnecessary endpoints
4. **Regular key rotation** - update APP_KEY periodically
5. **Monitor for unauthorized access** - check logs regularly

## Backup Strategy

1. **Database backups**: Railway volumes persist, but export regularly
2. **Configuration backup**: Keep a local copy of environment variables
3. **Trade logs**: Download from monitor dashboard periodically

## Support

- Railway Docs: https://docs.railway.app
- OpenAlgo Issues: https://github.com/marketcalls/openalgo/issues
- Trading Agent Issues: Check repository issues

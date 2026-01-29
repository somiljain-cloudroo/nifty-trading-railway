# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Automated options trading system for NIFTY index using swing-break strategy:
- Detect swing lows → Apply 2-stage filters → Place proactive SL (stop-limit) orders BEFORE breaks
- Risk: Rs.6,500 per R, daily targets of +/-5R
- Broker: OpenAlgo integration layer (http://127.0.0.1:5000 local, http://openalgo:5000 in Docker)
- Mode: Paper trading by default (PAPER_TRADING=true in .env)

## Build & Run Commands

### Docker (Production - Recommended)

```bash
# Build and start all services
docker compose up -d

# View logs
docker compose logs -f trading_agent

# Restart after code changes
docker compose up -d --build

# Stop all services
docker compose down

# Shell into container
docker compose exec trading_agent bash
```

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run system check
python -m baseline_v1_live.check_system

# Start trading (paper mode)
python -m baseline_v1_live.baseline_v1_live --expiry 30JAN26 --atm 23500

# Run monitor dashboard
cd baseline_v1_live/monitor_dashboard && streamlit run app.py
```

### Environment Variables

Required in `.env` (root level for Docker, `baseline_v1_live/.env` for local):
```
OPENALGO_API_KEY=your_api_key
PAPER_TRADING=true
EXPIRY=30JAN26
ATM=23500
```

## Architecture

```
WebSocket ticks → DataPipeline (1-min OHLCV + VWAP)
                       ↓
              SwingDetector (watch-based confirmation)
                       ↓
              ContinuousFilter (static + dynamic filters)
                       ↓
              OrderManager (proactive SL orders)
                       ↓
              PositionTracker (R-multiple accounting)
                       ↓
              StateManager (SQLite persistence)
```

### Core Files (baseline_v1_live/)

| File | Purpose |
|------|---------|
| `baseline_v1_live.py` | Main orchestrator, entry point |
| `config.py` | All configuration parameters |
| `data_pipeline.py` | WebSocket → 1-min OHLCV bars + VWAP |
| `swing_detector.py` | Multi-symbol swing low/high detection |
| `continuous_filter.py` | Two-stage filtering engine |
| `order_manager.py` | Proactive SL orders for entry + exit |
| `position_tracker.py` | R-multiple accounting |
| `state_manager.py` | SQLite persistence |

### Key Concepts

**Swing Detection**: Watch-based system where watch counters increment when future bars confirm turning points. When counter reaches 2, swing is confirmed. Swings must alternate: High → Low → High → Low.

**Strike Filtration**:
- Stage-1 (Static): Price range 100-300 Rs, VWAP premium ≥4%
- Stage-2 (Dynamic): SL% 2-10%, recalculated every bar
- Stage-3 (Tie-breaker): Select best strike per option type (CE/PE)

**Proactive Orders**: SL orders placed BEFORE swing breaks (trigger: swing_low - 0.05, limit: trigger - 3). Orders sit dormant until triggered, preventing slippage.

## Critical Safety Rules

1. **PAPER_TRADING=true by default** - Never change without thorough testing
2. **Position limits**: Max 5 total, max 3 CE, max 3 PE (hardcoded in config.py)
3. **Daily exits**: Auto-exit at +/-5R or 3:15 PM IST
4. **R-based sizing**: Always use formula, never flat lot sizing
5. **Reconciliation**: Positions synced with broker every 60 seconds
6. **NO emojis in terminal output** - Use ASCII only for portability

## Code Change Guidelines

When modifying core trading files:
1. Make minimal, focused changes
2. Don't refactor unrelated code
3. Test in paper trading mode first
4. Verify with `python -m baseline_v1_live.check_system`

### Symbol Format
```python
# Format: NIFTY[DDMMMYY][STRIKE][CE/PE]
symbol = f"NIFTY{expiry}{strike}CE"  # e.g., NIFTY30JAN2623500CE
```

### Time Handling
```python
import pytz
IST = pytz.timezone('Asia/Kolkata')
now = datetime.now(IST)
```

### Logging Convention
```python
logger.info("[TAG] Message")  # Tags: [SWING], [ORDER], [FILL], [EXIT], [HEARTBEAT]
```

## Troubleshooting

| Issue | Check |
|-------|-------|
| No trades | Filter summary logs: `[FILTER-SUMMARY]` - check VWAP<4% or SL% out of range |
| No ticks | OpenAlgo WebSocket connection, broker login |
| Orders not placing | API key, order_manager logs |
| Position mismatch | Reconciliation logs, broker dashboard |

## Docker Services

| Service | Port | Description |
|---------|------|-------------|
| openalgo | 5001 (host) → 5000 (container) | Broker API layer |
| openalgo | 8765 | WebSocket proxy |
| trading_agent | - | Core trading logic |
| monitor | 8050 | Real-time dashboard |

## Reference Documentation

Detailed theory documents in `baseline_v1_live/`:
- `SWING_DETECTION_THEORY.md` - Watch-based confirmation system
- `STRIKE_FILTRATION_THEORY.md` - Multi-stage filter pipeline
- `ORDER_EXECUTION_THEORY.md` - Proactive order placement

Path-specific rules in `.claude/rules/`:
- `trading-rules.md`, `swing-detection-rules.md`, `data-pipeline-rules.md`
- `openalgo-integration-rules.md`, `safety-rules.md`

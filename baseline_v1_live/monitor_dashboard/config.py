import os
from pathlib import Path

# Use environment variable if set, otherwise use relative path
# Default: ../live_state.db (relative to monitor_dashboard folder)
STATE_DB_PATH = os.environ.get('DB_PATH', str(Path(__file__).resolve().parent.parent / "live_state.db"))

FAST_REFRESH = 5
SLOW_REFRESH = 30

STRATEGY_NAME = "Baseline V1 Live"

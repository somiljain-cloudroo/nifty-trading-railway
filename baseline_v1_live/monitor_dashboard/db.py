import os
import sqlite3
import pandas as pd

# SQLAlchemy support for PostgreSQL (eliminates pandas warnings)
try:
    from sqlalchemy import create_engine, text
    HAS_SQLALCHEMY = True
except ImportError:
    HAS_SQLALCHEMY = False

from config import STATE_DB_PATH

# Database URL from environment (for PostgreSQL on Railway)
DATABASE_URL = os.environ.get('DATABASE_URL', '')

# Determine database type
DB_TYPE = 'postgresql' if DATABASE_URL.startswith('postgresql://') else 'sqlite'

# Create SQLAlchemy engine for PostgreSQL (reusable connection pool)
_pg_engine = None
if DB_TYPE == 'postgresql' and HAS_SQLALCHEMY:
    _pg_engine = create_engine(DATABASE_URL)


def read_df(query, params=None):
    """Read data from database into pandas DataFrame"""
    if DB_TYPE == 'postgresql':
        if not HAS_SQLALCHEMY:
            raise ImportError("SQLAlchemy is required for PostgreSQL. Install with: pip install sqlalchemy")
        # Convert SQLite placeholders (?) to PostgreSQL (%s)
        if params:
            query = query.replace('?', '%s')
        # Pass engine directly to pandas (recommended for SQLAlchemy 2.0)
        return pd.read_sql(query, _pg_engine, params=params)
    else:
        conn = sqlite3.connect(STATE_DB_PATH, check_same_thread=False)
        try:
            return pd.read_sql(query, conn, params=params)
        finally:
            conn.close()

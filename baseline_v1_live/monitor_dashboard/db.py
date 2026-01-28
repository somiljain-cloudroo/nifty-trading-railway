import os
import sqlite3
import pandas as pd

# SQLAlchemy support for PostgreSQL (eliminates pandas warnings)
try:
    from sqlalchemy import create_engine
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


def get_connection():
    """Get database connection (PostgreSQL or SQLite)"""
    if DB_TYPE == 'postgresql':
        if not HAS_SQLALCHEMY:
            raise ImportError("SQLAlchemy is required for PostgreSQL. Install with: pip install sqlalchemy")
        return _pg_engine.connect()
    else:
        return sqlite3.connect(
            STATE_DB_PATH,
            check_same_thread=False
        )


def read_df(query, params=None):
    """Read data from database into pandas DataFrame"""
    conn = get_connection()
    try:
        # Convert SQLite placeholders (?) to PostgreSQL (%s) if needed
        if DB_TYPE == 'postgresql' and params:
            query = query.replace('?', '%s')
        return pd.read_sql(query, conn, params=params)
    finally:
        conn.close()

import os
import sqlite3
import pandas as pd

# PostgreSQL support (optional - for Railway deployment)
try:
    import psycopg2
    import psycopg2.extras
    HAS_POSTGRES = True
except ImportError:
    HAS_POSTGRES = False

from config import STATE_DB_PATH

# Database URL from environment (for PostgreSQL on Railway)
DATABASE_URL = os.environ.get('DATABASE_URL', '')

# Determine database type
DB_TYPE = 'postgresql' if DATABASE_URL.startswith('postgresql://') else 'sqlite'


def get_connection():
    """Get database connection (PostgreSQL or SQLite)"""
    if DB_TYPE == 'postgresql':
        if not HAS_POSTGRES:
            raise ImportError("psycopg2 is required for PostgreSQL. Install with: pip install psycopg2-binary")
        return psycopg2.connect(DATABASE_URL)
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

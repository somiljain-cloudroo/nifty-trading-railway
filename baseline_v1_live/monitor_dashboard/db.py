import os
import sqlite3
import pandas as pd

# SQLAlchemy support for PostgreSQL
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

        # Use SQLAlchemy text() wrapper and connection context
        with _pg_engine.connect() as conn:
            if params:
                # Convert params tuple to dict for SQLAlchemy text()
                # Replace %s with :p0, :p1, etc. for named parameters
                param_dict = {}
                for i, val in enumerate(params):
                    query = query.replace('%s', f':p{i}', 1)
                    param_dict[f'p{i}'] = val
                result = conn.execute(text(query), param_dict)
            else:
                result = conn.execute(text(query))

            # Convert to DataFrame
            df = pd.DataFrame(result.fetchall(), columns=result.keys())
            return df
    else:
        # Use URI mode with immutable flag for read-only access
        # This works even when the filesystem is mounted read-only
        db_uri = f"file:{STATE_DB_PATH}?mode=ro&immutable=1"
        conn = sqlite3.connect(db_uri, uri=True, check_same_thread=False)
        try:
            return pd.read_sql(query, conn, params=params)
        finally:
            conn.close()

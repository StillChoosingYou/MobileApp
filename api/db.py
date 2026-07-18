import os

import psycopg2
import psycopg2.extras


def get_connection():
    """
    Opens a new connection for this request. Call `conn.close()` when done
    (every route below does this in a `finally` block) — a serverless
    function can have many short-lived invocations, so holding a connection
    open longer than one request risks exhausting Supabase's connection
    limit.

    DATABASE_URL must be Supabase's **Transaction mode (Supavisor)**
    connection string — the one on port 6543:

        postgresql://postgres.<project-ref>:<password>@aws-0-<region>.pooler.supabase.com:6543/postgres

    Get this exact string from: Supabase dashboard → Project Settings →
    Database → Connection string → "Transaction" mode. Don't use the direct
    connection (port 5432, db.<ref>.supabase.co) here — it isn't pooled, and
    a burst of serverless invocations (many short requests hitting Vercel at
    once) can exhaust Postgres's connection limit quickly on smaller
    Supabase tiers.
    """
    database_url = os.environ["DATABASE_URL"]
    return psycopg2.connect(database_url, cursor_factory=psycopg2.extras.RealDictCursor)

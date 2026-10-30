"""Run the complete ELT pipeline in the required order."""
import os
import subprocess
import sys
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

ROOT = Path(__file__).resolve().parent
SQL_DIR = ROOT / "sql"

def get_engine():
    load_dotenv(ROOT / ".env")
    password = os.getenv("MYSQL_PASSWORD", "")
    if not password:
        raise ValueError("Missing MYSQL_PASSWORD. Copy .env.example to .env and set credentials.")
    return create_engine(URL.create(
        "mysql+pymysql",
        username=os.getenv("MYSQL_USER", "root"),
        password=password,
        host=os.getenv("MYSQL_HOST", "localhost"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        database=os.getenv("MYSQL_DATABASE", "titanic_elt"),
        query={"charset": "utf8mb4"},
    ), pool_pre_ping=True)

def run_sql_file(engine, filename):
    # SQL files in this project use ordinary semicolon-terminated statements,
    # without semicolons embedded in strings or stored procedures.
    sql_text = (SQL_DIR / filename).read_text(encoding="utf-8")
    statements = [part.strip() for part in sql_text.split(";") if part.strip()]
    with engine.begin() as conn:
        for statement in statements:
            conn.exec_driver_sql(statement)

def main():
    load_dotenv(ROOT / ".env")
    # Extract/load is intentionally a separate Python step; it does not clean data.
    subprocess.run([sys.executable, str(ROOT / "extract_load.py")], cwd=ROOT, check=True)

    engine = get_engine()
    for filename in (
        "01_staging.sql",
        "02_transform.sql",
        "03_analytics.sql",
        "04_quality_checks.sql",
    ):
        print(f"Running {filename}...")
        run_sql_file(engine, filename)

    with engine.connect() as conn:
        rows = conn.execute(text(
            "SELECT check_name, status FROM dq_results ORDER BY check_name"
        )).all()

    print("\nData quality results")
    failed = False
    for check_name, status in rows:
        print(f"{status}: {check_name}")
        failed |= status != "PASS"

    if failed:
        raise SystemExit(1)
    print("\nELT pipeline completed successfully.")

if __name__ == "__main__":
    main()

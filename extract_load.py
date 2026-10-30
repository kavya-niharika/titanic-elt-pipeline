import os
from datetime import datetime, timezone
from uuid import uuid4

import pandas as pd
import seaborn as sns
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL


load_dotenv()


def get_engine():
    host = os.getenv("MYSQL_HOST", "localhost")
    port = int(os.getenv("MYSQL_PORT", "3306"))
    user = os.getenv("MYSQL_USER", "root")
    password = os.getenv("MYSQL_PASSWORD", "")
    database = os.getenv("MYSQL_DATABASE", "titanic_elt")

    if not password:
        raise ValueError(
            "MYSQL_PASSWORD is missing. Please check your .env file."
        )

    connection_url = URL.create(
        drivername="mysql+pymysql",
        username=user,
        password=password,
        host=host,
        port=port,
        database=database,
        query={"charset": "utf8mb4"},
    )

    return create_engine(connection_url)


def main():
    engine = get_engine()

    database = os.getenv("MYSQL_DATABASE", "titanic_elt")

    # Test MySQL connection
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))

    print("MySQL connection successful!")

    # Load Titanic dataset
    df = sns.load_dataset("titanic")

    # Convert category columns to object type
    for column in df.select_dtypes(include=["category"]).columns:
        df[column] = df[column].astype(object)

    # Add batch metadata
    batch_id = str(uuid4())

    df["batch_id"] = batch_id
    df["load_timestamp"] = datetime.now(timezone.utc).replace(tzinfo=None)

    # Load raw data into MySQL
    df.to_sql(
        name="raw_titanic",
        con=engine,
        if_exists="replace",
        index=False,
        chunksize=500,
        method="multi",
    )

    # Verify loaded records
    with engine.connect() as connection:
        count = connection.execute(
            text("SELECT COUNT(*) FROM raw_titanic")
        ).scalar()

    print(
        f"Loaded {count} raw rows into "
        f"{database}.raw_titanic (batch_id={batch_id})"
    )


if __name__ == "__main__":
    main()
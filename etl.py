"""
End-to-end ETL pipeline for the Zara sales dataset.
"""

import logging
from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine, text

# Configuration
RAW_DATA_PATH = Path("data/raw/zara.csv")
PROCESSED_DATA_PATH = Path("data/processed/zara_clean.csv")

DB_USER = "razikarahman"
DB_HOST = "localhost"
DB_PORT = 5432
DB_NAME = "zara_sales"
TABLE_NAME = "zara_products"

# Columns not needed for analysis
DROP_COLUMNS = ["url", "sku", "scraped_at", "description"]

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s | %(message)s"
)
log = logging.getLogger(__name__)


# Extract
def extract(path: Path = RAW_DATA_PATH) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(f"Raw data not found at {path}")

    df = pd.read_csv(path, sep=";")
    log.info("Extracted %d rows, %d columns from %s", len(df), len(df.columns), path)
    return df


# Transform
def transform(df: pd.DataFrame) -> pd.DataFrame:
    start_rows = len(df)

    # Drop unnecessary columns
    df = df.drop(columns=DROP_COLUMNS)
    log.info("Dropped unused columns: %s", ", ".join(DROP_COLUMNS))

    # Rename columns to snake case
    df.columns = df.columns.str.strip().str.lower().str.replace(" ", "_")

    # Drop missing values
    null_cols = [c for c in df.columns if df[c].isna().sum()]
    if null_cols:
        df = df.dropna(subset=null_cols)
        log.info("Dropped missing value rows from column(s): %s", ", ".join(null_cols))

    # Drop columns with single value
    single_value_cols = [c for c in df.columns if df[c].nunique() == 1]
    if single_value_cols:
        df = df.drop(columns=single_value_cols)
        log.info("Dropped columns with single value: %s", ", ".join(single_value_cols))

    # Rename columns
    if "terms" in df.columns:
        df = df.rename(columns={"terms": "category"})
        log.info("Renamed 'terms' -> 'category'")

    # Remove duplicates
    dups = df.duplicated().sum()
    if dups:
        df = df.drop_duplicates()
        log.info("Dropped %d duplicate row(s)", dups)

    # Revenue column
    df["product_revenue"] = df["price"] * df["sales_volume"]
    log.info("Derived 'product_revenue' = price * sales_volume")

    log.info("Transform complete: %d -> %d rows", start_rows, len(df))
    return df


# Validate data
def validate(df: pd.DataFrame) -> pd.DataFrame:
    checks = {
        "null values": df.isna().sum().sum(),
        "duplicate product_id": df["product_id"].duplicated().sum(),
        "non-positive price": (df["price"] <= 0).sum(),
        "non-positive sales_volume": (df["sales_volume"] <= 0).sum(),
        "revenue mismatch": (
            (df["product_revenue"] - df["price"] * df["sales_volume"]).abs() > 0.01
        ).sum(),
    }

    for check, count in checks.items():
        if count:
            log.warning("Validation — %s: %d", check, count)
        else:
            log.info("Validation — %s: pass", check)

    # handle duplicate
    if checks["duplicate product_id"]:
        raise ValueError(
            f"{checks['duplicate product_id']} duplicate product_id values; "
            "cannot set primary key. Please investigate."
        )

    return df


# Load - Create a SQLAlchemy engine for the local PostgreSQL instance, 
# them write into PostgresSQL
def get_engine():
    return create_engine(
        f"postgresql+psycopg2://{DB_USER}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )


def load(df: pd.DataFrame, table_name: str = TABLE_NAME) -> None:
    engine = get_engine()

    df.to_sql(table_name, engine, if_exists="replace", index=False)
    log.info("Loaded %d rows into %s.%s", len(df), DB_NAME, table_name)

def save_processed_copy(df: pd.DataFrame, path: Path = PROCESSED_DATA_PATH) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False)
    log.info("Saved cleaned copy to %s", path)

# Pipeline
def run_pipeline() -> pd.DataFrame:
    log.info("Starting Zara sales ETL pipeline")

    df = extract()
    df = transform(df)
    df = validate(df)
    save_processed_copy(df)
    load(df)

    log.info("Pipeline complete")
    return df


if __name__ == "__main__":
    run_pipeline()
# Zara Sales Analysis

A business analysis built on Zara product sales data through data preparation with the raw CSV and cleaning in Python/pandas, loading into PostgreSQL, analyzing with SQL, and visualizing in matplotlib.

## Overview

What are drivers for sales and revenue at Zara, and do they work the same way across menswear and womenswear?

This analysis found that there are several visible effects after segmenting by section at the aggregate level. Notable levers include promotion and product placement.

## Data Source

Source: Zara product sales dataset (Kaggle), scraped February 2024.
https://www.kaggle.com/datasets/xontoloyo/data-penjualan-zara/data
Raw size: 252 rows × 16 columns
Cleaned size: 251 rows × 10 columns
One row per product.

## Pipeline

1. **Extract**
   Read the raw CSV with a semicolon delimeter scraped from Zara's product pages.

2. **Transform**

- Dropped columns not relevant to the analysis
- Standardized column names to snake_case
- Dropped a row with missing product name
- Dropped three columns (product_category, brand, currency) that each holding a single value across all 251 rows, thus carrying no analytical significance
- Renamed columns (e.g. terms->category)
- Verified no duplicate rows
- Derived new product_revenue column as price × sales_volume

3. **Load**
   Written to a local PostgreSQL database (zara_sales, table zara_products) via SQLAlchemy.

## Key Insights

- Menswear generates 91.5% of revenue at nearly double the average price ($92 vs. $50)
- Womenswear products sell more when promoted; menswear products sell less.
- Front-of-store placement outperforms in both men and women sections. The weakest position differs: Aisle for women, End-cap for men.
- Kackets lead on revenue per product; shoes lead on units sold at a lower average price.
- Luxury products are the smallest prive tier by product count, yet have the highest total and average revenue. Mid-range products drive the most sales volume.
- Seasonality of products shows a notable effect only in womenswear. The share of products on promotion are identical between seasonal and non-seasonal products, ruling it out as the driver.

## Tools Used

Python (pandas, SQLAlchemy, matplotlib, seaborn), PostgreSQL, SQL (CTEs, window functions, aggregate filters), Jupyter

## How to Run

\`\`\`bash
brew install postgresql@18
brew services start postgresql@18
createdb zara_sales

**Setup**
\`\`\`
git clone https://github.com/razikarahman/zara-sales-analysis.git
cd zara-sales-analysis
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

Update DB_USER in etl.py to your PostgreSQL username (find it with whoami).

**Run the pipeline**
\`\`\`
python etl.py

**Run the SQL analysis**
\`\`\`
psql zara_sales -f sql/analysis.sql

**Generate some visualizations**
\`\`\`
jupyter notebook notebooks/zara_visualizations.ipynb

-- Zara Sales Analysis
-- What does overall performance look like?
SELECT COUNT(*) AS total_products,
    SUM(sales_volume) AS total_sales,
    ROUND(SUM(product_revenue)::numeric, 2) AS total_revenue,
    ROUND(AVG(price)::numeric, 2) AS avg_price,
    ROUND(AVG(sales_volume)::numeric, 1) AS avg_sales
FROM zara_products;
-- Q1. Does a particular section drive more revenue? Is this by volume or price?
SELECT section,
    COUNT(*) AS product_count,
    ROUND(AVG(sales_volume)::numeric, 1) AS avg_sales,
    ROUND(AVG(product_revenue)::numeric, 2) AS avg_revenue,
    ROUND(AVG(price)::numeric, 2) AS avg_price,
    ROUND(
        100.0 * SUM(product_revenue)::numeric / SUM(SUM(product_revenue)::numeric) OVER (),
        2
    ) AS pct_total_revenue
FROM zara_products
GROUP BY section
ORDER BY avg_revenue DESC;
-- Q2. Do products sell more when on promotion? 
SELECT promotion,
    COUNT(*) AS product_count,
    ROUND(AVG(sales_volume)::numeric, 1) AS avg_sales,
    ROUND(AVG(price)::numeric, 2) AS avg_price
FROM zara_products
GROUP BY promotion;
-- Q3. Does promotion sell better in menswear or womenswear?
SELECT section,
    promotion,
    COUNT(*) AS product_count,
    ROUND(AVG(price)::numeric, 2) AS avg_price,
    ROUND(AVG(sales_volume)::numeric, 1) AS avg_sales
FROM zara_products
GROUP BY section,
    promotion
ORDER BY section,
    promotion;
-- Q4. Does product placement in the store affect how much a product sells? Does this differ by section?
SELECT product_position,
    section,
    COUNT(*) AS product_count,
    ROUND(AVG(sales_volume)::numeric, 1) AS avg_sales,
    ROUND(AVG(price)::numeric, 2) AS avg_price,
    ROUND(SUM(product_revenue)::numeric, 2) AS total_revenue,
    ROUND(AVG(product_revenue)::numeric, 2) AS avg_revenue_per_product
FROM zara_products
GROUP BY product_position,
    section
ORDER BY product_position,
    section;
-- Q5. What are the best sellers in each section in terms of sales volume?
WITH ranked AS (
    SELECT name,
        category,
        section,
        price,
        sales_volume,
        RANK() OVER (
            PARTITION BY section
            ORDER BY sales_volume DESC
        ) AS sales_rank
    FROM zara_products
)
SELECT section,
    sales_rank,
    category,
    name,
    price,
    sales_volume
FROM ranked
WHERE sales_rank <= 6
ORDER BY section,
    sales_rank;
-- Q6. Which price tier generates the most revenue?
-- Determine product tiers
SELECT MIN(price),
    PERCENTILE_CONT(0.25) WITHIN GROUP (
        ORDER BY price
    ),
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY price
    ),
    AVG(price),
    PERCENTILE_CONT(0.75) WITHIN GROUP (
        ORDER BY price
    ),
    MAX(price)
FROM zara_products;
-- Analyze tiers
SELECT CASE
        WHEN price < 50 THEN 'Budget (<$50)'
        WHEN price < 80 THEN 'Mid-Range ($51-$79)'
        WHEN price < 110 THEN 'Premium ($80-$109)'
        ELSE 'Luxury ($110+)'
    END AS price_band,
    COUNT(*) AS product_count,
    SUM(sales_volume) AS total_sales,
    ROUND(SUM(product_revenue)::numeric, 2) AS total_revenue,
    ROUND(AVG(sales_volume)::numeric, 1) AS avg_sales,
    ROUND(AVG(product_revenue)::numeric, 1) AS avg_product_revenue
FROM zara_products
GROUP BY price_band
ORDER BY total_revenue DESC;
-- Q7. Do seasonal products perform better than non-seasonal? 
SELECT seasonal,
    COUNT(*) AS product_count,
    ROUND(AVG(price)::numeric, 2) AS avg_price,
    ROUND(AVG(sales_volume)::numeric, 1) AS avg_sales,
    ROUND(AVG(product_revenue)::numeric, 2) AS avg_revenue,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE promotion = 'Yes'
        ) / COUNT(*),
        1
    ) AS pct_on_promotion
FROM zara_products
GROUP BY seasonal;
-- Does this differ by section?
SELECT seasonal,
    section,
    COUNT(*) AS product_count,
    ROUND(AVG(price)::numeric, 2) AS avg_price,
    ROUND(AVG(sales_volume)::numeric, 1) AS avg_sales,
    ROUND(AVG(product_revenue)::numeric, 2) AS avg_revenue,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE promotion = 'Yes'
        ) / COUNT(*),
        1
    ) AS pct_on_promotion
FROM zara_products
GROUP BY seasonal,
    section
ORDER BY seasonal,
    section;
-- Q8. Which product categories produce the greatest average revenue?
SELECT category,
    COUNT(*) AS product_count,
    ROUND(AVG(sales_volume)::numeric, 2) AS avg_sales,
    ROUND(AVG(product_revenue)::numeric, 2) AS avg_revenue,
    ROUND(AVG(price)::numeric, 2) AS avg_price
FROM zara_products
GROUP BY category
ORDER BY avg_revenue DESC;
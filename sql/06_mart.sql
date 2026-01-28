CREATE SCHEMA IF NOT EXISTS mart;

CREATE OR REPLACE VIEW mart.mart_repeat_gmv_by_category_month AS
WITH base AS (
  SELECT
    date_trunc('month', r.purchase_ts)::date AS month_start,
    r.order_id,
    r.customer_unique_id,
    r.order_rank,
    og.order_gmv
  FROM core.vw_customer_order_rank r
  JOIN core.vw_order_gmv og
    ON og.order_id = r.order_id
)
SELECT
  month_start,

  SUM(order_gmv) AS total_gmv,
  SUM(CASE WHEN order_rank = 1 THEN order_gmv ELSE 0 END) AS new_gmv,
  SUM(CASE WHEN order_rank >= 2 THEN order_gmv ELSE 0 END) AS repeat_gmv,

  (SUM(CASE WHEN order_rank >= 2 THEN order_gmv ELSE 0 END)
    / NULLIF(SUM(order_gmv), 0))::numeric AS repeat_share,

  COUNT(DISTINCT order_id) AS orders_total,
  COUNT(DISTINCT CASE WHEN order_rank >= 2 THEN order_id END) AS orders_repeat,

  COUNT(DISTINCT CASE WHEN order_rank = 1 THEN customer_unique_id END) AS new_customers,
  COUNT(DISTINCT CASE WHEN order_rank >= 2 THEN customer_unique_id END) AS returning_customers

FROM base
GROUP BY month_start;



CREATE OR REPLACE VIEW mart.mart_repeat_gmv_by_state_month AS
WITH base AS (
  SELECT
    date_trunc('month', r.purchase_ts)::date AS month_start,
    r.order_id,
    r.customer_unique_id,
    r.order_rank,
    og.order_gmv,
    dc.custome_state
  FROM core.vw_customer_order_rank r
  JOIN core.vw_order_gmv og
    ON og.order_id = r.order_id
  JOIN core.fact_orders fo
    ON fo.order_id = r.order_id
  LEFT JOIN core.dim_customer dc
    ON dc.customer_id = fo.customer_id
)
SELECT
  month_start,
  COALESCE(custome_state, 'UNKNOWN') AS customer_state,

  SUM(order_gmv) AS total_gmv,
  SUM(CASE WHEN order_rank >= 2 THEN order_gmv ELSE 0 END) AS repeat_gmv,
  (SUM(CASE WHEN order_rank >= 2 THEN order_gmv ELSE 0 END)
    / NULLIF(SUM(order_gmv),0))::numeric AS repeat_share,

  COUNT(DISTINCT order_id) AS orders_total,
  COUNT(DISTINCT CASE WHEN order_rank >= 2 THEN order_id END) AS orders_repeat
FROM base
GROUP BY month_start, COALESCE(custome_state, 'UNKNOWN');




CREATE OR REPLACE VIEW mart.mart_repeat_gmv_by_category_month AS
WITH base AS (
  SELECT
    date_trunc('month', r.purchase_ts)::date AS month_start,
    r.order_id,
    r.order_rank,
    fi.product_id,
    fi.item_gmv
  FROM core.vw_customer_order_rank r
  JOIN core.fact_order_items fi
    ON fi.order_id = r.order_id
)
SELECT
  b.month_start,
  COALESCE(dp.product_category_name_en, 'unknown') AS category,

  SUM(b.item_gmv) AS total_gmv,
  SUM(CASE WHEN b.order_rank >= 2 THEN b.item_gmv ELSE 0 END) AS repeat_gmv,
  (SUM(CASE WHEN b.order_rank >= 2 THEN b.item_gmv ELSE 0 END)
    / NULLIF(SUM(b.item_gmv),0))::numeric AS repeat_share,

  COUNT(DISTINCT b.order_id) AS orders_total,
  COUNT(DISTINCT CASE WHEN b.order_rank >= 2 THEN b.order_id END) AS orders_repeat
FROM base b
LEFT JOIN core.dim_product dp
  ON dp.product_id = b.product_id
GROUP BY b.month_start, COALESCE(dp.product_category_name_en, 'unknown');



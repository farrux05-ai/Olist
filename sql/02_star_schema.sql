"""3) Har jadvalning “grain”ini yozib qo‘y (shart!)
dim_customer grain

1 row = 1 customer_id (va ichida customer_unique_id bor)

dim_product grain

1 row = 1 product_id

dim_seller grain

1 row = 1 seller_id

dim_date grain

1 row = 1 day

fact_orders grain

1 row = 1 order_id

fact_order_items grain

1 row = 1 (order_id, order_item_id)

Shuni yozib olsang, keyin KPIlar adashmaydi."""

-- CREATING SCHEMA
CREATE SCHEMA IF NOT EXISTS core;

-- CREATING VIEW
CREATE OR REPLACE VIEW core.dim_customer AS
select
    trim(customer_id) as customer_id,
    COALESCE(NULLIF(trim(customer_unique_id),''),'UNKNOWN') AS customer_unique_id,
    --location
    NULLIF(TRIM(customer_city),'') AS customer_city,
    NULLIF(TRIM(customer_state),'') AS custome_state,
    NULLIF(TRIM(customer_zip_code_prefix), '') AS customer_zip_code_prefix
FROM customers
WHERE nullif(TRIM(customer_id),'') is not null;
--check

SELECT
  COUNT(*) AS rows,
  COUNT(DISTINCT customer_id) AS distinct_customer_id
FROM core.dim_customer;

-- unknown
select 
count(*) as all_unknowns
from core.dim_customer
where customer_unique_id = 'UNKNOWN';
--STATE DISTURBTION
SELECT custome_state, count(*) as jami
from core.dim_customer
group by custome_state
order by jami desc;

--product dimention 1 row = 1 product_id
CREATE OR REPLACE VIEW core.dim_product AS
SELECT
  p.product_id,
  NULLIF(TRIM(p.product_category_name), '') AS product_category_name_pt,

  -- agar translation topilmasa, pt nomni o‘zini qo‘yamiz
  COALESCE(
    NULLIF(TRIM(t.product_category_name_english), ''),
    NULLIF(TRIM(p.product_category_name), ''),
    'unknown'
  ) AS product_category_name_en

FROM products p
LEFT JOIN product_category_translation t
  ON TRIM(p.product_category_name) = TRIM(t.product_category_name)
WHERE NULLIF(TRIM(p.product_id), '') IS NOT NULL;

--dim_seller grain
CREATE or REPLACE VIEW core.dim_seller as 
select  
    TRIM(seller_id) AS seller_id,
    NULLIF(trim(seller_zip_code_prefix),'') as seller_zip_code_prefix,
    COALESCE(NULLIF(trim(seller_city),''),'UNKNOWN') as seller_city,
    COALESCE(NULLIF(trim(seller_state),''),'UNKNOWN') as seller_state
from sellers
where NULLIF(trim(seller_id),'') is not null;
--test
select 
    count(*) as jami,
    count(distinct seller_id) as seller_unique_id
from core.dim_seller;

--state va city kop null emasmi
select 
    seller_city,
    count(*) as jami
from core.dim_seller
group by seller_city
order by jami desc;

--dim_date
CREATE OR REPLACE VIEW core.dim_date as 
WITH bounds as(
    select 
        min(order_purchase_timestamp) as min_d,
        max(order_purchase_timestamp) as max_d
    from orders
),
calendar as (
    select
        generate_series(min_d, max_d, interval'1 day')::date as date_day
        from bounds
)
select  
    date_day,
    EXTRACT(YEAR FROM date_day)::INT as year,
    EXTRACT(MONTH FROM date_day)::INT  as month,
    DATE_TRUNC('month', date_day)::date as mont_start,
    EXTRACT(QUARTER FROM date_day)::INT as quarter,
    EXTRACT(DOW FROM date_day)::int as week_num,
    to_char(date_day, 'Dy') as name_week,
    to_char(date_day, 'YYYY-MM') as year_month
from calendar
    

CREATE SCHEMA IF NOT EXISTS core;


-- Fact: 1 row = 1 order_id
CREATE OR REPLACE VIEW core.fact_orders AS
SELECT
  o.order_id,
  o.customer_id,
  dc.customer_unique_id,

  o.order_status,

  -- vaqtlar (trend va lifecycle uchun)
  o.order_purchase_timestamp AS purchase_ts,
  o.order_approved_at        AS approved_ts,
  o.order_delivered_carrier_date  AS delivered_carrier_ts,
  o.order_delivered_customer_date AS delivered_customer_ts,
  o.order_estimated_delivery_date AS estimated_delivery_ts,

  -- delivery metrikalari (order-levelda bo‘lishi kerak)
  CASE
    WHEN o.order_delivered_customer_date IS NOT NULL
     AND o.order_purchase_timestamp IS NOT NULL
    THEN (o.order_delivered_customer_date::date - o.order_purchase_timestamp::date)
    ELSE NULL
  END AS delivery_days,

  CASE
    WHEN o.order_delivered_customer_date IS NOT NULL
     AND o.order_estimated_delivery_date IS NOT NULL
     AND o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date
    THEN 1 ELSE 0
  END AS is_late

FROM orders o
LEFT JOIN core.dim_customer dc
  ON dc.customer_id = o.customer_id
WHERE NULLIF(TRIM(o.order_id), '') IS NOT NULL;

--fact order items
create or REPLACE view core.fact_order_items AS
select
    trim(oi.order_id) as order_id,
    oi.order_item_id,

    trim(oi.product_id) as product_id ,
    trim(oi.seller_id) as seller_id,
    oi.shipping_limit_date as date,

    COALESCE(oi.price, 0)::NUMERIC as price,
    COALESCE(oi.freight_value, 0)::NUMERIC as freight_value,

    (COALESCE(oi.price, 0) +  COALESCE(oi.freight_value, 0))::NUMERIC AS item_gmv
FROM order_items oi
where NULLIF(trim(oi.order_id),'') is not null and oi.order_item_id is not null;
SELECT
  COUNT(*) AS rows,
  COUNT(DISTINCT (order_id, order_item_id)) AS distinct_rows
FROM core.fact_order_items;

SELECT COUNT(*) AS negative_values
FROM core.fact_order_items
WHERE price < 0 OR freight_value < 0;

-- product dimga ulanmay qolgan itemlar
SELECT COUNT(*) AS missing_products
FROM core.fact_order_items fi
LEFT JOIN core.dim_product dp ON dp.product_id = fi.product_id
WHERE fi.product_id IS NOT NULL AND dp.product_id IS NULL;

-- seller dimga ulanmay qolgan itemlar
SELECT COUNT(*) AS missing_sellers
FROM core.fact_order_items fi
LEFT JOIN core.dim_seller ds ON ds.seller_id = fi.seller_id
WHERE fi.seller_id IS NOT NULL AND ds.seller_id IS NULL;

CREATE OR REPLACE VIEW core.vw_order_gmv AS
SELECT
  TRIM(order_id) AS order_id,
  SUM(COALESCE(item_gmv,0))::numeric AS order_gmv
FROM core.fact_order_items
WHERE NULLIF(TRIM(order_id),'') IS NOT NULL
GROUP BY TRIM(order_id);




SELECT  
    ork.order_id,
    ork.customer_unique_id,
    ork.purchase_ts,
    SUM(og.order_gmv) OVER(
        PARTITION BY ork.customer_unique_id
        ORDER BY ork.purchase_ts,ork.order_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_gmv
    from core.order_rank ork
    join core.vw_order_gmv og
    on ork.order_id = og.order_id;



CREATE OR REPLACE VIEW core.vw_customer_order_rank AS
SELECT
  fo.order_id,
  fo.customer_unique_id,
  fo.purchase_ts,
  ROW_NUMBER() OVER (
    PARTITION BY fo.customer_unique_id
    ORDER BY fo.purchase_ts, fo.order_id
  ) AS order_rank
FROM core.fact_orders fo
WHERE fo.customer_unique_id IS NOT NULL
  AND fo.order_status = 'delivered'
  AND fo.purchase_ts IS NOT NULL;


CREATE or REPLACE VIEW core.running_order_count as 
select 
    fo.order_id,
    fo.customer_unique_id,
    fo.purchase_ts,
    COUNT(*) OVER (
    PARTITION BY customer_unique_id
    ) AS count_row
from core.fact_orders fo
where fo.customer_unique_id is not null and fo.order_status = 'delivered';

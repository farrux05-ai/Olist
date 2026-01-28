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

--state va city kop null emasmi
select 
    seller_city,
    count(*) as jami
from core.dim_seller
group by seller_city
order by jami desc;

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
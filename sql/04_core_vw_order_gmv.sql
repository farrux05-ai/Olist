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
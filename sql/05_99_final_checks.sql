SELECT
  month_start,
  total_gmv,
  new_gmv + repeat_gmv AS sum_parts,
  (total_gmv - (new_gmv + repeat_gmv)) AS diff
FROM mart.mart_monthly_repeat_gmv
ORDER BY month_start;


SELECT * 
FROM mart.mart_monthly_repeat_gmv
ORDER BY month_start
LIMIT 24;

SELECT
  customer_state,
  COUNT(*) as total_state
from mart.mart_repeat_gmv_by_state_month
group by customer_state;


SELECT *
FROM core.vw_order_gmv
ORDER BY order_gmv DESC
LIMIT 10;
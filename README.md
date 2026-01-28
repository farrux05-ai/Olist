# Brazilian E-Commerce (Olist) — Repeat GMV Growth Analytics

## Overview
This project analyzes **Repeat GMV (Gross Merchandise Value)** growth using the Brazilian Olist e-commerce dataset.  
The goal is to understand **how much revenue comes from returning customers** and identify the main **drivers (category, state)** behind repeat purchases.

## Business Goal (North Star)
**North Star Metric:** Repeat GMV  
**Supporting Metric:** Repeat Share = Repeat GMV / Total GMV

The key question:
> “What drives Repeat GMV and how can we increase the share of revenue coming from returning customers?”

## Tech Stack
- **PostgreSQL**: data ingestion, cleaning, modeling, marts
- **Power BI**: dashboarding & insights

## Data Pipeline
1. **Raw -> Staging**
   - Loaded CSV files into staging tables
   - Type casting (timestamps, numeric values)
   - Basic cleaning (trimming, null handling)

2. **Core Model (Star Schema)**
   - Built a star schema to ensure correct aggregations and fast BI performance

   **Facts**
   - `fact_orders` (1 row = 1 order)
   - `fact_order_items` (1 row = 1 order item)

   **Dimensions**
   - `dim_customer` (includes `customer_unique_id` for repeat tracking)
   - `dim_product` (includes category + English translation)
   - `dim_seller`
   - `dim_date` + `dim_month` (monthly slicing for marts)

3. **Marts (BI-ready tables)**
   - `mart_monthly_repeat_gmv` (monthly North Star trend)
   - `mart_repeat_gmv_by_state_month`
   - `mart_repeat_gmv_by_category_month`

## Metric Definitions
- **GMV** = `price + freight_value`
- **Repeat Order** = customer’s order_rank >= 2 (based on `customer_unique_id`)
- **Repeat GMV** = GMV from repeat orders only
- **Repeat Share** = Repeat GMV / Total GMV

## Dashboard
Power BI dashboard includes:
- Repeat GMV trend over time
- Repeat share trend
- New vs Repeat GMV comparison
- Top repeat categories
- Top repeat states

## Key Findings
1. **Repeat share peaks at ~4% (Feb 2018)** — this is the current best benchmark month.
2. Repeat GMV is concentrated in a few states: **SP, RJ, MG, RS, PR**.
3. Repeat GMV is driven by a small set of categories:
   - **bed_bath_table (~5% repeat share)**
   - **computers_accessories (~4%)**
   - **furniture_decor (~4%)**
   - **sports_leisure (~4%)**
   - **health_beauty (~2% repeat share, underperforming)**

## Recommendations
1. **Increase repeat share above the 4% benchmark**
   - Launch 7/14/30-day post-purchase triggers (coupon / free shipping threshold / personalized recommendations)
   - Track: repeat_share, repeat_gmv, returning_customers

2. **Double down on top repeat categories**
   - `bed_bath_table`: bundles + returning-customer incentives
   - Track: category repeat_share, repeat orders

3. **Cross-sell strategy for computers & furniture**
   - Recommend accessories/add-ons to encourage a second purchase
   - Track: 2nd purchase rate, repeat GMV by category

4. **Fix low-repeat segment (health_beauty) with A/B tests**
   - Test free shipping threshold vs. 2nd purchase coupon
   - Track: health_beauty repeat_share and incremental repeat GMV

5. **Geo-prioritize retention campaigns**
   - Focus on SP/RJ/MG/RS/PR where repeat GMV is highest
   - Track: repeat_gmv by state and repeat orders

## Project Structure
- `sql/01_staging.sql` — staging tables & cleaning
- `sql/02_star_schema.sql` — core facts & dimensions
- `sql/mart.sql` — marts for BI
- `sql/99_final_checks.sql` — validation tests
- `powerbi/olist.pbix` — dashboard file
- `powerbi/screenshots/` — dashboard images

## Notes / Limitations
- Repeat customer identification uses `customer_unique_id` (recommended for Olist data).
- Analysis is based on delivered orders (if filtered in the model).
- Some categories may be missing/unknown due to incomplete product labels.

## Author
Created by: **<YOUR NAME>**  
LinkedIn: <YOUR LINK>  

DROP TABLE IF exists stg_olist_orders;
CREATE TABLE stg_olist_orders(
    order_id	TEXT,
    customer_id	TEXT,
    order_status TEXT,	
    order_purchase_timestamp TEXT,	
    order_approved_at	TEXT,
    order_delivered_carrier_date	TEXT,
    order_delivered_customer_date	TEXT,
    order_estimated_delivery_date TEXT
);
--IMPORT
\copy stg_olist_orders FROM 'C:\Users\U S E R\Desktop\portifolio\Brazilian Olist\olist_orders_dataset.csv' WITH CSV HEADER;

-- 2) CORE / CLEAN TABLE (typed)
DROP TABLE IF EXISTS orders;
CREATE TABLE orders(
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    order_status TEXT NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP NULL,
    order_delivered_carrier_date TIMESTAMP NULL,
    order_delivered_customer_date TIMESTAMP NULL,
    order_estimated_delivery_date TIMESTAMP NULL
);

-- 3) INSERT + CLEAN + CAST
INSERT INTO orders(
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)
SELECT
    TRIM(order_id) AS order_id,
    COALESCE(NULLIF(TRIM(customer_id), ''), 'UNKNOWN') AS customer_id,
    COALESCE(NULLIF(TRIM(order_status), ''), 'unknown') AS order_status,

    NULLIF(TRIM(order_purchase_timestamp), '')::timestamp AS order_purchase_timestamp,
    NULLIF(TRIM(order_approved_at), '')::timestamp AS order_approved_at,
    NULLIF(TRIM(order_delivered_carrier_date), '')::timestamp AS order_delivered_carrier_date,
    NULLIF(TRIM(order_delivered_customer_date), '')::timestamp AS order_delivered_customer_date,
    NULLIF(TRIM(order_estimated_delivery_date), '')::timestamp AS order_estimated_delivery_date
FROM stg_olist_orders
WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
  AND NULLIF(TRIM(order_purchase_timestamp), '') IS NOT NULL;

DROP TABLE IF exists stg_olist_order_items;
CREATE TABLE stg_olist_order_items(
    order_id TEXT,
    order_item_id TEXT,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TEXT,
    price TEXT,
    freight_value TEXT
);
--IMPORT
\copy stg_olist_order_items FROM 'C:\Users\U S E R\Desktop\portifolio\Brazilian Olist\olist_order_items_dataset.csv' WITH CSV HEADER;

CREATE TABLE order_items(
    order_id TEXT,
    order_item_id INT,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC
);

insert into order_items(order_id,order_item_id, product_id, seller_id,shipping_limit_date, price,freight_value)
select 
    trim(order_id) as order_id,
    NULLIF(trim(order_item_id), '')::INT as order_item_id,
    COALESCE(NULLIF(trim(product_id),''), 'UNKNOWN') as product_id,
    COALESCE(NULLIF(trim(seller_id),''), 'UNKNOWN') as seller_id,
    NULLIF(trim(shipping_limit_date),'')::timestamp,
    NULLIF(replace(trim(price),',',''), '')::NUMERIC as price,
    NULLIF(replace(trim(freight_value),',',''), '')::NUMERIC as freight_value
from stg_olist_order_items
where NULLIF(TRIM(order_id), '') IS NOT NULL;

--CUSTOMERS
DROP TABLE IF EXISTS stg_olist_customers;
CREATE TABLE stg_olist_customers(
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

\copy stg_olist_customers FROM 'C:\Users\U S E R\Desktop\portifolio\Brazilian Olist\olist_customers_dataset.csv' WITH CSV HEADER;

DROP TABLE IF EXISTS customers;
CREATE TABLE customers(
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

INSERT INTO customers(
    customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state
)
SELECT
    TRIM(customer_id) AS customer_id,
    COALESCE(NULLIF(TRIM(customer_unique_id), ''), 'UNKNOWN') AS customer_unique_id,
    NULLIF(TRIM(customer_zip_code_prefix), '') AS customer_zip_code_prefix,
    NULLIF(TRIM(customer_city), '') AS customer_city,
    NULLIF(TRIM(customer_state), '') AS customer_state
FROM stg_olist_customers
WHERE NULLIF(TRIM(customer_id), '') IS NOT NULL;

--PRODUCTS
DROP TABLE IF EXISTS stg_olist_products;
CREATE TABLE stg_olist_products(
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght TEXT,
    product_description_lenght TEXT,
    product_photos_qty TEXT,
    product_weight_g TEXT,
    product_length_cm TEXT,
    product_height_cm TEXT,
    product_width_cm TEXT
);

\copy stg_olist_products FROM 'C:\Users\U S E R\Desktop\portifolio\Brazilian Olist\olist_products_dataset.csv' WITH CSV HEADER;

DROP TABLE IF EXISTS products;
CREATE TABLE products(
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT,
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

INSERT INTO products(
    product_id, product_category_name,
    product_name_length, product_description_length, product_photos_qty,
    product_weight_g, product_length_cm, product_height_cm, product_width_cm
)
SELECT
    TRIM(product_id) AS product_id,
    NULLIF(TRIM(product_category_name), '') AS product_category_name,

    NULLIF(TRIM(product_name_lenght), '')::INT AS product_name_length,
    NULLIF(TRIM(product_description_lenght), '')::INT AS product_description_length,
    NULLIF(TRIM(product_photos_qty), '')::INT AS product_photos_qty,

    NULLIF(REPLACE(TRIM(product_weight_g), ',', ''), '')::NUMERIC AS product_weight_g,
    NULLIF(REPLACE(TRIM(product_length_cm), ',', ''), '')::NUMERIC AS product_length_cm,
    NULLIF(REPLACE(TRIM(product_height_cm), ',', ''), '')::NUMERIC AS product_height_cm,
    NULLIF(REPLACE(TRIM(product_width_cm), ',', ''), '')::NUMERIC AS product_width_cm
FROM stg_olist_products
WHERE NULLIF(TRIM(product_id), '') IS NOT NULL;

--CATEGORY TRANSLATION
DROP TABLE IF EXISTS stg_product_category_translation;
CREATE TABLE stg_product_category_translation(
    product_category_name TEXT,
    product_category_name_english TEXT
);

\copy stg_product_category_translation FROM 'C:\Users\U S E R\Desktop\portifolio\Brazilian Olist\product_category_name_translation.csv' WITH CSV HEADER;

DROP TABLE IF EXISTS product_category_translation;
CREATE TABLE product_category_translation(
    product_category_name TEXT PRIMARY KEY,
    product_category_name_english TEXT
);

INSERT INTO product_category_translation(product_category_name, product_category_name_english)
SELECT
    TRIM(product_category_name),
    NULLIF(TRIM(product_category_name_english), '')
FROM stg_product_category_translation
WHERE NULLIF(TRIM(product_category_name), '') IS NOT NULL;

--PAYMENTS
DROP TABLE IF EXISTS stg_olist_order_payments;
CREATE TABLE stg_olist_order_payments(
    order_id TEXT,
    payment_sequential TEXT,
    payment_type TEXT,
    payment_installments TEXT,
    payment_value TEXT
);

\copy stg_olist_order_payments FROM 'C:\Users\U S E R\Desktop\portifolio\Brazilian Olist\olist_order_payments_dataset.csv' WITH CSV HEADER;

DROP TABLE IF EXISTS order_payments;
CREATE TABLE order_payments(
    order_id TEXT NOT NULL,
    payment_sequential INT,
    payment_type TEXT,
    payment_installments INT,
    payment_value NUMERIC
);

INSERT INTO order_payments(
    order_id, payment_sequential, payment_type, payment_installments, payment_value
)
SELECT
    TRIM(order_id) AS order_id,
    NULLIF(TRIM(payment_sequential), '')::INT AS payment_sequential,
    NULLIF(TRIM(payment_type), '') AS payment_type,
    NULLIF(TRIM(payment_installments), '')::INT AS payment_installments,
    NULLIF(REPLACE(TRIM(payment_value), ',', ''), '')::NUMERIC AS payment_value
FROM stg_olist_order_payments
WHERE NULLIF(TRIM(order_id), '') IS NOT NULL;

--REVIEWS
DROP TABLE IF EXISTS stg_olist_order_reviews;
CREATE TABLE stg_olist_order_reviews(
    review_id TEXT,
    order_id TEXT,
    review_score TEXT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);

\copy stg_olist_order_reviews FROM 'C:\Users\U S E R\Desktop\portifolio\Brazilian Olist\olist_order_reviews_dataset.csv' WITH CSV HEADER  ENCODING 'WIN1251';
\copy stg_olist_order_reviews FROM 'C:\Users\U S E R\Desktop\portifolio\Brazilian Olist\olist_order_reviews_dataset.csv' WITH CSV HEADER ENCODING 'LATIN1';



DROP TABLE IF EXISTS order_reviews;
CREATE TABLE order_reviews(
    review_id TEXT,
    order_id TEXT NOT NULL,
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

INSERT INTO order_reviews(
    review_id, order_id, review_score,
    review_comment_title, review_comment_message,
    review_creation_date, review_answer_timestamp
)
SELECT
    TRIM(review_id) AS review_id,
    TRIM(order_id) AS order_id,
    NULLIF(TRIM(review_score), '')::INT AS review_score,
    NULLIF(TRIM(review_comment_title), '') AS review_comment_title,
    NULLIF(TRIM(review_comment_message), '') AS review_comment_message,
    NULLIF(TRIM(review_creation_date), '')::timestamp AS review_creation_date,
    NULLIF(TRIM(review_answer_timestamp), '')::timestamp AS review_answer_timestamp
FROM stg_olist_order_reviews
WHERE NULLIF(TRIM(review_id), '') IS NOT NULL
  AND NULLIF(TRIM(order_id), '') IS NOT NULL;

--SELLERS
DROP TABLE IF EXISTS stg_olist_sellers;
CREATE TABLE stg_olist_sellers(
    seller_id TEXT,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

\copy stg_olist_sellers FROM 'C:\Users\U S E R\Desktop\portifolio\Brazilian Olist\olist_sellers_dataset.csv' WITH CSV HEADER;

DROP TABLE IF EXISTS sellers;
CREATE TABLE sellers(
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

INSERT INTO sellers(
    seller_id, seller_zip_code_prefix, seller_city, seller_state
)
SELECT
    TRIM(seller_id) AS seller_id,
    NULLIF(TRIM(seller_zip_code_prefix), '') AS seller_zip_code_prefix,
    NULLIF(TRIM(seller_city), '') AS seller_city,
    NULLIF(TRIM(seller_state), '') AS seller_state
FROM stg_olist_sellers
WHERE NULLIF(TRIM(seller_id), '') IS NOT NULL;


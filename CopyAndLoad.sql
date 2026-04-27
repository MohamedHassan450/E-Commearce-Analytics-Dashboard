CREATE TABLE E_Base (
    event_id VARCHAR(20),
    event_type VARCHAR(50),
    event_date TIMESTAMP,
    customer_id VARCHAR(20),
    product_id VARCHAR(20),
    country VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    region VARCHAR(50),
    channel VARCHAR(50),
    payment_method VARCHAR(50),
    currency VARCHAR(10),
    quantity INT,
    unit_price_local NUMERIC(12,2),
    discount_code VARCHAR(50),
    discount_local NUMERIC(12,2),
    tax_local NUMERIC(12,2),
    net_revenue_local NUMERIC(12,2),
    fx_rate_to_usd NUMERIC(12,6),
    net_revenue_usd NUMERIC(12,2),
    is_refunded BOOLEAN,
    refund_datetime TIMESTAMP,
    refund_reason TEXT
);

\copy E_Base From 'C:\Users\moham\OneDrive\Documents\Database\Used\Projects\E-Commerce\E_Base.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

UPDATE E_Base
SET region = CASE
    WHEN country IN ('United States', 'Canada') THEN 'North America'
    WHEN country IN ('United Kingdom', 'Germany', 'France', 'Netherlands', 'Spain') THEN 'EU'
    WHEN country IN ('Australia') THEN 'APAC'
    WHEN country IN ('Philippines') THEN 'APAC'
    WHEN country IN ('Brazil') THEN 'LATAM'
    ELSE 'Other'
END;



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE E_Products (
    product_id VARCHAR(20),
    product_name VARCHAR(200),
    category VARCHAR(100),
    is_subscription BOOLEAN,
    billing_cycle VARCHAR(50),
    base_price NUMERIC(12,2),
    first_release DATE,
    vendor VARCHAR(100),
    resale_model VARCHAR(50),
    brand_safe_name VARCHAR,
    product_name_orig VARCHAR,
    base_price_usd NUMERIC(12,2),
    base_key VARCHAR(100),
    product_version VARCHAR(50)
);

\copy E_Products From 'C:\Users\moham\OneDrive\Documents\Database\Used\Projects\E-Commerce\E_Product.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE E_Customers (
    customer_id VARCHAR(20),
    signup_date TIMESTAMP,
    region VARCHAR(20),
    currency_preference VARCHAR(10),
    segment VARCHAR(50),
    acquisition_channel VARCHAR(100),
    age_band VARCHAR(50),
    country VARCHAR(100),
    country_latitude DECIMAL(9,6),
    country_longitude DECIMAL(9,6)
);

\copy E_Customers From 'C:\Users\moham\OneDrive\Documents\Database\Used\Projects\E-Commerce\E_Customers.csv' With(FORMAT csv,HEADER true,DELIMITER ',',ENCODING 'UTF8');
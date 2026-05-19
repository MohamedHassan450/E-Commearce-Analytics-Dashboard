--Qiuck Insights--

--Number of Orders
SELECT
Count(*)
From e_base as eb;

--Ranking countries by number of orders
SELECT
    eb.country,
    Sum(eb.net_revenue_usd),
    Count(eb.country) as total_orders
From e_base as eb
WHERE eb.country IS NOT NULL
GROUP BY eb.country
ORDER BY Count(eb.country) DESC;

--Ranking regions by number of orders 
SELECT
COALESCE(eb.region,'Other') as region,
Count(*) as total_orders
FROM e_base as eb 
GROUP BY COALESCE(eb.region,'Other')
ORDER BY total_orders DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--How many orders were placed, percentage of total orders and total revenue does each payment method represent?
With base AS
(
    SELECT 
        b.payment_method,
        count(*) as count_payment_method,
        Sum(b.net_revenue_usd) as Revnue
    From e_base as b
    WHERE b.payment_method IS NOT NULL
    GROUP BY b.payment_method
),

Total_Revnue AS 
(
    SELECT
        Sum(net_revenue_usd) as total
    FROM e_base
),

Total_Ordars AS 
(
    SELECT
    Count(event_id) as total
    From e_base
)

SELECT
    bb.payment_method,
    bb.count_payment_method,
    Round((bb.count_payment_method *100 / tor.total),2)as percentage_from_total_Ordars,
    Round((bb.Revnue * 100 / tr.total),2) as percentage_from_total_revenue
From base as bb
Cross JOIN Total_Revnue as tr
Cross JOIN Total_Ordars as tor;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--How do total sales change by month?
SELECT 
    EXTRACT(YEAR From eb.event_date) as Year,
    EXTRACT(MONTH From eb.event_date) as Month,
    Sum(eb.net_revenue_usd) as total_revenue,
    Sum(eb.net_revenue_usd) - LAG(SUM(eb.net_revenue_usd)) Over (ORDER BY EXTRACT(YEAR FROM eb.event_date), EXTRACT(MONTH FROM eb.event_date)) as Revenue_change
FROM e_base AS EB
Where EXTRACT(YEAR From eb.event_date) IS NOT NULL and eb.is_refunded = False
GROUP BY YEAR,MONTH
ORDER BY YEAR,MONTH ASC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Which channel bring in the most sales?
SELECT
    eb.channel,
    Count(*) as total_ordars,
    Sum(eb.net_revenue_usd) as total_sales
From e_base as eb
where eb.is_refunded IS FALSE
GROUP BY eb.channel
ORDER BY Sum(eb.net_revenue_usd) DESC;

--Which channel  get more customer
SELECT 
    ec.acquisition_channel,
    Round(SUM(eb.net_revenue_usd)) as total_reveune,
    Count(eb.customer_id)
From e_base as eb
INNER JOIN e_customers as ec on ec.customer_id = eb.customer_id 
GROUP BY ec.acquisition_channel
ORDER BY total_reveune DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Most comman refunded reason
SELECT 
    eb.refund_reason,
    count(eb.refund_reason)
From e_base as eb
WHERE eb.refund_reason is NOT NULL
GROUP BY eb.refund_reason;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Calcualte Profit & Cost   
SELECT
        eb.customer_id,
        eb.product_id,
        eb.quantity,
        eb.net_revenue_usd,
        (eb.net_revenue_usd / NULLIF(eb.quantity,0)) AS revenue_per_product,
        (ep.base_price_usd * eb.quantity) AS cost,
        eb.net_revenue_usd - (ep.base_price_usd * eb.quantity) AS profit
FROM e_base AS eb
INNER JOIN e_products AS ep ON ep.product_id = eb.product_id;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Which channels bring the most repeat (loyal) customers?
WITH count_purchaseing_number AS 
(
    SELECT 
        eb.customer_id,
        COUNT(*) AS number_of_purchaseing
    FROM e_base AS eb
    WHERE eb.is_refunded = FALSE 
    GROUP BY eb.customer_id
    HAVING COUNT(*) > 2      
),
Customer_Category AS 
(
    SELECT
        cp.customer_id,
        cp.number_of_purchaseing,
        CASE
            WHEN cp.number_of_purchaseing >= 20 THEN 'Elite Customer'
            WHEN cp.number_of_purchaseing >= 10 THEN 'Loyal Customer'
            ELSE 'Average Customer'
        END AS customer_loyalty
    FROM count_purchaseing_number AS cp
)
SELECT 
    eb.channel,
    cc.customer_loyalty,
    COUNT(DISTINCT cc.customer_id) AS customer_count
FROM e_base AS eb
INNER JOIN Customer_Category AS cc ON cc.customer_id = eb.customer_id
WHERE cc.customer_loyalty = 'Loyal Customer'
GROUP BY eb.channel, cc.customer_loyalty
ORDER BY customer_count DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--What percent of sales comes from loyal customers?
WITH count_purchaseing_number AS 
(
    SELECT 
        eb.customer_id,
        COUNT(*) AS number_of_purchaseing,
        Sum(eb.net_revenue_usd) as total_rev
    FROM e_base AS eb
    WHERE eb.is_refunded = FALSE 
    GROUP BY eb.customer_id
    HAVING COUNT(*) > 2 
),
Customer_Category AS 
(
    SELECT
        cp.customer_id,
        cp.number_of_purchaseing,
        cp.total_rev,
        CASE
            WHEN cp.number_of_purchaseing >= 20 THEN 'Elite Customer'
            WHEN cp.number_of_purchaseing >= 10 THEN 'Loyal Customer'
            ELSE 'Average Customer'
        END AS customer_loyalty
    FROM count_purchaseing_number AS cp
),
total_sales_cte AS
(
    SELECT 
        Sum(net_revenue_usd) as total_sales 
    From e_base
),total_Sales_by_customer_category as 
(
    SELECT 
    cc.customer_loyalty,
    Sum(cc.total_rev) as total_rev
    From Customer_Category as cc
    GROUP BY cc.customer_loyalty
) 
SELECT 
ts.customer_loyalty,
Round((ts.total_rev * 100/tsc.total_sales),2)
From total_Sales_by_customer_category as ts,total_sales_cte as tsc;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Comperstion sales by previos month 
wITH Base_Table aS 
(
    SELECT 
        Extract(YEAR From eb.event_date) as Year,
        Extract(Month From eb.event_date) as Month,
        Sum(eb.net_revenue_usd) as total_sales,
        LAG(Sum(eb.net_revenue_usd),1,0) OVER(ORDER BY EXTRACT(YEAR FROM eb.event_date), EXTRACT(MONTH FROM eb.event_date)) AS prev_month_sales
    From e_base as eb
    GROUP BY Year,Month
    ORDER BY Year,Month ASC
)
SELECT 
    BT.YEAR,
    BT.Month,
    Round(Bt.total_sales),
    Round(BT.total_sales - BT.prev_month_sales) as prev_month_sales_diffrence
    From Base_Table AS BT;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Percentage of every country by total sales 
With Base_Table as 
(
    SELECT
        eb.country,
        Round(SUM(eb.net_revenue_usd)) as total_Sales_By_Country,
        (SELECT Round(SUM(net_revenue_usd)) From e_base) as total_Sales
    From e_base as eb
    Group By eb.country 
)
SELECT
    BT.country,
    BT.total_Sales_By_Country as total_Sales,
    Round(BT.total_Sales_By_Country*100 / BT.total_Sales , 2) as Percentage_From_Total_Sales
From Base_Table as BT
Order By BT.total_Sales_By_Country DESC;
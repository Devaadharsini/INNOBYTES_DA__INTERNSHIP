use internship_3;

desc amazon_sales;

select * from amazon_sales where sl_no between 0 and 4;

alter table amazon_sales modify Date date;

set sql_safe_updates=0;

UPDATE amazon_sales
SET Date = STR_TO_DATE(Date, '%m-%d-%y');

-- Sales Overview--_______________________________________________________________________________________________

-- What is the total sales amount for the period covered in the data set?

select year(date) as year, round(sum(amount),2) as total_sales_amount from amazon_sales group by year;

-- •	What is the average order value?

WITH SALES_CTE AS 
(SELECT Order_ID , sum(Qty*Amount)  AS ORDER_VALUE FROM amazon_sales group by order_id)
SELECT round(avg(ORDER_VALUE),2)  as average_order_value from SALES_CTE ;

-- •	What are the top-selling days of the week?

select distinct date from amazon_sales order by date asc;

with top_selling_cte as (
select  date , status from amazon_sales where status in ('shipped - delivered to buyer', 'shipped')  
and Courier_Status in ( 'shipped','on the way'))
select date as top_selling_days , count(*) as count_of_shipped_and_delivered from top_selling_cte  
group by top_selling_days order by count_of_shipped_and_delivered   desc limit 5;


-- •	Are there any seasonal trends in sales data? For instance, are there specific times of year (e.g., holidays) when sales are higher?

with trends as (
select day(date) as day , month(date) as month , year(date) as year , sum(qty* amount) as tot_Sales
from amazon_sales group by date)
select day,month,year,tot_Sales,
rank() over (order by tot_sales desc) as rank_for_trends from trends;

-- Product Analysis

-- What are the top-selling product categories?

with product as (
select Category as top_selling_product_categories ,sum(qty*amount) as tot_sales from amazon_sales 
 where qty is not null and amount is not null group by Category  )
select top_selling_product_categories,tot_sales,
dense_rank() over ( order by tot_sales desc) as rank_product 
from product  limit 5;

-- •	What is the distribution of sales across different product sizes?

select size as Distribution_of_size, sum(Qty*amount) as tot_sales from amazon_sales 
group by Distribution_of_size order by tot_sales desc ;


-- •	Are there any product categories with consistently low sales volumes?

with low_sales_cte as(
select distinct Date,category , sum(qty*amount) as tot_sales from amazon_sales group by category,date order by tot_sales asc limit 5 )
select date , category , tot_sales from low_sales_cte order by date , tot_sales asc ;

-- 	How does the sales volume vary for different product categories and sizes over time?

select distinct date,category, size,sum(qty*amount) as tot_sales from amazon_sales 
group by date ,category, size order by Date,category, size  asc ;

-- •	What is the average amount spent per product category?
select category, round(avg(amount*qty),1) as average from amazon_sales group by category order by average desc;

-- •	How often do orders get cancelled? Are there any specific product categories 
-- or fulfillment methods associated with higher cancellation rates?

select category as products ,fulfilment ,count(*) as no_of_cancellation 
from amazon_sales where status = 'cancelled' group by products ,fulfilment 
order by no_of_cancellation desc;

-- •	What is the average amount of revenue lost due to cancelled orders?

select category, count(*) as tot_cancelled_orders,
sum(qty*amount) as revenue_lost_cancelled_orders  from amazon_sales
where status='cancelled' group by category order by revenue_lost_cancelled_orders desc ;

-- How many items are typically included in an order? Does this vary depending on factors like product category or customer location?
select  category,avg(qty) avg_qty ,ship_state from amazon_sales
 group by category,ship_state order by ship_state  asc;










-- Fulfillment Analysis

-- What are the different fulfillment methods used (e.g., Amazon fulfillment, Seller fulfillment)?

select distinct Fulfilment as fulfillment_methods from amazon_sales;

-- 	What is the proportion of orders fulfilled by each method?

with proportion_cte as (
select count(distinct order_id) as tot_orders from amazon_sales )
select Fulfilment, count(*) as tot_orders ,count(*) / (select tot_orders from proportion_cte) as 
proportion_of_orders from amazon_sales  group by Fulfilment;


-- •	How does the fulfillment method impact factors like shipping cost and delivery time?

select  Date,fulfilment,Status, currency,sum(amount) as shipping_cost from amazon_sales
 where Status in ('shipped', 'Shipped - Delivered to Buyer')
 group by fulfilment,Status,Date,currency order by fulfilment,Status,Date ;
 
 -- 	Customer Segmentation
 
-- 	Can customer segments be identified based on factors like location, purchase history, or order value?


with segment_cte as(
select ship_city, ship_state,ship_country, count(distinct order_id) as tot_orders , sum(qty*amount)  as tot_sales from amazon_sales 
group by ship_city, ship_state,ship_country  ) 
select ship_city, ship_state,ship_country,tot_orders,
ntile(10) over (partition by tot_orders ) as segemntation
from segment_cte  order by tot_orders desc ;

create view info_amazon_sales as 
with segment_cte as(
select ship_city, ship_state,ship_country, count(distinct order_id) as tot_orders , sum(qty*amount)  as tot_sales from amazon_sales 
group by ship_city, ship_state,ship_country  ) 
select ship_city, ship_state,ship_country,tot_orders,
ntile(10) over (partition by tot_orders ) as segemntation
from segment_cte  order by tot_orders desc ;

select * from info_amazon_sales;

-- •	What are the characteristics of each customer segment (e.g., demographics, buying behavior)?

  SELECT
  CONCAT(Order_ID, '-', MD5(CONCAT(ship_city, ship_state, ship_country))) AS customer_id,
  ship_city,ship_state,ship_country,COUNT(DISTINCT Order_ID) AS total_orders,
  SUM(qty * amount) AS total_sales FROM amazon_sales GROUP BY customer_id, ship_city, ship_state, ship_country
  order by total_sales desc ;

-- •	How does the average order value vary between different customer segments?

select 
CONCAT(Order_ID, '-', MD5(CONCAT(ship_city, ship_state, ship_country))) AS customer_id,
ship_city, ship_state,ship_country, avg(qty*amount) as avg_order_val from amazon_sales 
group by customer_id,ship_city, ship_state,ship_country order by ship_city;

-- Geographical Analysis
-- In which states and cities are sales concentrated?

select ship_city, ship_state, 
sum(qty*amount) as tot_sales,round(avg(qty*amount),2) as avg_order_val
from amazon_sales group by ship_city, ship_state order by tot_sales desc; 

-- 	Are there any regional variations in product preferences or buying behavior?

select category as prod_cat,ship_city, ship_state, count(distinct order_id) as tot_orders,
sum(qty*amount) as tot_sales,round(avg(qty*amount),2) as avg_order_val
 from amazon_sales group by category,ship_city, ship_state
 order by tot_sales desc ;


select category , avg(qty*amount) as avg from amazon_sales group by category;

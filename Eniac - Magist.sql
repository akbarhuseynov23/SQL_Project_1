use magist;

select * from products;

#How many orders are there in the dataset?
SELECT COUNT(*) AS orders_count
FROM orders;
    
#ARE ORDERS ACTUALLY DELIVERED?
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status;

# IS MAGIST HAVING USER GROWTH?
SELECT 
    YEAR(order_purchase_timestamp) AS year_,
    MONTH(order_purchase_timestamp) AS month_,
    COUNT(customer_id)
FROM orders
GROUP BY year_ , month_
ORDER BY year_ , month_;

#How many products are there in the products table? 
SELECT COUNT(DISTINCT product_id) AS products_count
FROM products;
    
#Which are the categories with most products? 
SELECT p.product_category_name, COUNT(DISTINCT p.product_id) AS n_products, pcnt.product_category_name_english
FROM products as p
inner join product_category_name_translation as pcnt on p.product_category_name = pcnt.product_category_name
where pcnt.product_category_name_english in ('audio', 'cds_dvds_musicals', 'cine_photo', 'consoles_games', 'dvds_blu_ray', 'electronics', 'computers_accessories', 'pc_gamer', 'computers', 'tablets_printing_image', 'telephony', 'fixed_telephony')
GROUP BY p.product_category_name
ORDER BY COUNT(product_id) DESC;

#How many of those products were present in actual transactions?
SELECT count(DISTINCT product_id) AS n_products
FROM order_items;

#What’s the price for the most expensive and cheapest products? 
SELECT MIN(price) AS cheapest, MAX(price) AS most_expensive
FROM order_items;

#What are the highest and lowest payment values?
SELECT MAX(payment_value) as highest, MIN(payment_value) as lowest
FROM order_payments;

## --------------------------------------------------------------------------------------------------------------------

#What categories of tech products does Magist have?
select * 
from product_category_name_translation
where product_category_name_english in ('audio', 'cds_dvds_musicals', 'cine_photo', 'consoles_games', 'dvds_blu_ray', 'electronics', 'computers_accessories', 'pc_gamer', 'computers', 'tablets_printing_image', 'telephony', 'fixed_telephony');

#How many products of these tech categories have been sold (within the time window of the database snapshot)? 
select p.product_category_name, pcnt.product_category_name_english, count(p.product_id) as prod_sld_qty
from product_category_name_translation as pcnt
inner join products as p on p.product_category_name = pcnt.product_category_name
inner join order_items as oi on oi.product_id = p.product_id  
where pcnt.product_category_name_english in ('audio', 'cds_dvds_musicals', 'cine_photo', 'consoles_games', 'dvds_blu_ray', 'electronics', 'computers_accessories', 'pc_gamer', 'computers', 'tablets_printing_image', 'telephony', 'fixed_telephony')
group by p.product_category_name
order by prod_sld_qty desc;

#What percentage does that represent from the overall number of products sold? --> (17349/112650)*100 = 15.4%
select sum(prod_sld_qty) as total_tech
from 
    (select p.product_category_name, pcnt.product_category_name_english, count(p.product_id) as prod_sld_qty
    from product_category_name_translation as pcnt
    inner join products as p on p.product_category_name = pcnt.product_category_name
    inner join order_items as oi on oi.product_id = p.product_id  
    where pcnt.product_category_name_english in ('audio', 'cds_dvds_musicals', 'cine_photo', 'consoles_games', 'dvds_blu_ray', 'electronics', 'computers_accessories', 'pc_gamer', 'computers', 'tablets_printing_image', 'telephony', 'fixed_telephony')
    group by p.product_category_name
    order by prod_sld_qty desc) as grand_total ## 17861
union 
select count(order_id) as overall_sum
from order_items as oi; ## 112650

#What’s the average price of the products being sold?
select avg(price) as avg_price
from order_items;
# The average price of all products being sold is 120.65

# FOR PRESENTATION
select avg(price) as avg_price
from order_items
where product_id in (
	select product_id
	from products p
	inner join tech_product_categories tpc  on tpc.product_category_name = p.product_category_name
);
# The average price of tech products is 110


# get all tech product ids, their prices and their categories
select o.product_id, o.price, tpc.product_category_name_english as product_category
from order_items o
inner join products p on p.product_id = o.product_id
inner join tech_product_categories tpc on tpc.product_category_name = p.product_category_name;

# FOR PRESENTATION
# get the average price per tech product category
select o.product_id, avg(o.price) as avg_price, tpc.product_category_name_english as product_category
from order_items o
inner join products p on p.product_id = o.product_id
inner join tech_product_categories tpc on tpc.product_category_name = p.product_category_name
group by product_category
order by avg_price desc;
# This might make a good visualization for the presentation

#Are expensive tech products popular?
select pcnt.product_category_name_english, oi.product_id, oi.price, count(oi.product_id) as repetitions
from order_items as oi
inner join products as p on oi.product_id = p.product_id
inner join product_category_name_translation as pcnt on pcnt.product_category_name = p.product_category_name 
where pcnt.product_category_name_english in ('audio', 'cds_dvds_musicals', 'cine_photo', 'consoles_games', 'dvds_blu_ray', 'electronics', 'computers_accessories', 'pc_gamer', 'computers', 'tablets_printing_image', 'telephony', 'fixed_telephony')
group by oi.product_id
having count(oi.product_id)> 1
order by oi.price desc;

## --------------------------------------------------------------------------------------------------------------------

#How many sellers are there?
SELECT COUNT(*) FROM sellers;
#3095

#What’s the average monthly revenue of Magist’s sellers?
select seller_id, round(avg(revenue_ym), 2)
from (
    SELECT YEAR(shipping_limit_date), MONTH(shipping_limit_date), seller_id, SUM(price) AS revenue_ym  
    FROM order_items
    GROUP BY YEAR(shipping_limit_date), MONTH(shipping_limit_date), seller_id
    ) temp
group by temp.seller_id;  

#What’s the average revenue of sellers that sell tech products?
select avg(mr.monthly_revenue)
from (
	select year(order_purchase_timestamp) as year_, month(order_purchase_timestamp) as month_, oi.seller_id, sum(op.payment_value) AS monthly_revenue
	from order_payments op
	inner join orders o on o.order_id = op.order_id
	inner join order_items oi on oi.order_id = o.order_id
    where oi.product_id in (
		select product_id
		from products p
		inner join tech_product_categories tpc  on tpc.product_category_name = p.product_category_name)
	group by year_, month_, oi.seller_id) mr;
# The average monthly revenue of sellers that sell tech products is 603

## --------------------------------------------------------------------------------------------------------------------

#What’s the average time between the order being placed and the product being delivered?
SELECT avg(timestampdiff(day, order_purchase_timestamp, order_delivered_customer_date))
from orders;
# The average time between orders being placed and delivered is 12days.

#How many orders are delivered on time vs orders delivered with a delay?
select count(*)
from orders;
# There are 99441 orders

select count(*)
from orders
where timestampdiff(day, order_estimated_delivery_date, order_delivered_customer_date) > 1;
# 5710 orders were delivered a day or more late
# 5710/99441 = 5.7% of orders were late

#Is there any pattern for delayed orders, e.g. big products being delayed more often?
select p.product_id, pcnt.product_category_name_english, 
p.product_weight_g/1000 as product_weight, 
(p.product_length_cm*p.product_height_cm*p.product_width_cm)/1000000 as product_dimension_m³, 
avg(datediff(o.order_estimated_delivery_date, o.order_delivered_customer_date)) as avg_delay_in_days
from products as p
inner join order_items as oi on p.product_id = oi.product_id
inner join orders as o on oi.order_id = o.order_id
inner join product_category_name_translation as pcnt on p.product_category_name = pcnt.product_category_name
group by oi.product_id
order by product_dimension_m³ desc
limit 50;






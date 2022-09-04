drop schema if exists dannys_diner;
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

drop table if exists sales;
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
 select * from sales
 
 ---QNS 1 WHAT IS THE TOTAL AMOUNT EACH CUSTOMER SPENT AT THE RESTAURANT?
 select customer_id, sum(price) as total_amount_spent
 from sales
 inner join menu
 using (product_id)
 group by customer_id
 
 ---QNS 2 HOW MANY DAYS HAS EACH CUSTOMER VISITED THE RESTAURANT?
 select customer_id, count( distinct order_date) as number_of_days_visited
 from sales
 group by  customer_id
 
---QNS 3 WHAT WAS THE FIRST ITEM FROM THE MENU PURCHASED BY EACH CUSTOMER?
select customer_id, product_name 
from
(select customer_id, product_name,
dense_rank () over(partition by customer_id order by order_date) first_item
from sales
inner join menu
using (product_id)) as purchases
where first_item = 1

---QNS 4 WHAT IS THE MOST PURCHASED ITEM ON THE MENU AND HOW MANY TIMES WAS IT PURCHASED BY ALL CUSTOMERS?
select product_name, count(product_name) as most_purchased from sales
inner join menu using (product_id)
group by product_name
order by count(product_name) desc
limit 1

---QNS 5 WHICH ITEM WAS THE MOST POPULAR FOR EACH CUSTOMER?
select customer_id, product_name, number_of_products from (
select customer_id, product_name, count(product_name) as number_of_products,
dense_rank () over(partition by customer_id order by count(product_name) desc) popular_item
from sales 
inner join menu using (product_id)
group by customer_id, product_name) as subquery
where popular_item = 1
group by customer_id, product_name,number_of_products

---QNS 6 WHICH ITEM WAS PURCHASED FIRST BY THE CUSTOMER AFTER THEY BECAME A MEMBER?

select customer_id,product_name,order_date from(
select customer_id,product_name,order_date,
dense_rank () over(partition by customer_id order by order_date) as rankings
from sales 
inner join menu using (product_id)
inner join members using (customer_id)
where order_date >= join_date) as first_purchase
where rankings = 1

---QNS 7 WHICH ITEM WAS PURCHASED JUST BEFORE THE CUSTOMER BECAME A MEMBER?
select distinct customer_id,product_name,order_date from(
select customer_id,product_name,order_date,
dense_rank () over(partition by customer_id order by order_date) as rankings
from sales 
inner join menu using (product_id)
inner join members using (customer_id)
where order_date < join_date) as first_purchase
where rankings = 1

----QNS 8 WHAT IS THE TOTAL ITEMS AND AMOUNT SPENT FOR EACH MEMBER BEFORE THEY BECAME A MEMBER?
select customer_id, count(product_name) as total_items, sum(price) as amt_spent
from sales
inner join menu using (product_id)
inner join members using (customer_id)
where order_date < join_date
group by customer_id

/*QNS 9 IF EACH $1 SPENT EQUATES TO 10 POINTS AND SUSHI HAS 2X POINTS MULTIPLIER-HOW MANY POINTS
WOULD EACH CUSTOMER GET?*/
select customer_id, sum(points) as total_points from(
select customer_id, product_name, sum(price) as price,
case when product_name = 'sushi' then sum(price) * 20
else sum(price) * 10
end as points
from sales
inner join menu using (product_id)
group by 1,2) as dollar_spent
group by 1

/* QNS 10 IN THE FIRST WEEK AFTER A CUSTOMER JOINS THE PROGRAM(INCLUDING THEIR JOIN DATE)THEY EARN 2X
POINTS ON ALL ITEMS, NOT JUST SUSHI- HOW MANY POINTS DO CUSTOMER A AND B HAVE AT THE END OF JANUARY?*/

with points as (
select customer_id,order_date,join_date,join_date + interval '6day' as first_week,price,product_name
from sales
inner join menu using (product_id)
inner join members using (customer_id)
where order_date <= '2021-01-31')
select customer_id,
sum(case when order_date between join_date and first_week then price*20
when product_name = 'sushi' then price*20
else price*10
end) as total_points
from points
group by customer_id
	
	
--- BONUS QUESTION 1
-- RECREATING THE TABLE BY JOINING COLUMNS
select customer_id, order_date, product_name, price,
case when order_date >= join_date then 'Y'
else 'N' end as members
from sales s 
left join menu using (product_id)
left join members using (customer_id)
order by customer_id,order_date

--- QUESTION 2
-- RANK THE CUSTOMERS
select *,
case when members = 'N' then null
else dense_rank() over(partition by customer_id, members order by order_date) end as ranks
from ( 
select customer_id, order_date, product_name, price,
case when order_date >= join_date then 'Y'
else 'N' end as members
from sales s 
left join menu using (product_id)
left join members using (customer_id)) as ranking
--1)The total amount each customer spent at the restaurant

Select customer_id,sum(price) as total_amount from sales a
join
menu b
on a.product_id=b.product_id group by customer_id order by 1;

--2)How many days has each customer visited the restaurant?

Select customer_id,count(Distinct order_Date) from 
sales group by customer_id order by 1;

--3)the first item from the menu purchased by each customer
select customer_id,product_name
from
(Select dense_rank() over(partition by customer_id order by order_date) as rnk,
* from sales a
join
menu b
on a.product_id=b.product_id order by 2)a where rnk=1;

---4)the most purchased item on the menu and how many times was it purchased by all customers

Select 
product_name,count(product_name) from sales a
join
menu b
on a.product_id=b.product_id group by product_name


---5)the most popular item for each customer
select customer_id,
product_name 
from
(select customer_id,
product_name
,count(product_name) as cnt, dense_rank() over(partition by customer_id order by count(product_name) desc) as rank from sales a
join
menu b
on a.product_id=b.product_id group by customer_id,
product_name
order by 1)a where  rank=1

--6)item purchased first by the customer after they became a member
select customer_id,product_name
from
(select a.customer_id,b.product_name,
dense_rank() over(partition by a.customer_id order by order_date) as rank
from sales a
join
menu b
on a.product_id=b.product_id
left join
members c
on a.customer_id=c.customer_id
where a.order_date>=c.join_date order by 1) a where rank=1

--7)item was purchased just before the customer became a member
select customer_id,product_name
from
(select a.customer_id,b.product_name,order_date,
dense_rank() over(partition by a.customer_id order by order_date desc) as rank
from sales a
join
menu b
on a.product_id=b.product_id
left join
members c
on a.customer_id=c.customer_id
where a.order_date<c.join_date order by 1) a where rank=1

--8)the total items and amount spent for each member before they became a member
select a.customer_id,count(product_name) total_item,sum(price) as amount_spent
from sales a
join
menu b
on a.product_id=b.product_id
left join
members c
on a.customer_id=c.customer_id
where a.order_date<c.join_date group by a.customer_id order by 1;

--9)If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have
select customer_id,
sum(case when product_name='sushi' then price*10*2
else price*10 end) as points
from sales a
join
menu b
on a.product_id=b.product_id group by customer_id order by 1


---10)In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
--how many points do customer A and B have at the end of January?
select a.customer_id,extract(month from order_date) as month,
sum(case when order_date between join_date and (join_date+7) then price*10*2
when  product_name='sushi' then price*10*2
else price*10 end) as points
from sales a
join
menu b
on a.product_id=b.product_id
 join
 members c
on a.customer_id=c.customer_id
where extract(month from order_date)=01 group by a.customer_id,extract(month from order_date) order by 1

---11)Recreate the table output using the available data

select a.customer_id,
order_date,
product_name,
price,
case when a.customer_id=c.customer_id and order_date>=join_date then 'Y'
else 'N' end as Member
from sales a
join
menu b
on a.product_id=b.product_id
left join
 members c
on a.customer_id=c.customer_id order by 1,2

---11)Ranking of products
with cte as(select a.customer_id,
order_date,
product_name,
price,
case when a.customer_id=c.customer_id and order_date>=join_date then 'Y'
else 'N' end as Member
from sales a
join
menu b
on a.product_id=b.product_id
left join
 members c
on a.customer_id=c.customer_id order by 1,2)
select * ,
case when member='Y' then 
rank() over(partition by customer_id,member order by order_date)
else Null end as rank
from cte


				 

-----Table creation------------------------------
CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);

-- Still works without specifying the column names explicitly
INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');


CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);


CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);

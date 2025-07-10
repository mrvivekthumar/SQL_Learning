--1. write a query to print emp name , their manager name and diffrence in their age (in days) 
--for employees whose year of birth is before their managers year of birth
select e1.emp_name, e2.emp_name as manager_name , (e2.dob - e1.dob) AS diff_in_age_in_days
from employee e1
inner join employee e2 on e1.manager_id = e2.emp_id
where EXTRACT(YEAR FROM e1.dob) < EXTRACT(YEAR FROM e2.dob);

--2. write a query to find subcategories who never had any return orders in the month of november (irrespective of years)
select o.sub_category 
from orders o
left join returns r on o.order_id = r.order_id
where EXTRACT(MONTH FROM order_date) = 11
group by o.sub_category
having count(r.order_id) = 0;

--3. orders table can have multiple rows for a particular order_id when customers buys more than 1 product in an order.
-- write a query to find order ids where there is only 1 product bought by the customer.
select o.order_id
from orders o
group by o.order_id
having count(o.product_name) = 1

--4. write a query to print manager names along with the comma separated list(order by emp salary) of all employees directly reporting to him.
select e2.emp_name as manager_name , STRING_AGG(e1.emp_name,':' ORDER BY e1.salary) as emp_list
from employee e1
inner join employee e2 on e1.manager_id = e2.emp_id
group by e2.emp_name

--5. write a query to get number of business days between order_date and ship_date (exclude weekends). 
--Assume that all order date and ship date are on weekdays only

select order_date, ship_date, 
        (ship_date - order_date + 1) as total_days,
        (ship_date - order_date + 1) - (FLOOR((ship_date - order_date + 1) / 7)::int * 2) AS no_of_business_days
from orders;

--6. write a query to print 3 columns : category, total_sales and (total sales of returned orders)
select o.category , sum(sales) as total_sales, sum(case when r.order_id is not null then sales end) as total_returned_order_sales
from orders o
left join returns r on o.order_id = r.order_id
group by o.category

--7. write a query to print below 3 columns
--category, total_sales_2019(sales in year 2019), total_sales_2020(sales in year 2020)
select category , sum(case when EXTRACT(Year from order_date) = 2019 then sales end) as sales_2019,
sum(case when EXTRACT(Year from order_date)= 2020 then sales end) as total_sales_2020
from orders
group by category;

--8. write a query print top 5 cities in west region by average no of days between order date and ship date.
select city , avg((ship_date - order_date)) as average_no_of_days
from orders 
where region = 'West'
group by city
order by average_no_of_days desc
limit 5;

--9. write a query to print emp name, manager name and senior manager name (senior manager is manager's manager)
select e1.emp_name, e2.emp_name as manager_name , e3.emp_name as senior_manager_name
from employee e1
inner join employee e2 on e1.manager_id = e2.emp_id
inner join employee e3 on e2.manager_id = e3.emp_id;
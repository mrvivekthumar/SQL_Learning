-- 1. write a query to get region wise count of return orders
select  region , count(distinct o.order_id) as return_order
from orders o
inner join returns r on o.order_id = r.order_id
group by region,

--2. write a query to get category wise sales of orders that were not returned
select o.category , sum(o.sales) as total_sales
from orders o
left join returns r on o.order_id = r.order_id
where r.roder_id is null
group by category

--3. write a query to print dep name and average salary of employees in that dep
select d.dep_name , avg(e.salary) as avg_salary_of_employee_in_the_department
from employee e
inner join dept d on d.dep_id = e.dept_id
group by d.dep_name

--4. write a query to print dep names where none of the emplyees have same salary. 
select d.dep_name
from employee e
inner join dept d on e.dept_id=d.dep_id
group by d.dep_name
having count(e.emp_id)=count(distinct e.salary)


--5. write a query to print sub categories where we have all 3 kinds of returns (others,bad quality,wrong items)
select o.sub_category
from orders o 
inner join returns r on o.order_id = r.order_id
group by o.sub_category
having count(distinct r.return_reason) = 3

--6. write a query to find cities where not even a single order was returned.
select o.city , count(distinct o.order_id) as not_even_single_order_returned
from orders o 
left join returns r on o.order_id = r.order_id
group by o.city 
having count(r.order_id)=0

--7. write a query to find top 3 subcategories by sales of returned orders in east region
select sub_category , sum(sales) as return_sales
from orders o
inner join returns r on o.order_id=r.order_id
where o.region = 'East'
group by sub_category
order by return_sales desc
limit 3

--8. write a query to print dep name for which there is no employee
select d.dep_id,d.dep_name
from dept d 
left join employee e on e.dept_id=d.dep_id
group by d.dep_id,d.dep_name
having count(e.emp_id)=0;

--9. write a query to print employees name for dep id is not avaiable in dept table
select e.*
from employee e 
left join dept d on e.dept_id = d.dep_id
where d.dep_id is null
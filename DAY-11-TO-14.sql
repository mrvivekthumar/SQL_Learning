-- # SQL Server to PostgreSQL Migration Guide

-- ## 1. Window Functions and Analytics

-- ### Highest Salaried Employee in Each Department
SELECT *, 
    ROW_NUMBER() OVER(PARTITION BY dept_id ORDER BY salary DESC) as rn,
    RANK() OVER(PARTITION BY dept_id ORDER BY salary DESC) as rnk,
    DENSE_RANK() OVER(PARTITION BY dept_id ORDER BY salary DESC) as d_rnk 
FROM employee;


WITH cat_product_sales AS (
    SELECT category, product_id, SUM(sales) as category_sales 
    FROM orders 
    GROUP BY category, product_id
),
rnk_sales AS (
    SELECT *, 
        RANK() OVER(PARTITION BY category ORDER BY category_sales DESC) as rn 
    FROM cat_product_sales
)
SELECT * FROM rnk_sales WHERE rn <= 5;

-- ## 2. Date Functions Transformation

-- ### SQL Server DATEPART vs PostgreSQL EXTRACT

SELECT EXTRACT(year FROM order_date) as year_order,
       EXTRACT(month FROM order_date) as month_order,
       SUM(sales) as total_sales
FROM orders 
GROUP BY EXTRACT(year FROM order_date), EXTRACT(month FROM order_date);

-- Alternative using DATE_PART function
SELECT DATE_PART('year', order_date) as year_order,
       DATE_PART('month', order_date) as month_order,
       SUM(sales) as total_sales
FROM orders 
GROUP BY DATE_PART('year', order_date), DATE_PART('month', order_date);

-- ### Date Difference Functions

-- Method 1: Using EXTRACT with EPOCH
SELECT EXTRACT(EPOCH FROM (end_time - start_time))/60 as duration
FROM call_logs;

-- Method 2: Using AGE function
SELECT EXTRACT(EPOCH FROM AGE(end_time, start_time))/60 as duration
FROM call_logs;

-- Method 3: Direct interval calculation
SELECT (end_time - start_time) as duration_interval,
       EXTRACT(EPOCH FROM (end_time - start_time))/60 as duration_minutes
FROM call_logs;

-- ## 3. String Functions and Casting

-- ### CAST vs :: operator

-- Method 1: Using CAST
RAISE NOTICE 'total employees %', CAST(cnt AS VARCHAR(10));

-- Method 2: Using :: operator (PostgreSQL specific)
RAISE NOTICE 'total employees %', cnt::VARCHAR(10);

-- Method 3: Using CONCAT function
RAISE NOTICE '%', CONCAT('total employees ', cnt);

-- ## 4. Stored Procedures and Functions
-- ### SQL Server Procedure

CREATE OR REPLACE FUNCTION spemp(p_dept_id INT, OUT p_cnt INT)
RETURNS INT AS $$
BEGIN
    SELECT COUNT(1) INTO p_cnt FROM employee WHERE dept_id = p_dept_id;
    
    IF p_cnt = 0 THEN
        RAISE NOTICE 'there is no employee in this dept';
    ELSE
        RAISE NOTICE 'total employees %', p_cnt;
    END IF;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT spemp(100);

-- Or with OUT parameter
DO $$
DECLARE
    cnt_result INT;
BEGIN
    SELECT spemp(100) INTO cnt_result;
    RAISE NOTICE 'Result: %', cnt_result;
END;
$$;

-- ###  Scalar Function
CREATE OR REPLACE FUNCTION fnproduct(a INT, b INT DEFAULT 200)
RETURNS DECIMAL(5,2) AS $$
BEGIN
    RETURN (a * b);
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT fnproduct(4); -- Uses default value
SELECT fnproduct(4, 300); -- Override default

-- ## 5. PIVOT Operations
-- ###  PIVOT
SELECT category,
    SUM(CASE WHEN EXTRACT(year FROM order_date) = 2020 THEN sales END) as sales_2020,
    SUM(CASE WHEN EXTRACT(year FROM order_date) = 2021 THEN sales END) as sales_2021
FROM orders
GROUP BY category;

SELECT category,
    SUM(sales) FILTER (WHERE EXTRACT(year FROM order_date) = 2020) as sales_2020,
    SUM(sales) FILTER (WHERE EXTRACT(year FROM order_date) = 2021) as sales_2021
FROM orders
GROUP BY category;

-- First enable the tablefunc extension
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Then use crosstab
SELECT * FROM crosstab(
    'SELECT category, EXTRACT(year FROM order_date)::text, SUM(sales)::text 
     FROM orders 
     GROUP BY category, EXTRACT(year FROM order_date) 
     ORDER BY category',
    'VALUES (''2020''), (''2021'')'
) AS ct(category text, sales_2020 text, sales_2021 text);

-- ## 6. UPDATE with JOIN
-- ### SQL Server UPDATE with JOIN

-- Method 1: Using subquery (same as SQL Server)
UPDATE employee 
SET salary = salary * 1.1 
WHERE dept_id IN (SELECT dep_id FROM dept WHERE dep_name = 'HR');

-- Method 2: Using FROM clause (PostgreSQL style)
UPDATE employee 
SET dep_name = d.dep_name 
FROM dept d 
WHERE employee.dept_id = d.dep_id 
AND d.dep_name = 'Analytics';

-- Method 3: Using JOIN in UPDATE (PostgreSQL 9.5+)
UPDATE employee 
SET dep_name = d.dep_name 
FROM employee e 
JOIN dept d ON e.dept_id = d.dep_id 
WHERE employee.emp_id = e.emp_id 
AND d.dep_name = 'Analytics';

-- ## 7. DELETE with JOIN
-- Method 1: Using subquery
DELETE FROM employee 
WHERE dept_id IN (SELECT dep_id FROM dept WHERE dep_name = 'HR');

-- Method 2: Using USING clause (PostgreSQL specific)
DELETE FROM employee 
USING dept d 
WHERE employee.dept_id = d.dep_id 
AND d.dep_name = 'HR';

-- Method 3: Using EXISTS
DELETE FROM employee e
WHERE EXISTS (
    SELECT 1 FROM dept d 
    WHERE e.dept_id = d.dep_id 
    AND d.dep_name = 'HR'
);

-- ## 8. Indexes

-- ### Index Creation
-- PostgreSQL doesn't have clustered/non-clustered concept
-- All indexes are essentially "non-clustered" except for primary key

CREATE INDEX idx_name ON emp_index(emp_name DESC);
CREATE INDEX idx_rn ON orders_index(rn);

-- PostgreSQL equivalent of INCLUDE clause
CREATE INDEX idx_rn_covering ON orders_index(rn) INCLUDE(customer_id);

-- Partial indexes (PostgreSQL specific feature)
CREATE INDEX idx_active_employees ON employee(dept_id) WHERE status = 'active';

-- Expression indexes (PostgreSQL specific)
CREATE INDEX idx_upper_name ON employee(UPPER(emp_name));

-- Concurrent index creation (PostgreSQL specific)
CREATE INDEX CONCURRENTLY idx_salary ON employee(salary);


-- ## 9. Transaction Control
-- ### SQL Server Transactions

-- Basic transaction
BEGIN;
UPDATE employee SET salary = 35000 WHERE emp_id = 1;
COMMIT;

-- With savepoints
BEGIN;
UPDATE employee SET salary = 35000 WHERE emp_id = 1;
SAVEPOINT sp1;
UPDATE employee SET salary = 40000 WHERE emp_id = 2;
ROLLBACK TO SAVEPOINT sp1;
COMMIT;

-- Read-only transaction (PostgreSQL specific)
BEGIN READ ONLY;
SELECT * FROM employee;
COMMIT;

-- Isolation levels
BEGIN ISOLATION LEVEL READ COMMITTED;
-- or SERIALIZABLE, REPEATABLE READ, READ UNCOMMITTED

-- ## 10. Data Types and Special Features
-- ### PostgreSQL Specific Data Types

-- JSON/JSONB support
CREATE TABLE orders_json (
    id SERIAL PRIMARY KEY,
    order_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO orders_json (order_data) VALUES 
('{"customer": "John", "items": [{"product": "laptop", "price": 1000}]}');

-- Query JSON data
SELECT order_data->'customer' as customer,
       order_data->'items'->0->>'product' as first_product
FROM orders_json;

-- Array data type
CREATE TABLE employee_skills (
    emp_id INT,
    skills TEXT[]
);

INSERT INTO employee_skills VALUES 
(1, ARRAY['Python', 'SQL', 'Java']);

-- Query arrays
SELECT emp_id, skills[1] as first_skill,
       'Python' = ANY(skills) as knows_python
FROM employee_skills;

-- UUID data type
CREATE TABLE orders_uuid (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_date DATE
);

-- ### PostgreSQL Window Function Extensions

-- NTILE function for quartiles
SELECT emp_name, salary, dept_id,
       NTILE(4) OVER (ORDER BY salary) as salary_quartile
FROM employee;

-- PERCENT_RANK and CUME_DIST
SELECT emp_name, salary,
       PERCENT_RANK() OVER (ORDER BY salary) as percent_rank,
       CUME_DIST() OVER (ORDER BY salary) as cumulative_dist
FROM employee;

-- Window frame specifications
SELECT emp_name, salary, dept_id,
       AVG(salary) OVER (
           PARTITION BY dept_id 
           ORDER BY salary 
           ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
       ) as moving_avg
FROM employee;

-- ## 11. Common Table Expressions (CTE) Advanced Usage
-- ### Recursive CTEs

-- Employee hierarchy
WITH RECURSIVE emp_hierarchy AS (
    -- Base case: top-level managers
    SELECT emp_id, emp_name, manager_id, 0 as level
    FROM employee 
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case
    SELECT e.emp_id, e.emp_name, e.manager_id, eh.level + 1
    FROM employee e
    JOIN emp_hierarchy eh ON e.manager_id = eh.emp_id
)
SELECT * FROM emp_hierarchy ORDER BY level, emp_name;

-- ## 12. PostgreSQL-Specific Performance Features
-- ### EXPLAIN ANALYZE

-- Detailed query execution plan
EXPLAIN (ANALYZE, BUFFERS, VERBOSE) 
SELECT * FROM orders WHERE customer_id = 'CUST001';

-- Auto-explain for slow queries
LOAD 'auto_explain';
SET auto_explain.log_min_duration = 1000; -- Log queries taking >1 second

-- ### Table Partitioning

-- Range partitioning by date
CREATE TABLE orders_partitioned (
    order_id SERIAL,
    order_date DATE,
    customer_id VARCHAR(20),
    sales DECIMAL(10,2)
) PARTITION BY RANGE (order_date);

-- Create partitions
CREATE TABLE orders_2020 PARTITION OF orders_partitioned
FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');

CREATE TABLE orders_2021 PARTITION OF orders_partitioned
FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
/*

## Key Differences Summary

| Feature | SQL Server | PostgreSQL |
|---------|------------|------------|
| String Concatenation | `+` operator | `||` operator or `CONCAT()` |
| Date Functions | `DATEPART()` | `EXTRACT()` or `DATE_PART()` |
| Boolean Values | `BIT` (0/1) | `BOOLEAN` (true/false) |
| Identity Columns | `IDENTITY(1,1)` | `SERIAL` or `GENERATED ALWAYS AS IDENTITY` |
| Stored Procedures | T-SQL syntax | PL/pgSQL syntax |
| PIVOT | Built-in `PIVOT` | `CASE WHEN` or `CROSSTAB` |
| Indexes | Clustered/Non-clustered | Regular indexes only |
| Transactions | `BEGIN TRAN` | `BEGIN` |
| Error Handling | `TRY...CATCH` | `EXCEPTION` blocks |
| Variable Declaration | `DECLARE @var` | `DECLARE var` |
| Print Statements | `PRINT` | `RAISE NOTICE` |

*/

-- 1. Highest salaried employee in each department
SELECT emp_name, salary, dept_id
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn
  FROM employee
) AS ranked
WHERE rn = 1;

-- 2. Top 5 selling products from each category by total sales
WITH cat_product_sales AS (
  SELECT category, product_id, SUM(sales) AS category_sales
  FROM orders
  GROUP BY category, product_id
),
rnk_sales AS (
  SELECT *, RANK() OVER (PARTITION BY category ORDER BY category_sales DESC) AS rn
  FROM cat_product_sales
)
SELECT * FROM rnk_sales
WHERE rn <= 5;

-- 3. Lead and First Value in each department (by employee name desc)
SELECT *,
  LEAD(salary, 1) OVER (PARTITION BY dept_id ORDER BY emp_name DESC) AS lead_sal,
  FIRST_VALUE(salary) OVER (PARTITION BY dept_id ORDER BY emp_name DESC) AS first_sal
FROM employee;

-- 4. Calculate call duration by matching call start and end logs
SELECT 
  s.phone_number, s.rn, s.start_time, e.end_time,
  EXTRACT(EPOCH FROM (e.end_time - s.start_time)) / 60 AS duration_minutes
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY phone_number ORDER BY start_time) AS rn
  FROM call_start_logs
) s
JOIN (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY phone_number ORDER BY end_time) AS rn
  FROM call_end_logs
) e
ON s.phone_number = e.phone_number AND s.rn = e.rn;

-- 5. Max salary per department and running max salary overall
SELECT *,
  MAX(salary) OVER (PARTITION BY dept_id) AS max_dep_salary,
  MAX(salary) OVER (ORDER BY salary DESC) AS running_max_salary
FROM employee;

-- 6. Sum of salary per department and running sum by emp_id
SELECT *,
  SUM(salary) OVER (PARTITION BY dept_id) AS dep_salary,
  SUM(salary) OVER (ORDER BY emp_id) AS running_salary
FROM employee;

-- 7. Running sum over full partition
SELECT *,
  SUM(salary) OVER (
    PARTITION BY dept_id 
    ORDER BY emp_id 
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  ) AS total_salary
FROM employee;

-- 8. First and last salary using window functions
SELECT *,
  FIRST_VALUE(salary) OVER (ORDER BY salary) AS first_salary,
  FIRST_VALUE(salary) OVER (ORDER BY salary DESC) AS last_salary,
  LAST_VALUE(salary) OVER (
    ORDER BY salary 
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS last_salary_val
FROM employee;

-- 9. Running sales based on order_id and row_id
SELECT order_id, sales,
  SUM(sales) OVER (ORDER BY order_id, row_id) AS running_sales
FROM orders;

-- 10. 3-month rolling sales total by month and year
WITH month_wise_sales AS (
  SELECT EXTRACT(YEAR FROM order_date) AS year_order,
         EXTRACT(MONTH FROM order_date) AS month_order,
         SUM(sales) AS total_sales
  FROM orders
  GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
)
SELECT year_order, month_order, total_sales,
  SUM(total_sales) OVER (
    ORDER BY year_order, month_order 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS rolling_3_sales
FROM month_wise_sales;

-- 11. Update salary of HR department employees by 10%
UPDATE employee
SET salary = salary * 1.1
WHERE dept_id IN (
  SELECT dep_id FROM dept WHERE dep_name = 'HR'
);

-- 12. Add department name column and update from dept table
ALTER TABLE employee ADD COLUMN dep_name VARCHAR(20);

UPDATE employee
SET dep_name = d.dep_name
FROM dept d
WHERE employee.dept_id = d.dep_id AND d.dep_name = 'Analytics';

-- 13. Delete employees from HR department
DELETE FROM employee
USING dept
WHERE employee.dept_id = dept.dep_id AND dept.dep_name = 'HR';

-- 14. EXISTS / NOT EXISTS example
SELECT *
FROM employee_back e
WHERE EXISTS (
  SELECT 1 FROM dept_back d WHERE d.dep_id = e.dept_id
)
AND dept_id = 100;

-- 15. Pivot: category-wise sales for 2020 and 2021
SELECT 
  category,
  SUM(CASE WHEN EXTRACT(YEAR FROM order_date) = 2020 THEN sales ELSE 0 END) AS sales_2020,
  SUM(CASE WHEN EXTRACT(YEAR FROM order_date) = 2021 THEN sales ELSE 0 END) AS sales_2021
FROM orders
GROUP BY category;

-- 16. Unpivot-like query in PostgreSQL (normalized form)
SELECT category, EXTRACT(YEAR FROM order_date) AS year_order, sales
FROM orders;

-- 17. Create materialized view for pivoted data (if needed)
CREATE MATERIALIZED VIEW sales_yearwise AS
SELECT 
  category,
  SUM(CASE WHEN region = 'West' THEN sales ELSE 0 END) AS west_sales,
  SUM(CASE WHEN region = 'East' THEN sales ELSE 0 END) AS east_sales,
  SUM(CASE WHEN region = 'South' THEN sales ELSE 0 END) AS south_sales
FROM orders
GROUP BY category;

-- 18. Insert and clone table
CREATE TABLE orders_east AS
SELECT * FROM orders WHERE region = 'East';

INSERT INTO orders SELECT * FROM orders_back;

-- 19. Transaction control
BEGIN;
UPDATE employee SET salary = 35000 WHERE emp_id = 1;
COMMIT;

-- Savepoint and rollback
BEGIN;
SAVEPOINT a;
INSERT INTO employee VALUES (999, 'Temp', 12345, 10);
ROLLBACK TO SAVEPOINT a;
COMMIT;

-- 20. Function and Procedure equivalent
-- Function: multiply two numbers
CREATE OR REPLACE FUNCTION fnproduct(a INT, b INT DEFAULT 200)
RETURNS NUMERIC AS $$
BEGIN
  RETURN a * b;
END;
$$ LANGUAGE plpgsql;

SELECT fnproduct(4, DEFAULT);

-- Procedure: check employee count in department
CREATE OR REPLACE PROCEDURE spemp(IN dept_id INT, OUT cnt INT)
LANGUAGE plpgsql
AS $$
BEGIN
  SELECT COUNT(*) INTO cnt FROM employee WHERE dept_id = spemp.dept_id;
  IF cnt = 0 THEN
    RAISE NOTICE 'There is no employee in this dept';
  ELSE
    RAISE NOTICE 'Total employees: %', cnt;
  END IF;
END;
$$;

-- Call procedure
CALL spemp(100, NULL);

-- 21. Index creation
CREATE TABLE emp_index (
  emp_id INT PRIMARY KEY,
  emp_name VARCHAR(20),
  salary INT
);

CREATE INDEX idx_name ON emp_index(emp_name DESC);

-- 22. Delete duplicates (keeping latest)
DELETE FROM emp_dup
WHERE ctid NOT IN (
  SELECT MAX(ctid)
  FROM emp_dup
  GROUP BY emp_id
);

-- 23. User permissions (roles)
-- Create role and grant
CREATE ROLE role_sales;
GRANT SELECT ON employee TO role_sales;
GRANT role_sales TO guest;

-- Revoke
REVOKE SELECT, INSERT, DELETE ON employee FROM guest;

-- With grant option
GRANT SELECT ON employee TO guest WITH GRANT OPTION;

-- ====================================================================
-- ADVANCED POSTGRESQL LEARNING GUIDE - INTERMEDIATE TO EXPERT
-- ====================================================================

-- ====================================================================
-- SECTION 1: ADVANCED JOINS AND SELF-JOINS (PRIORITY 3)
-- ====================================================================

-- 1.1 SELF-JOIN EXAMPLES
-- Self-join: Joining a table with itself to find relationships within the same table

-- Find employees who earn more than their managers
-- This compares employee salary with their manager's salary using employee hierarchy
SELECT e1.emp_id, 
       e1.emp_name, 
       e2.emp_name AS manager_name
FROM employee e1 
INNER JOIN employee e2 ON e1.manager_id = e2.emp_id  -- Connect employee to their manager
WHERE e1.salary > e2.salary;  -- Employee earns more than manager

-- 1.2 ADVANCED GROUP BY WITH JOINS
-- Find departments where all employees have the same salary
-- Uses HAVING with COUNT DISTINCT to check salary uniformity
SELECT e.dept_id, d.dep_name 
FROM employee e 
LEFT JOIN dept d ON e.dept_id = d.dep_id 
GROUP BY e.dept_id, d.dep_name 
HAVING COUNT(DISTINCT salary) = COUNT(1);  -- Same number of distinct salaries as total employees

-- Find sub-categories with ALL THREE specific return reasons
-- Ensures complete coverage of specified return reasons
SELECT o.sub_category 
FROM orders o 
LEFT JOIN returns r ON o.order_id = r.order_id 
WHERE return_reason IN ('others','bad quality','wrong item')  -- ✓ Fixed typo: 'quanlity' → 'quality'
GROUP BY o.sub_category 
HAVING COUNT(DISTINCT r.return_reason) = 3;  -- Must have all 3 distinct reasons

-- Find cities with NO returns (orders never returned)
-- Uses LEFT JOIN to include all orders, then filters for NULL return reasons
SELECT o.city 
FROM orders o 
LEFT JOIN returns r ON o.order_id = r.order_id 
WHERE r.return_reason IS NULL  -- Only orders with no returns
GROUP BY o.city 
HAVING COUNT(r.return_reason) = 0;  -- Confirms no return records exist

-- ====================================================================
-- SECTION 2: STRING FUNCTIONS AND MANIPULATION (PRIORITY 4)
-- ====================================================================

-- 2.1 POSTGRESQL STRING FUNCTIONS
-- PostgreSQL uses different syntax than SQL Server for string functions ✓

SELECT order_id,
       customer_name,
       -- String cleaning and manipulation
       TRIM('  ankit bansal  ') AS trimmed_text,              -- Remove leading/trailing spaces
       REVERSE(customer_name) AS reversed_name,               -- ✓ PostgreSQL has REVERSE()
       REPLACE(order_id, 'CA', 'PB') AS replaced_prefix,      -- Replace CA with PB
       REPLACE(customer_name, ' ', '') AS no_spaces,          -- Remove all spaces
       -- ✓ PostgreSQL uses TRANSLATE differently:
       TRANSLATE(customer_name, 'AC', 'B@') AS translated,    -- Replace A→B, C→@
       LENGTH(customer_name) AS name_length,                  -- ✓ LENGTH() not LEN()
       LEFT(customer_name, 4) AS first_four_chars,            -- First 4 characters
       RIGHT(customer_name, 5) AS last_five_chars,            -- Last 5 characters
       -- String position and extraction
       POSITION(' ' IN customer_name) AS space_position,      -- ✓ POSITION() not CHARINDEX()
       POSITION('n' IN customer_name) AS first_n_position,
       -- String concatenation methods
       CONCAT(order_id, '-', customer_name) AS concatenated,  -- Function method
       order_id || '-' || customer_name AS pipe_concatenated  -- ✓ PostgreSQL operator
FROM orders;

-- 2.2 ADVANCED STRING EXTRACTION ✓
-- Extract first name from full name
SELECT customer_name,
       SUBSTRING(customer_name FROM 1 FOR POSITION(' ' IN customer_name) - 1) AS first_name,
       SUBSTRING(customer_name FROM POSITION(' ' IN customer_name) + 1) AS last_name,
       -- ✓ PostgreSQL regex extraction
       SUBSTRING(customer_name FROM '^[A-Za-z]+') AS first_word_regex
FROM orders;

-- 2.3 STRING AGGREGATION
-- Concatenate employee names by department with custom delimiter
-- ✓ PostgreSQL uses STRING_AGG differently than SQL Server
SELECT dept_id,
       STRING_AGG(emp_name, '; ' ORDER BY salary DESC) AS employee_list  -- ✓ No WITHIN GROUP needed
FROM employee 
GROUP BY dept_id;

-- ====================================================================
-- SECTION 3: DATE AND TIME FUNCTIONS (PRIORITY 4)
-- ====================================================================

-- 3.1 POSTGRESQL DATE FUNCTIONS
-- PostgreSQL has different date functions than SQL Server ✓

-- Add date of birth column and calculate from age
ALTER TABLE employee ADD COLUMN dob DATE;

-- ✓ PostgreSQL date arithmetic (not DATEADD/DATEDIFF)
UPDATE employee 
SET dob = CURRENT_DATE - (emp_age || ' years')::INTERVAL;  -- Convert age to date

-- 3.2 DATE CALCULATIONS AND DIFFERENCES
SELECT order_id,
       order_date,
       ship_date,
       -- ✓ PostgreSQL date difference methods
       ship_date - order_date AS days_difference,                    -- Simple subtraction
       EXTRACT(DAY FROM ship_date - order_date) AS days_extracted,   -- Extract days
       DATE_PART('week', ship_date - order_date) AS weeks_diff,      -- Week difference
       -- Date arithmetic
       order_date + INTERVAL '5 days' AS five_days_later,            -- ✓ Add days
       order_date + INTERVAL '5 weeks' AS five_weeks_later,          -- ✓ Add weeks
       order_date - INTERVAL '5 days' AS five_days_earlier,          -- ✓ Subtract days
       -- Date part extraction
       EXTRACT(YEAR FROM order_date) AS order_year,                  -- ✓ EXTRACT not DATEPART
       EXTRACT(MONTH FROM order_date) AS order_month,
       EXTRACT(WEEK FROM order_date) AS order_week,
       TO_CHAR(order_date, 'Month') AS month_name,                   -- ✓ TO_CHAR not DATENAME
       TO_CHAR(order_date, 'Day') AS day_name
FROM orders;

-- 3.3 ADVANCED DATE FUNCTIONS ✓
SELECT order_date,
       -- Age calculations
       AGE(CURRENT_DATE, order_date) AS order_age,
       -- Date truncation
       DATE_TRUNC('month', order_date) AS month_start,
       DATE_TRUNC('year', order_date) AS year_start,
       -- Generate date series ✓
       GENERATE_SERIES(order_date, order_date + INTERVAL '7 days', INTERVAL '1 day') AS week_dates
FROM orders
LIMIT 3;

-- ====================================================================
-- SECTION 4: CASE STATEMENTS AND CONDITIONAL LOGIC (PRIORITY 3)
-- ====================================================================

-- 4.1 BASIC CASE STATEMENTS
-- Categorize profits into different levels
SELECT order_id, 
       profit,
       -- Simple CASE statement for profit categorization
       CASE 
           WHEN profit < 100 THEN 'Low Profit'
           WHEN profit < 250 THEN 'Medium Profit'
           WHEN profit < 400 THEN 'High Profit'
           ELSE 'Very High Profit'
       END AS profit_category,
       -- More complex CASE with multiple conditions
       CASE 
           WHEN profit < 0 THEN 'Loss'
           WHEN profit >= 100 AND profit < 250 THEN 'Medium Profit'
           WHEN profit < 100 THEN 'Low Profit'
           WHEN profit >= 250 AND profit < 400 THEN 'High Profit'
           ELSE 'Very High Profit'
       END AS detailed_profit_category
FROM orders;

-- 4.2 CASE IN AGGREGATIONS ✓
-- Pivot data using CASE statements
SELECT category,
       SUM(CASE WHEN region = 'West' THEN sales END) AS west_sales,
       SUM(CASE WHEN region = 'East' THEN sales END) AS east_sales,
       SUM(CASE WHEN region = 'South' THEN sales END) AS south_sales,
       SUM(CASE WHEN region = 'Central' THEN sales END) AS central_sales
FROM orders
GROUP BY category;

-- ====================================================================
-- SECTION 5: NULL HANDLING FUNCTIONS (PRIORITY 3)
-- ====================================================================

-- 5.1 POSTGRESQL NULL HANDLING
-- ✓ PostgreSQL uses COALESCE instead of ISNULL
SELECT order_id,
       city,
       COALESCE(city, 'Unknown') AS city_with_default,          -- ✓ COALESCE not ISNULL
       COALESCE(sales, 0) AS sales_with_zero,                   -- Handle NULL sales
       state,
       COALESCE(city, state, region, 'Unknown') AS location,    -- First non-NULL value
       -- Null checking
       NULLIF(city, '') AS null_if_empty,                       -- ✓ Convert empty string to NULL
       CASE WHEN city IS NULL THEN 'Missing' ELSE city END AS manual_null_check
FROM orders
WHERE city IS NULL OR city = ''
ORDER BY city NULLS FIRST;  -- ✓ PostgreSQL NULL ordering

-- ====================================================================
-- SECTION 6: DATA TYPE CONVERSION AND FORMATTING (PRIORITY 4)
-- ====================================================================

-- 6.1 POSTGRESQL CASTING AND CONVERSION
SELECT order_id,
       sales,
       -- ✓ PostgreSQL casting methods
       sales::INTEGER AS sales_int_method1,                     -- PostgreSQL-specific casting
       CAST(sales AS INTEGER) AS sales_int_method2,             -- Standard SQL casting
       ROUND(sales, 1) AS sales_rounded,                        -- Round to 1 decimal
       FLOOR(sales) AS sales_floor,                             -- ✓ Round down
       CEIL(sales) AS sales_ceiling,                            -- ✓ Round up
       TRUNC(sales, 0) AS sales_truncated                       -- ✓ Truncate decimals
FROM orders
LIMIT 5;

-- ====================================================================
-- SECTION 7: SET OPERATIONS (PRIORITY 5)
-- ====================================================================

-- 7.1 CREATING SAMPLE TABLES FOR SET OPERATIONS
CREATE TABLE orders_west (
    order_id INTEGER,
    region VARCHAR(10),
    sales INTEGER
);

CREATE TABLE orders_east (
    order_id INTEGER,
    region VARCHAR(10),
    sales INTEGER
);

-- Insert sample data
INSERT INTO orders_west VALUES 
(1,'west',100), (2,'west',200), (3,'east',100), (1,'west',100);

INSERT INTO orders_east VALUES 
(3,'east',100), (4,'east',300);

-- 7.2 UNION OPERATIONS
-- UNION ALL: Includes duplicates, faster performance
SELECT * FROM orders_west
UNION ALL
SELECT * FROM orders_east;

-- UNION: Removes duplicates, slower performance
SELECT * FROM orders_west
UNION
SELECT * FROM orders_east;

-- 7.3 SET DIFFERENCE AND INTERSECTION ✓
-- EXCEPT: Records in first query but not in second (PostgreSQL syntax)
SELECT * FROM orders_east
EXCEPT
SELECT * FROM orders_west;

-- Symmetric difference: Records in either set but not both ✓
(SELECT * FROM orders_east EXCEPT SELECT * FROM orders_west)
UNION ALL
(SELECT * FROM orders_west EXCEPT SELECT * FROM orders_east);

-- INTERSECT: Records common to both queries ✓
SELECT * FROM orders_east
INTERSECT
SELECT * FROM orders_west;

-- 7.4 PRACTICAL SET OPERATIONS EXAMPLE
-- World Cup team statistics using UNION ALL
SELECT team_1 AS team_name,
       CASE WHEN team_1 = winner THEN 1 ELSE 0 END AS win_flag
FROM icc_world_cup
UNION ALL
SELECT team_2 AS team_name,
       CASE WHEN team_2 = winner THEN 1 ELSE 0 END AS win_flag
FROM icc_world_cup;

-- ====================================================================
-- SECTION 8: COMPLEX REPORTING AND PIVOT OPERATIONS (PRIORITY 5)
-- ====================================================================

-- 8.1 HIERARCHICAL REPORTING
-- Create multi-level reports with different grouping levels
SELECT 'category' AS hierarchy_type,
       category AS hierarchy_name,
       SUM(CASE WHEN region = 'West' THEN sales END) AS total_sales_west_region,
       SUM(CASE WHEN region = 'East' THEN sales END) AS total_sales_east_region,
       NULL AS total_sales_south_region
FROM orders
GROUP BY category

UNION ALL

SELECT 'sub-category' AS hierarchy_type,
       sub_category AS hierarchy_name,
       SUM(CASE WHEN region = 'West' THEN sales END),
       SUM(CASE WHEN region = 'East' THEN sales END),
       SUM(CASE WHEN region = 'South' THEN sales END)
FROM orders
GROUP BY sub_category

UNION ALL

SELECT 'ship_mode' AS hierarchy_type,
       ship_mode AS hierarchy_name,
       SUM(CASE WHEN region = 'West' THEN sales END),
       SUM(CASE WHEN region = 'East' THEN sales END),
       SUM(CASE WHEN region = 'South' THEN sales END)
FROM orders
GROUP BY ship_mode;

-- ====================================================================
-- SECTION 9: VIEWS AND VIRTUAL TABLES (PRIORITY 4)
-- ====================================================================

-- 9.1 SIMPLE VIEWS
-- Create a basic view for all orders
CREATE VIEW orders_vw AS
SELECT * FROM orders;

-- Query the view like a regular table
SELECT * FROM orders_vw LIMIT 10;

-- 9.2 COMPLEX VIEWS
-- Create a view with complex aggregation and hierarchy
CREATE VIEW orders_summary_vw AS
SELECT 'category' AS hierarchy_type,
       category AS hierarchy_name,
       SUM(CASE WHEN region = 'West' THEN sales END) AS total_sales_west_region,
       SUM(CASE WHEN region = 'East' THEN sales END) AS total_sales_east_region,
       NULL AS total_sales_south_region
FROM orders
GROUP BY category

UNION ALL

SELECT 'sub-category',
       sub_category,
       SUM(CASE WHEN region = 'West' THEN sales END),
       SUM(CASE WHEN region = 'East' THEN sales END),
       SUM(CASE WHEN region = 'South' THEN sales END)
FROM orders
GROUP BY sub_category;

-- Query the complex view
SELECT * FROM orders_summary_vw;

-- 9.3 FILTERED VIEWS ✓
-- Create region-specific views
CREATE VIEW orders_south_vw AS
SELECT * FROM orders WHERE region = 'South';

-- Cross-database views (if needed) ✓
-- CREATE VIEW emp_master AS
-- SELECT * FROM other_database.public.emp;

-- ====================================================================
-- SECTION 10: REFERENTIAL INTEGRITY AND CONSTRAINTS (PRIORITY 4)
-- ====================================================================

-- 10.1 FOREIGN KEY CONSTRAINTS
-- Create department table with primary key
CREATE TABLE dept (
    dep_id INTEGER PRIMARY KEY,
    dep_name VARCHAR(50)
);

-- Create employee table with foreign key reference
CREATE TABLE emp (
    emp_id INTEGER,
    emp_name VARCHAR(10),
    dep_id INTEGER NOT NULL REFERENCES dept(dep_id)  -- Foreign key constraint
);

-- Insert valid department first
INSERT INTO dept VALUES (500, 'Operations');

-- This will work - department exists
INSERT INTO emp VALUES (1, 'Ankit', 500);

-- This will fail - department 600 doesn't exist
-- INSERT INTO emp VALUES (2, 'Ramesh', 600);

-- 10.2 CONSTRAINT MANAGEMENT ✓
-- Add primary key to existing table
ALTER TABLE dept ADD CONSTRAINT pk_dept PRIMARY KEY (dep_id);

-- Add foreign key to existing table
ALTER TABLE emp ADD CONSTRAINT fk_emp_dept 
FOREIGN KEY (dep_id) REFERENCES dept(dep_id);

-- 10.3 SERIAL/IDENTITY COLUMNS ✓
-- PostgreSQL uses SERIAL for auto-increment (not IDENTITY)
CREATE TABLE dept1 (
    id SERIAL PRIMARY KEY,  -- ✓ SERIAL instead of IDENTITY
    dep_id INTEGER,
    dep_name VARCHAR(10)
);

-- Insert with auto-increment
INSERT INTO dept1(dep_id, dep_name) VALUES (100, 'HR');
INSERT INTO dept1(dep_id, dep_name) VALUES (200, 'Analytics');

-- ====================================================================
-- SECTION 11: SUBQUERIES (PRIORITY 5)
-- ====================================================================

-- 11.1 SIMPLE SUBQUERIES
-- Find average order value using subquery
SELECT AVG(order_sales) AS avg_order_value
FROM (
    SELECT order_id, SUM(sales) AS order_sales
    FROM orders
    GROUP BY order_id
) AS orders_aggregated;

-- 11.2 CORRELATED SUBQUERIES
-- Find orders with sales above average order value
SELECT order_id
FROM orders
GROUP BY order_id
HAVING SUM(sales) > (
    SELECT AVG(order_sales)
    FROM (
        SELECT order_id, SUM(sales) AS order_sales
        FROM orders
        GROUP BY order_id
    ) AS orders_aggregated
);

-- 11.3 SUBQUERIES WITH NOT IN/NOT EXISTS ✓
-- Find employees in departments that don't exist
SELECT * FROM employee 
WHERE dept_id NOT IN (100, 200, 300);

-- Better approach using NOT EXISTS (handles NULLs better) ✓
SELECT * FROM employee e
WHERE NOT EXISTS (
    SELECT 1 FROM dept d WHERE d.dep_id = e.dept_id
);

-- 11.4 SCALAR SUBQUERIES ✓
-- Add company average salary to each employee record
SELECT *,
       (SELECT AVG(salary) FROM employee) AS company_avg_salary
FROM employee
WHERE dept_id IN (SELECT dep_id FROM dept);

-- ====================================================================
-- SECTION 12: COMMON TABLE EXPRESSIONS (CTEs) (PRIORITY 5)
-- ====================================================================

-- 12.1 BASIC CTE
-- Rewrite subquery using CTE for better readability
WITH team_matches AS (
    SELECT team_1 AS team_name,
           CASE WHEN team_1 = winner THEN 1 ELSE 0 END AS win_flag
    FROM icc_world_cup
    UNION ALL
    SELECT team_2 AS team_name,
           CASE WHEN team_2 = winner THEN 1 ELSE 0 END AS win_flag
    FROM icc_world_cup
)
SELECT team_name,
       COUNT(*) AS matches_played,
       SUM(win_flag) AS matches_won,
       COUNT(*) - SUM(win_flag) AS matches_lost
FROM team_matches
GROUP BY team_name;

-- 12.2 MULTIPLE CTEs
-- Multiple CTEs for complex calculations
WITH dept_avg AS (
    SELECT dept_id, AVG(salary) AS avg_dept_salary
    FROM employee
    GROUP BY dept_id
),
total_salary AS (
    SELECT SUM(avg_dept_salary) AS total_salary
    FROM dept_avg
)
SELECT e.*, d.avg_dept_salary
FROM employee e
INNER JOIN dept_avg d ON e.dept_id = d.dept_id;

-- 12.3 RECURSIVE CTEs ✓
-- Find employee hierarchy (manager-subordinate relationships)
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: Top-level managers (no manager)
    SELECT emp_id, emp_name, manager_id, 1 AS level
    FROM employee
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: Employees with managers
    SELECT e.emp_id, e.emp_name, e.manager_id, eh.level + 1
    FROM employee e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.emp_id
)
SELECT * FROM employee_hierarchy ORDER BY level, emp_name;

-- ====================================================================
-- SECTION 13: WINDOW FUNCTIONS (PRIORITY 6)
-- ====================================================================

-- 13.1 RANKING FUNCTIONS
-- Find highest salaried employee in each department
SELECT *,
       ROW_NUMBER() OVER(PARTITION BY dept_id ORDER BY salary DESC) AS row_num,
       RANK() OVER(PARTITION BY dept_id ORDER BY salary DESC) AS rank_num,
       DENSE_RANK() OVER(PARTITION BY dept_id ORDER BY salary DESC) AS dense_rank_num
FROM employee;

-- Get only the highest paid employee per department
WITH ranked_employees AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY dept_id ORDER BY salary DESC) AS rn
    FROM employee
)
SELECT * FROM ranked_employees WHERE rn = 1;

-- 13.2 ANALYTICAL FUNCTIONS
-- Top 5 selling products from each category
WITH category_product_sales AS (
    SELECT category, product_id, SUM(sales) AS total_sales
    FROM orders
    GROUP BY category, product_id
),
ranked_sales AS (
    SELECT *,
           RANK() OVER(PARTITION BY category ORDER BY total_sales DESC) AS sales_rank
    FROM category_product_sales
)
SELECT * FROM ranked_sales WHERE sales_rank <= 5;

-- 13.3 LAG/LEAD FUNCTIONS ✓
-- Compare current salary with next/previous employee
SELECT *,
       LAG(salary, 1) OVER(PARTITION BY dept_id ORDER BY emp_name) AS prev_salary,
       LEAD(salary, 1) OVER(PARTITION BY dept_id ORDER BY emp_name) AS next_salary,
       salary - LAG(salary, 1) OVER(PARTITION BY dept_id ORDER BY emp_name) AS salary_diff
FROM employee;

-- 13.4 FRAME FUNCTIONS ✓
-- Running totals and moving averages
SELECT emp_name, dept_id, salary,
       SUM(salary) OVER(PARTITION BY dept_id ORDER BY salary ROWS UNBOUNDED PRECEDING) AS running_total,
       AVG(salary) OVER(PARTITION BY dept_id ORDER BY salary ROWS 2 PRECEDING) AS moving_avg_3,
       FIRST_VALUE(salary) OVER(PARTITION BY dept_id ORDER BY salary DESC) AS highest_in_dept,
       LAST_VALUE(salary) OVER(PARTITION BY dept_id ORDER BY salary DESC 
                              ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS lowest_in_dept
FROM employee;

-- ====================================================================
-- SECTION 14: ADVANCED SCENARIOS NOT COVERED ✓
-- ====================================================================

-- 14.1 PIVOT OPERATIONS (PostgreSQL Method) ✓
-- PostgreSQL doesn't have native PIVOT, use conditional aggregation
SELECT 
    product_id,
    SUM(CASE WHEN EXTRACT(QUARTER FROM order_date) = 1 THEN sales ELSE 0 END) AS q1_sales,
    SUM(CASE WHEN EXTRACT(QUARTER FROM order_date) = 2 THEN sales ELSE 0 END) AS q2_sales,
    SUM(CASE WHEN EXTRACT(QUARTER FROM order_date) = 3 THEN sales ELSE 0 END) AS q3_sales,
    SUM(CASE WHEN EXTRACT(QUARTER FROM order_date) = 4 THEN sales ELSE 0 END) AS q4_sales
FROM orders
GROUP BY product_id;

-- 14.2 CROSSTAB USING PostgreSQL Extensions ✓
-- Enable tablefunc extension for CROSSTAB
-- CREATE EXTENSION IF NOT EXISTS tablefunc;

-- 14.3 ARRAY OPERATIONS ✓
-- Working with PostgreSQL arrays
CREATE TABLE product_tags (
    product_id INTEGER,
    tags TEXT[]
);

INSERT INTO product_tags VALUES 
(1, ARRAY['electronics', 'computers', 'laptop']),
(2, ARRAY['furniture', 'office', 'chair']);

-- Query array elements
SELECT product_id, 
       tags,
       tags[1] AS first_tag,  -- Array indexing starts at 1
       CARDINALITY(tags) AS tag_count,
       'electronics' = ANY(tags) AS is_electronics
FROM product_tags;

-- 14.4 JSON OPERATIONS ✓
-- Working with JSON data in PostgreSQL
CREATE TABLE order_details (
    order_id VARCHAR(20),
    details JSONB
);

INSERT INTO order_details VALUES 
('CA-2020-001', '{"customer": "John Doe", "items": [{"name": "Laptop", "qty": 1}]}');

-- Query JSON data
SELECT order_id,
       details->>'customer' AS customer_name,
       details->'items'->0->>'name' AS first_item,
       jsonb_array_length(details->'items') AS item_count
FROM order_details;

-- 14.5 FULL TEXT SEARCH ✓
-- PostgreSQL full-text search capabilities
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title TEXT,
    content TEXT,
    search_vector TSVECTOR
);

-- Create search index
CREATE INDEX idx_search ON documents USING GIN(search_vector);

-- Update search vector
UPDATE documents 
SET search_vector = to_tsvector('english', title || ' ' || content);

-- Search documents
SELECT * FROM documents 
WHERE search_vector @@ to_tsquery('english', 'database & postgresql');

-- 14.6 PARTITIONING ✓
-- Table partitioning for large datasets
CREATE TABLE orders_partitioned (
    order_id VARCHAR(20),
    order_date DATE,
    sales DECIMAL(10,2)
) PARTITION BY RANGE (order_date);

-- Create partitions
CREATE TABLE orders_2020 PARTITION OF orders_partitioned
FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');

CREATE TABLE orders_2021 PARTITION OF orders_partitioned
FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');

-- 14.7 MATERIALIZED VIEWS ✓
-- Pre-computed views for performance
CREATE MATERIALIZED VIEW sales_summary AS
SELECT region, category, SUM(sales) AS total_sales
FROM orders
GROUP BY region, category;

-- Refresh materialized view
REFRESH MATERIALIZED VIEW sales_summary;

-- 14.8 STORED PROCEDURES AND FUNCTIONS ✓
-- Create a PostgreSQL function
CREATE OR REPLACE FUNCTION get_employee_count(dept_name TEXT)
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM employee e 
            JOIN dept d ON e.dept_id = d.dep_id 
            WHERE d.dep_name = dept_name);
END;
$$ LANGUAGE plpgsql;

-- Use the function
SELECT get_employee_count('Engineering');

-- ====================================================================
-- SECTION 15: PERFORMANCE OPTIMIZATION ✓
-- ====================================================================

-- 15.1 QUERY OPTIMIZATION
-- Use EXPLAIN ANALYZE to understand query performance
EXPLAIN ANALYZE
SELECT * FROM orders WHERE region = 'West' AND category = 'Technology';

-- 15.2 INDEX STRATEGIES ✓
-- Single column index
CREATE INDEX idx_orders_region ON orders(region);

-- Composite index (order matters!)
CREATE INDEX idx_orders_region_category ON orders(region, category);

-- Partial index (conditional)
CREATE INDEX idx_high_value_orders ON orders(order_date) 
WHERE sales > 1000;

-- 15.3 VACUUM AND ANALYZE ✓
-- PostgreSQL maintenance commands
VACUUM ANALYZE orders;  -- Reclaim space and update statistics
REINDEX INDEX idx_orders_region;  -- Rebuild index

-- ====================================================================
-- POSTGRESQL COMPATIBILITY SUMMARY ✓
-- ====================================================================

/*
KEY POSTGRESQL DIFFERENCES FROM SQL SERVER:
1. LIMIT instead of TOP
2. STRING_AGG instead of STRING_AGG...WITHIN GROUP
3. COALESCE instead of ISNULL
4. LENGTH() instead of LEN()
5. POSITION() instead of CHARINDEX()
6. EXTRACT() instead of DATEPART()
7. TO_CHAR() instead of DATENAME()
8. SERIAL instead of IDENTITY
9. || for string concatenation
10. Array data types and operations
11. JSONB for JSON data
12. Different casting syntax (::type)
13. Recursive CTEs syntax
14. EXCEPT/INTERSECT instead of some proprietary operations
15. Different date arithmetic (INTERVAL)

SCENARIOS NOT COVERED IN ORIGINAL NOTES ✓:
1. Recursive CTEs for hierarchical data
2. Array operations and indexing
3. JSON/JSONB operations
4. Full-text search
5. Table partitioning
6. Materialized views
7. Stored procedures/functions
8. PIVOT alternatives
9. Performance optimization
10. Database maintenance (VACUUM, ANALYZE)
11. Advanced window frame specifications
12. PostgreSQL-specific extensions
13. Cross-database queries
14. Transaction isolation levels
15. Error handling in functions
*/
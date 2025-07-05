-- ====================================================================
-- COMPLETE POSTGRESQL LEARNING GUIDE - BEGINNER TO ADVANCED
-- ====================================================================

-- ====================================================================
-- SECTION 1: BASICS - START HERE (PRIORITY 1)
-- ====================================================================

-- 1.1 INTRODUCTION TO SQL
-- SQL = Structured Query Language
-- Used to communicate with databases
-- Four main categories:
--   DDL (Data Definition Language) - Creating/modifying structure
--   DML (Data Manipulation Language) - Adding/updating/deleting records
--   DQL (Data Query Language) - Retrieving data
--   DCL (Data Control Language) - Managing permissions ✓

-- 1.2 DATA TYPES IN POSTGRESQL
/*
PostgreSQL Data Types (✓ Enhanced for PostgreSQL):
- 🔢 Numeric Types
- INTEGER/INT (4 bytes) : Whole numbers (-2,147,483,648 to 2,147,483,647)
- BIGINT (8 bytes) : Large integers ✓
- SMALLINT (2 bytes) : Small numbers (e.g., age, status codes) (-32,768 to +32,767) ✓
- SERIAL: Auto-incrementing integer ✓
- BIGSERIAL: Auto-incrementing integer ✓
- DECIMAL(precision,scale): (e.g., DECIMAL(5,2) = 123.45)
- NUMERIC: Same as DECIMAL ✓

- 📅 Date/Time Types
- DATE: '2020-11-01' (YYYY-MM-DD format) (e.g., DOB, joining date)
- TIME [without time zone] : Time only (HH:MM:SS) (e.g., store hours , schedules, durations)
- TIMESTAMP [without time zone]: '2020-11-01 12:05:12' (replaces DATETIME in other DBs) Date + time (e.g.,  Use for: created_at, updated_at)
- TIMESTAMPTZ : Timestamp with timezone ( Use for: global apps, logging)
- INTERVAL - Time duration. (Use for: age calculations, time differences) (e.g., 3 days, 2 hours)

- 🔤 Character/Text Types
- CHAR(n) : Fixed-length text (e.g., country codes: 'IN')
- VARCHAR(n): Variable character string up to n characters  (e.g., names, titles)
- TEXT: Unlimited text (e.g., descriptions, blog posts) ✓

- ✅ Boolean Type
- BOOLEAN: TRUE/FALSE ✓ (e.g., is_active, is_verified)

- 🔘 JSON/JSONB Types
- JSON: Store JSON text (preserves formatting)
- JSONB: Binary JSON (faster, indexable) — use for querying JSON ✓

- 🔂 Arrays
- any[] =>(e.g., int[], text[]) : Lists of values in a single column
- UUID - Unique identifiers. Use for: distributed systems, unique keys  (e.g., user/session IDs in distributed systems)

- 📁 Binary Data
- BYTEA  : Binary data. (Use for: files, images, encrypted data) (e.g., file storage, images)

*/

-- ====================================================================
-- SECTION 2: DDL - DATA DEFINITION LANGUAGE (PRIORITY 1)
-- ====================================================================

-- 2.1 CREATING TABLES
-- DDL -> Data Definition Language - defines database structure
CREATE TABLE amazon_orders (
    order_id INTEGER,                    -- Whole number identifier
    order_date DATE,                     -- Date in YYYY-MM-DD format
    product_name VARCHAR(100),           -- Text up to 100 characters
    total_price DECIMAL(6,2),           -- Price with 4 digits before, 2 after decimal
    payment_method VARCHAR(20)           -- Payment type
);

-- 2.2 DROPPING TABLES
-- Completely removes table and all its data
-- DROP TABLE amazon_orders;

-- 2.3 ALTERING TABLES - MODIFYING STRUCTURE
-- PostgreSQL uses different syntax than SQL Server/MySQL ✓

-- Change column data type (PostgreSQL syntax)
ALTER TABLE amazon_orders ALTER COLUMN order_date TYPE TIMESTAMP; -- ✓ PostgreSQL uses TYPE keyword

-- Add new columns to existing table
ALTER TABLE amazon_orders ADD COLUMN username VARCHAR(20);        -- ✓ Added COLUMN keyword
ALTER TABLE amazon_orders ADD COLUMN category VARCHAR(20);

-- Remove column from table
ALTER TABLE amazon_orders DROP COLUMN category;                   -- Safe - removes column permanently

-- IMPORTANT: Data type changes must be compatible
-- Can only change if data can convert safely
-- Example: DATE to TIMESTAMP (✓), but not INTEGER to DATE (X)

-- ====================================================================
-- SECTION 3: CONSTRAINTS - DATA INTEGRITY (PRIORITY 2)
-- ====================================================================

-- Constraints ensure data quality and relationships
DROP TABLE IF EXISTS a_orders; -- ✓ PostgreSQL syntax for safe drop

CREATE TABLE a_orders (
    order_id INTEGER NOT NULL,                    -- NOT NULL: Field must have value
    order_date DATE,
    product_name VARCHAR(100) NOT NULL,
    total_price DECIMAL(6,2),
    -- CHECK constraint: Validates data meets condition
    payment_method VARCHAR(20) CHECK (payment_method IN ('UPI','CREDIT CARD')) DEFAULT 'UPI',
    -- Multiple constraints on one column
    discount INTEGER CHECK (discount <= 20),      -- Discount cannot exceed 20%
    -- DEFAULT constraint: Provides value if none specified
    category VARCHAR(20) DEFAULT 'Mens Wear',
    -- COMPOSITE PRIMARY KEY: Combination must be unique
    PRIMARY KEY (order_id, product_name)          -- Both together must be unique
);

-- Primary Key = UNIQUE + NOT NULL constraint combined
-- Ensures each row can be uniquely identified

-- ====================================================================
-- SECTION 4: DML - DATA MANIPULATION LANGUAGE (PRIORITY 1)
-- ====================================================================

-- 4.1 INSERTING DATA
-- DML -> Data Manipulation Language - modifies data within tables

-- Insert complete record with all values
INSERT INTO a_orders VALUES(1,'2022-10-01','Shirts',132.5,'UPI',20,'kids wear');

-- Insert partial record (unspecified columns get DEFAULT values)
INSERT INTO a_orders(order_id, order_date, product_name, total_price, payment_method) 
VALUES(7,'2022-10-01','Shirts',132.5,'UPI');

-- Using DEFAULT keyword explicitly
INSERT INTO a_orders(order_id, order_date, product_name, total_price, payment_method) 
VALUES(2,'2022-10-01','jeans',132.5, DEFAULT);  -- Uses DEFAULT value for payment_method

-- 4.2 UPDATING DATA
-- Update all records (dangerous - no WHERE clause)
UPDATE a_orders SET discount = 10;

-- Update specific records using WHERE clause (recommended)
UPDATE a_orders 
SET discount = 10 
WHERE order_id = 2;

-- Update multiple columns at once
UPDATE a_orders
SET product_name = 'jeans2', 
    payment_method = 'CREDIT CARD'
WHERE product_name = 'jeans';

-- 4.3 DELETING DATA
-- Delete all records (keeps table structure)
DELETE FROM amazon_orders;

-- Delete specific records using WHERE clause
DELETE FROM a_orders 
WHERE product_name = 'jeans';

-- ====================================================================
-- SECTION 5: DQL - DATA QUERYING LANGUAGE (PRIORITY 1)
-- ====================================================================

-- 5.1 BASIC SELECT STATEMENTS
-- DQL -> Data Querying Language - retrieves data from tables

-- Select all columns and rows
SELECT * FROM amazon_orders;

-- Select specific columns (limits columns returned)
SELECT product_name, order_date, total_price FROM amazon_orders;

-- PostgreSQL LIMIT syntax (not TOP like SQL Server) ✓
SELECT * FROM amazon_orders LIMIT 1;  -- ✓ PostgreSQL uses LIMIT instead of TOP

-- 5.2 SORTING DATA
-- ORDER BY: Arranges results in specified order
SELECT * FROM amazon_orders
ORDER BY order_date DESC,           -- Primary sort: newest first
         product_name DESC,          -- Secondary sort: Z to A
         payment_method;             -- Tertiary sort: A to Z (ASC is default)

-- 5.3 REMOVING DUPLICATES
-- DISTINCT: Returns only unique values
SELECT DISTINCT order_date FROM orders
ORDER BY order_date;

-- DISTINCT on multiple columns: Unique combinations
SELECT DISTINCT ship_mode, segment FROM orders;

-- DISTINCT on all columns: Completely unique rows
SELECT DISTINCT * FROM orders;

-- ====================================================================
-- SECTION 6: FILTERING DATA - WHERE CLAUSE (PRIORITY 2)
-- ====================================================================

-- 6.1 BASIC FILTERING
-- WHERE clause: Filters rows based on conditions

-- Exact match filter
SELECT * FROM orders
WHERE ship_mode = 'First Class';

-- Date filtering
SELECT * FROM orders
WHERE order_date = '2020-12-08';

-- Not equal operator
SELECT order_date, quantity 
FROM orders
WHERE quantity != 5        -- or <> for not equal
ORDER BY quantity DESC;

-- 6.2 COMPARISON OPERATORS
-- Less than filter
SELECT * FROM orders
WHERE order_date < '2020-12-08'
ORDER BY order_date DESC;

-- 6.3 RANGE FILTERING
-- BETWEEN: Inclusive range (includes both boundaries)
SELECT * FROM orders
WHERE order_date BETWEEN '2020-12-08' AND '2020-12-12'
ORDER BY order_date DESC;

SELECT * FROM orders
WHERE quantity BETWEEN 3 AND 5
ORDER BY quantity DESC;

-- 6.4 LIST FILTERING
-- IN: Matches any value in the list
SELECT DISTINCT ship_mode FROM orders
WHERE ship_mode IN ('First Class','Same Day');

SELECT * FROM orders
WHERE quantity IN (3, 5, 4)
ORDER BY quantity DESC;

-- NOT IN: Excludes values in the list
SELECT DISTINCT ship_mode FROM orders
WHERE ship_mode NOT IN ('First Class','Same Day');

-- 6.5 LOGICAL OPERATORS
-- AND: Both conditions must be true (reduces rows)
SELECT order_date, ship_mode, segment FROM orders
WHERE ship_mode = 'First Class' AND segment = 'Consumer';

-- OR: Either condition can be true (increases rows)
SELECT order_date, ship_mode, segment FROM orders
WHERE ship_mode = 'First Class' OR segment = 'Consumer';



/*
"NOT IN" , "IN" used when we want different values from row. but within SAME COLUMN. 
but
"AND" , "OR" is used when we want to different values of row. but DIFFERENT COLUMNS. 

Example :

let's say ship_mode  column has a only four type of value ( 'First', 'Second', 'Third' , 'Fourth') and we want only First and Third
QUERY : where ship_mode in ('First' , 'Third');
BUT
let's say i want ship_mode = 'First' and segment = 'Consumer' here segment and ship_mode is two different column then i will use "AND" "OR" condition
QUERY : where ship_mode 'First' OR segment = 'Sales Man');

*/

-- Complex conditions
SELECT * FROM orders 
WHERE quantity > 5 AND order_date < '2020-11-08';

-- 6.6 PATTERN MATCHING WITH LIKE
-- LIKE operator with wildcards for text patterns

-- % = Zero or more characters
-- _ = Exactly one character

-- Names starting with 'Chris'
SELECT order_id, order_date, customer_name
FROM orders
WHERE customer_name LIKE 'Chris%';

-- Names ending with 't'
SELECT order_id, order_date, customer_name
FROM orders
WHERE customer_name LIKE '%t';

-- Names containing 'ven' anywhere
SELECT order_id, order_date, customer_name
FROM orders
WHERE customer_name LIKE '%ven%';

-- Case-Sensitive pattern matching
SELECT order_id, order_date, customer_name
FROM orders
WHERE customer_name LIKE 'A%a';

-- Case-insensitive pattern matching using UPPER()
SELECT order_id, order_date, customer_name, UPPER(customer_name) as name_upper
FROM orders
WHERE UPPER(customer_name) LIKE 'A%A';

-- Single character wildcard: Names with 'l' as second letter
SELECT order_id, order_date, customer_name
FROM orders
WHERE customer_name LIKE '_l%';

-- PostgreSQL Pattern Matching (✓ Different from SQL Server):
-- PostgreSQL uses SIMILAR TO or ~ for advanced patterns ✓
-- Character classes work differently in PostgreSQL ✓

-- Simple patterns: Use LIKE with % and _
-- Character classes: Use ~ (regex) or SIMILAR TO
-- Complex patterns: Use ~ (regex)

-- QUERY 1: Using REGEX (~ operator) - CORRECT SYNTAX ✅
-- Purpose: Find customers whose name starts with 'C' but the second letter is NOT 'a', 'l', 'b', or 'o'
-- Example matches: "Christine", "Clark", "Curtis" 
-- Example non-matches: "Claire", "Carlos", "Corey"
SELECT order_id, order_date, customer_name
FROM orders
WHERE customer_name ~ '^C[^albo].*'
ORDER BY customer_name;


-- Purpose: Find customers whose name starts with 'C' followed by 'a', 'l', 'b', or 'o'
-- Example matches: "Claire", "Carlos", "Corey", "Clinton"
SELECT order_id, order_date, customer_name
FROM orders
WHERE customer_name ~ '^C[albo].*'
ORDER BY customer_name;


-- Purpose: Find order IDs starting with 'CA-20' followed by any character, then 1 or 2
-- Example matches: "CA-2021-123456", "CA-2012-789012"
SELECT order_id, order_date, customer_name
FROM orders
WHERE order_id ~ '^CA-20.[1-2]'
ORDER BY customer_name;

--like aobve similar
SELECT order_id, order_date, customer_name
FROM orders
WHERE order_id ~ '^CA-20.[1-2]..[3-4]'
ORDER BY customer_name;


-- Find orders from 2020 using regex
SELECT order_id, order_date, customer_name
FROM orders
WHERE order_id ~ '^CA-2020-'
ORDER BY order_date
LIMIT 10;


-- Find 2020 orders using regex  
SELECT order_id FROM orders WHERE order_id ~ '^CA-2020-';

-- Find names with exactly 5 letters starting with 'C'
SELECT customer_name FROM orders WHERE customer_name ~ '^C.{4}$';

-- 6.7 NULL VALUE FILTERING
-- NULL represents missing or unknown data
SELECT * FROM orders
WHERE city IS NULL;        -- Finds records with missing city

-- To find the null value "= operator" will not give you correct result. 
SELECT * FROM orders
WHERE city = NULL;        

SELECT * FROM orders
WHERE city IS NOT NULL;    -- Finds records with city data

-- Important: Use IS NULL/IS NOT NULL, never use = NULL

-- ====================================================================
-- SECTION 7: CALCULATED FIELDS AND FUNCTIONS (PRIORITY 2)
-- ====================================================================

-- 7.1 ARITHMETIC OPERATIONS
-- Create calculated columns in SELECT
SELECT *,
       profit/sales AS ratio,              -- Division for ratio calculation
       profit*sales AS product,            -- Multiplication  
       NOW() AS current_timestamp          -- ✓ PostgreSQL uses NOW() instead of GETDATE()
FROM orders
WHERE order_date < '2022-11-01 12:00:00' AND '2022-11-01 12:40:00'
ORDER BY order_date;

-- ✓ PostgreSQL Date/Time Functions:
-- NOW() - Current timestamp
-- CURRENT_DATE - Current date only
-- CURRENT_TIME - Current time only
-- AGE(date1, date2) - Calculate age/difference ✓

-- ====================================================================
-- SECTION 8: AGGREGATE FUNCTIONS (PRIORITY 2)
-- ====================================================================

-- 8.1 BASIC AGGREGATE FUNCTIONS
-- Aggregate functions perform calculations on multiple rows

SELECT COUNT(*) AS cnt,                    -- Count all rows
       SUM(sales) AS total_sales,          -- Sum of all sales
       MAX(sales) AS max_sales,            -- Highest sales value
       MIN(profit) AS min_profit,          -- Lowest profit value
       AVG(profit) AS avg_profit           -- Average profit
FROM orders;

-- 8.2 COUNT VARIATIONS
SELECT COUNT(DISTINCT region),             -- Count unique regions
       COUNT(*),                           -- Count all rows
       COUNT(city),                        -- Count non-NULL cities
       SUM(sales)
FROM orders;

-- Important: COUNT(*) includes NULLs, COUNT(column) excludes NULLs

-- ====================================================================
-- SECTION 9: GROUP BY - GROUPING DATA (PRIORITY 3)
-- ====================================================================

-- 9.1 BASIC GROUPING
-- GROUP BY: Divides rows into groups for aggregate calculations
SELECT region, 
       COUNT(*) AS cnt,
       SUM(sales) AS total_sales,
       MAX(sales) AS max_sales,
       MIN(profit) AS min_profit,
       AVG(profit) AS avg_profit
FROM orders
GROUP BY region;

-- 9.2 MULTIPLE COLUMN GROUPING
-- Groups by combination of columns
SELECT region, category, SUM(sales) AS total_sales
FROM orders
GROUP BY region, category;  -- Must include all non-aggregate columns

-- 9.3 GROUP BY WITH WHERE (Filtering before grouping)
SELECT region, SUM(sales) AS total_sales
FROM orders
WHERE profit > 50                          -- Filter individual rows first
GROUP BY region
ORDER BY total_sales DESC
LIMIT 2;                                   -- ✓ PostgreSQL LIMIT syntax

-- 9.4 HAVING CLAUSE (Filtering after grouping)
-- HAVING: Filters groups based on aggregate conditions
SELECT sub_category, SUM(sales) AS total_sales
FROM orders
GROUP BY sub_category
HAVING SUM(sales) > 100000                 -- Filter groups after aggregation
ORDER BY total_sales DESC;

-- Complex example with all clauses
SELECT sub_category, SUM(sales) AS total_sales
FROM orders
WHERE profit > 50                          -- 1. Filter individual rows
GROUP BY sub_category                      -- 2. Group remaining rows
HAVING SUM(sales) > 100000                -- 3. Filter groups
ORDER BY total_sales DESC                 -- 4. Sort results
LIMIT 5;                                  -- 5. Limit output ✓

-- 9.5 HAVING WITH DATE CONDITIONS
-- Filter groups based on date aggregates
SELECT sub_category, 
       MIN(order_date) AS first_order,
       MAX(order_date) AS last_order,
       SUM(sales) AS total_sales
FROM orders
GROUP BY sub_category
HAVING MAX(order_date) > '2020-01-01'     -- Only groups with recent orders
ORDER BY total_sales DESC;

-- Alternative approach using WHERE (more efficient)
SELECT sub_category, SUM(sales) AS total_sales
FROM orders
WHERE order_date > '2020-01-01'           -- Filter before grouping
GROUP BY sub_category
ORDER BY total_sales DESC;

-- ====================================================================
-- SECTION 10: JOINS - COMBINING TABLES (PRIORITY 4)
-- ====================================================================

-- 10.1 INNER JOIN
-- Returns only matching records from both tables
SELECT o.order_id, o.product_id, r.return_reason
FROM orders o
INNER JOIN returns r ON o.order_id = r.order_id;

-- 10.2 LEFT JOIN (LEFT OUTER JOIN)
-- Returns all records from left table, matching from right
SELECT o.order_id, o.product_id, r.return_reason, r.order_id AS return_order_id
FROM orders o
LEFT JOIN returns r ON o.order_id = r.order_id;

-- 10.3 RIGHT JOIN (RIGHT OUTER JOIN) ✓
-- Returns all records from right table, matching from left
SELECT e.emp_id, e.emp_name, e.dept_id, d.dep_id, d.dep_name 
FROM employee e
RIGHT JOIN dept d ON e.dept_id = d.dep_id;

-- 10.4 FULL OUTER JOIN ✓
-- Returns all records from both tables
SELECT e.emp_id, e.emp_name, e.dept_id, d.dep_id, d.dep_name 
FROM dept d
FULL OUTER JOIN employee e ON e.dept_id = d.dep_id;

-- 10.5 MULTIPLE JOINS
-- Join three tables together
SELECT o.order_id, o.product_id, r.return_reason, p.manager
FROM orders o
LEFT JOIN returns r ON o.order_id = r.order_id
INNER JOIN people p ON o.region = p.region;

-- 10.6 JOIN WITH AGGREGATION
-- Combine joins with GROUP BY
SELECT r.return_reason, SUM(sales) AS total_sales
FROM orders o
INNER JOIN returns r ON o.order_id = r.order_id
GROUP BY r.return_reason;

-- 10. 7 CROSS JOIN
-- Cross Join Example (creates Cartesian product - usually not what you want)
-- What it does: Creates every possible combination of employees with departments (usually produces too many rows)
SELECT e.emp_id, e.emp_name, d.dep_name
FROM employee e
CROSS JOIN dept d;


/* 
emp_id | emp_name
-------|----------
1      | John
2      | Sarah  
3      | Mike

dep_id | dep_name
-------|----------
10     | Sales
20     | IT

SELECT e.emp_id, e.emp_name, d.dep_name
FROM employee e
CROSS JOIN dept d;


cross join result : 

emp_id | emp_name | dep_name
-------|----------|----------
1      | John     | Sales
1      | John     | IT
2      | Sarah    | Sales
2      | Sarah    | IT
3      | Mike     | Sales
3      | Mike     | IT

*/


-- ====================================================================
-- SECTION 11: ADVANCED TOPICS (PRIORITY 5) ✓
-- ====================================================================

-- 11.1 SUBQUERIES ✓
-- Query within another query
SELECT * FROM orders 
WHERE sales > (SELECT AVG(sales) FROM orders);

-- Correlated subquery ✓
SELECT order_id, sales,
       (SELECT AVG(sales) FROM orders o2 WHERE o2.region = o1.region) AS region_avg
FROM orders o1;

-- 11.2 WINDOW FUNCTIONS ✓
-- Perform calculations across related rows
SELECT order_id, sales,
       ROW_NUMBER() OVER (ORDER BY sales DESC) AS sales_rank,
       RANK() OVER (PARTITION BY region ORDER BY sales DESC) AS region_rank,
       SUM(sales) OVER (PARTITION BY region) AS region_total
FROM orders;

-- 11.3 COMMON TABLE EXPRESSIONS (CTE) ✓
-- Temporary named result sets
WITH sales_summary AS (
    SELECT region, SUM(sales) AS total_sales
    FROM orders
    GROUP BY region
)
SELECT * FROM sales_summary
WHERE total_sales > 100000;

-- 11.4 CASE STATEMENTS ✓
-- Conditional logic in SELECT
SELECT order_id, sales,
       CASE 
           WHEN sales > 1000 THEN 'High'
           WHEN sales > 500 THEN 'Medium'
           ELSE 'Low'
       END AS sales_category
FROM orders;

-- 11.5 UNION OPERATIONS ✓
-- Combine results from multiple queries
SELECT region, 'Sales' AS metric, SUM(sales) AS value
FROM orders GROUP BY region
UNION ALL
SELECT region, 'Profit' AS metric, SUM(profit) AS value
FROM orders GROUP BY region;

-- 11.6 STRING FUNCTIONS ✓
-- PostgreSQL specific string functions
SELECT customer_name,
       LENGTH(customer_name) AS name_length,
       UPPER(customer_name) AS uppercase,
       LOWER(customer_name) AS lowercase,
       SUBSTRING(customer_name FROM 1 FOR 3) AS first_three,
       POSITION('a' IN LOWER(customer_name)) AS first_a_position
FROM orders;

-- 11.7 DATE FUNCTIONS ✓
-- PostgreSQL date/time manipulation
SELECT order_date,
       EXTRACT(YEAR FROM order_date) AS order_year,
       EXTRACT(MONTH FROM order_date) AS order_month,
       EXTRACT(DOW FROM order_date) AS day_of_week,  -- 0=Sunday
       order_date + INTERVAL '30 days' AS thirty_days_later,
       AGE(CURRENT_DATE, order_date) AS days_since_order
FROM orders;

-- 11.8 INDEXES ✓
-- Improve query performance
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_region_category ON orders(region, category);
-- DROP INDEX idx_orders_date;  -- Remove index when not needed

-- 11.9 VIEWS ✓
-- Virtual tables based on queries
CREATE VIEW high_value_orders AS
SELECT * FROM orders 
WHERE sales > 1000;

-- Query the view like a table
SELECT * FROM high_value_orders WHERE region = 'West';

-- 11.10 TRANSACTIONS ✓
-- Ensure data consistency
BEGIN;  -- Start transaction
    UPDATE orders SET sales = sales * 1.1 WHERE region = 'West';
    INSERT INTO audit_log VALUES (NOW(), 'Price increase applied');
COMMIT;  -- Save changes

-- Or rollback if there's an issue
BEGIN;
    DELETE FROM orders WHERE region = 'West';
    -- ROLLBACK;  -- Undo changes

-- ====================================================================
-- SECTION 12: POSTGRESQL SPECIFIC FEATURES ✓
-- ====================================================================

-- 12.1 ARRAYS ✓
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    tags TEXT[]  -- Array of text values
);

INSERT INTO products VALUES (1, 'Laptop', ARRAY['electronics', 'computers']);
SELECT * FROM products WHERE 'electronics' = ANY(tags);

-- 12.2 JSON DATA ✓
CREATE TABLE orders_json (
    id SERIAL PRIMARY KEY,
    order_data JSONB  -- Binary JSON for better performance
);

INSERT INTO orders_json VALUES (1, '{"customer": "John", "items": ["laptop", "mouse"]}');
SELECT order_data->>'customer' AS customer_name FROM orders_json;

-- 12.3 GENERATE_SERIES ✓
-- Create sequences of numbers or dates
SELECT * FROM GENERATE_SERIES(1, 10);  -- Numbers 1 to 10
SELECT * FROM GENERATE_SERIES('2023-01-01'::DATE, '2023-01-07'::DATE, '1 day');

-- ====================================================================
-- SECTION 13: SAMPLE DATA SETUP ✓
-- ====================================================================

-- Create sample tables for practice
CREATE TABLE people (
    manager VARCHAR(20),
    region VARCHAR(10)
);

INSERT INTO people VALUES 
('Ankit','West'),
('Deepak','East'),
('Vishal','Central'),
('Sanjay','South');

-- Create returns table for join examples
CREATE TABLE returns (
    order_id VARCHAR(10),
    return_reason VARCHAR(20)
);

-- Create employee and department tables for join practice ✓
CREATE TABLE dept (
    dep_id INTEGER PRIMARY KEY,
    dep_name VARCHAR(50)
);

CREATE TABLE employee (
    emp_id INTEGER PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INTEGER,
    FOREIGN KEY (dept_id) REFERENCES dept(dep_id)
);

-- ====================================================================
-- SECTION 14: BEST PRACTICES AND TIPS ✓
-- ====================================================================

/*
POSTGRESQL COMPATIBILITY NOTES ✓:
1. Use LIMIT instead of TOP for row limiting
2. Use NOW() instead of GETDATE() for current timestamp
3. Use SERIAL for auto-incrementing integers
4. Use TEXT for unlimited text (no need to specify length)
5. Use TIMESTAMP instead of DATETIME
6. Use BOOLEAN for true/false values
7. Pattern matching with LIKE works similarly, but advanced patterns differ
8. Use POSITION() instead of CHARINDEX() for finding substring positions
9. Use SUBSTRING(text FROM start FOR length) syntax
10. PostgreSQL is case-sensitive for object names when quoted

PERFORMANCE TIPS ✓:
1. Always use WHERE clause when possible to limit data
2. Create indexes on frequently queried columns
3. Use LIMIT to restrict large result sets
4. Prefer WHERE over HAVING when filtering individual rows
5. Use appropriate data types (don't use TEXT for short strings)
6. Use EXPLAIN ANALYZE to understand query performance

COMMON MISTAKES TO AVOID ✓:
1. Forgetting WHERE clause in UPDATE/DELETE (affects all rows!)
2. Using SELECT * in production code (specify columns needed)
3. Not handling NULL values properly (use IS NULL, not = NULL)
4. Mixing aggregate and non-aggregate columns without GROUP BY
5. Using HAVING instead of WHERE for row-level filtering
6. Not using transactions for related operations
*/

-- ====================================================================
-- END OF POSTGRESQL LEARNING GUIDE
-- ====================================================================
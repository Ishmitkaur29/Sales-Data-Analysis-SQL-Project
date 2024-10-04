--Creating database if it doesn't already exists
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'walmart')
BEGIN
    EXEC('CREATE DATABASE walmart');
END

USE walmart;
CREATE TABLE sales(
    invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    --branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    vat FLOAT(6) NOT NULL,  -- FLOAT does not support precision like decimal
    total DECIMAL(12, 4) NOT NULL,
    sale_date DATETIME NOT NULL,  -- "date" is a reserved keyword in SQL Server
    sale_time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10, 2) NOT NULL,
    gross_margin_pct FLOAT(53),  -- FLOAT uses precision for its size (53 is standard)
    gross_income DECIMAL(12, 4),
    rating FLOAT(2)  -- You don't need precision for FLOAT types
);

BULK INSERT sales
FROM 'C:\Users\admin\Desktop\Practice Data\SQL Server\WALMART SALES\Walmart Sales Data.csv.csv'
WITH (
    FIELDTERMINATOR = ',',  -- Column delimiter
    ROWTERMINATOR = '\n'   -- Row delimiter
);
--ALTER TABLE sales
--ALTER COLUMN branch VARCHAR(50);  -- Increase the size as needed

ALTER TABLE sales
ALTER COLUMN unit_price DECIMAL(12, 4);  -- Adjust precision if necessary


--creating staging table


CREATE TABLE sales_staging (
    invoice_id VARCHAR(30),
    --branch VARCHAR(5),
    city VARCHAR(30),
    customer_type VARCHAR(30),
    gender VARCHAR(10),
    product_line VARCHAR(100),
    unit_price VARCHAR(30),  -- Temporarily use VARCHAR to capture any value
    quantity VARCHAR(30),     -- Temporarily use VARCHAR to capture any value
    vat VARCHAR(30),          -- Temporarily use VARCHAR to capture any value
    total VARCHAR(30),        -- Temporarily use VARCHAR to capture any value
    sale_date VARCHAR(30),    -- Temporarily use VARCHAR to capture any value
    sale_time VARCHAR(30),    -- Temporarily use VARCHAR to capture any value
    payment VARCHAR(15),
    cogs VARCHAR(30),         -- Temporarily use VARCHAR to capture any value
    gross_margin_pct VARCHAR(30),  -- Temporarily use VARCHAR to capture any value
    gross_income VARCHAR(30),  -- Temporarily use VARCHAR to capture any value
    rating VARCHAR(30)        -- Temporarily use VARCHAR to capture any value
);

--ALTER TABLE sales
--ALTER COLUMN branch CHAR(10); 

DROP TABLE sales_staging;

select * from sales;

------------------- Feature Engineering -----------------------------
--1. Time_of_day

SELECT 
    sale_time,
    CASE 
        WHEN CAST(sale_time AS TIME) BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN CAST(sale_time AS TIME) BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening' 
    END AS time_of_day
FROM sales;


ALTER TABLE sales ADD time_of_day VARCHAR(20);

UPDATE sales
SET time_of_day = (
    CASE 
        WHEN CAST(sale_time AS TIME) BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN CAST(sale_time AS TIME) BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening' 
    END
);

SELECT * FROM sales;

--2.Day_name

SELECT sale_date,
DATENAME(weekday, sale_date) AS day_name
FROM sales;

ALTER TABLE sales ADD day_name VARCHAR(10);

UPDATE sales
SET day_name = DATENAME(weekday, sale_date);

SELECT * FROM sales;

--3.Momth_name

SELECT sale_date,
MONTH(sale_date) AS month_name
FROM sales;

ALTER TABLE sales ADD month_name VARCHAR(10);

UPDATE sales
SET month_name = MONTH(sale_date);

SELECT * FROM sales;


----------------Exploratory Data Analysis (EDA)----------------------
--Generic Questions
-- 1.How many distinct cities are present in the dataset?
SELECT DISTINCT city FROM sales;

-- 2.In which city is each branch situated?
SELECT DISTINCT branch, city FROM sales;

--Product Analysis
-- 1.How many distinct product lines are there in the dataset?
SELECT COUNT(DISTINCT product_line) AS unique_productline FROM sales;

-- 2.What is the most common payment method?
SELECT TOP 1 payment, COUNT(payment) AS common_payment_method 
FROM sales GROUP BY payment ORDER BY common_payment_method DESC;

-- 3.What is the most selling product line?
SELECT TOP 1 product_line, count(product_Line) AS most_selling_product
FROM sales GROUP BY product_line ORDER BY most_selling_product DESC;

-- 4.What is the total revenue by month?
SELECT month_name, SUM(total) AS total_revenue
FROM SALES GROUP BY month_name ORDER BY total_revenue DESC;

-- 5.Which month recorded the highest Cost of Goods Sold (COGS)?
SELECT month_name, SUM(cogs) AS total_cogs
FROM sales GROUP BY month_name ORDER BY total_cogs DESC;

-- 6.Which product line generated the highest revenue?
SELECT TOP 1 product_line, SUM(total) AS total_revenue
FROM sales GROUP BY product_line ORDER BY total_revenue DESC;

-- 7.Which city has the highest revenue?
SELECT TOP 1 city, SUM(total) AS total_revenue
FROM sales GROUP BY city ORDER BY total_revenue DESC;

-- 8.Which product line incurred the highest VAT?
SELECT TOP 1 product_line, SUM(vat) as VAT 
FROM sales GROUP BY product_line ORDER BY VAT DESC;

-- 9.Retrieve each product line and add a column product_category, indicating 'Good' or 'Bad,'based on whether its sales are above the average.

ALTER TABLE sales ADD product_category VARCHAR(80);

UPDATE sales 
SET product_category= 
(CASE 
	WHEN total >= (SELECT AVG(total) FROM sales) THEN 'Good'
    ELSE 'Bad'
END)FROM sales;

SELECT * FROM sales;

-- 10.Which branch sold more products than average product sold?
SELECT TOP 1 branch, SUM(quantity) AS quantity
FROM sales GROUP BY branch HAVING SUM(quantity) > AVG(quantity) ORDER BY quantity DESC;

-- 11.What is the most common product line by gender?
SELECT gender, product_line, COUNT(gender) AS total_count
FROM sales GROUP BY gender, product_line ORDER BY total_count DESC;

-- 12.What is the average rating of each product line?
SELECT product_line, ROUND(AVG(rating),2) AS average_rating
FROM sales GROUP BY product_line ORDER BY average_rating DESC;


--Sales Analysis
-- 1.Number of sales made in each time of the day per weekday
SELECT day_name, time_of_day, COUNT(invoice_id) AS total_sales
FROM sales GROUP BY day_name, time_of_day HAVING day_name NOT IN ('Sunday','Saturday');

SELECT day_name, time_of_day, COUNT(*) AS total_sales
FROM sales WHERE day_name NOT IN ('Saturday','Sunday') GROUP BY day_name, time_of_day;

-- 2.Identify the customer type that generates the highest revenue.
SELECT TOP 1 customer_type, SUM(total) AS total_sales
FROM sales GROUP BY customer_type ORDER BY total_sales DESC;

-- 3.Which city has the largest tax percent/ VAT (Value Added Tax)?
SELECT TOP 1 city, SUM(VAT) AS total_VAT
FROM sales GROUP BY city ORDER BY total_VAT DESC;

-- 4.Which customer type pays the most in VAT?
SELECT TOP 1 customer_type, SUM(VAT) AS total_VAT
FROM sales GROUP BY customer_type ORDER BY total_VAT DESC;

--Customer Analysis

-- 1.How many unique customer types does the data have?
SELECT COUNT(DISTINCT customer_type) AS total_custtype FROM sales;

-- 2.How many unique payment methods does the data have?
SELECT COUNT(DISTINCT payment) AS total_pay FROM sales;

-- 3.Which is the most common customer type?
SELECT TOP 1 customer_type, COUNT(customer_type) AS common_customer
FROM sales GROUP BY customer_type ORDER BY common_customer DESC;

-- 4.Which customer type buys the most?
SELECT TOP 1 customer_type, SUM(total) as total_sales
FROM sales GROUP BY customer_type ORDER BY total_sales;

SELECT TOP 1 customer_type, COUNT(*) AS most_buyer
FROM sales GROUP BY customer_type ORDER BY most_buyer DESC;

-- 5.What is the gender of most of the customers?
SELECT TOP 1 gender, COUNT(*) AS all_genders 
FROM sales GROUP BY gender ORDER BY all_genders DESC;

-- 6.What is the gender distribution per branch?
SELECT branch, gender, COUNT(gender) AS gender_distribution
FROM sales GROUP BY branch, gender ORDER BY branch;

-- 7.Which time of the day do customers give most ratings?
SELECT TOP 1 time_of_day, AVG(rating) AS average_rating
FROM sales GROUP BY time_of_day ORDER BY average_rating DESC;

-- 8.Which time of the day do customers give most ratings per branch?
SELECT branch, time_of_day, AVG(rating) AS average_rating
FROM sales GROUP BY branch, time_of_day ORDER BY average_rating DESC;

SELECT branch, time_of_day,
AVG(rating) OVER(PARTITION BY branch) AS ratings
FROM sales GROUP BY branch, time_of_day, rating;

-- 9.Which day of the week has the best avg ratings?
SELECT TOP 1 day_name, AVG(rating) AS average_rating
FROM sales GROUP BY day_name ORDER BY average_rating DESC;

-- 10.Which day of the week has the best average ratings per branch?
SELECT  branch, day_name, AVG(rating) AS average_rating
FROM sales GROUP BY day_name, branch ORDER BY average_rating DESC;

SELECT  branch, day_name,
AVG(rating) OVER(PARTITION BY branch) AS rating
FROM sales GROUP BY branch, day_name, rating ORDER BY rating DESC;


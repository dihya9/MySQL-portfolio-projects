
-- The dataset is about sales for differnent years (2003-2004-2005) of differnent transportation means (cars, planes, ..), and contains informations about orders, productlines with their respective products, countries, ..  

SHOW DATABASES;

SELECT DATABASE();

USE portfolio_project;


-- Importing the table 'Sales'

DELETE FROM sales;

LOAD DATA LOCAL INFILE '/home/dyhia/Téléchargements/Datasetss/SQL_pp/sales1.csv' INTO TABLE sales
COLUMNS TERMINATED BY ',' IGNORE 1 LINES;


-- table 'Sales' columns:

SELECT * FROM sales;


-- --------------------------------------------------------------------------------------------------------------------
# General informations about the dataset 
-- --------------------------------------------------------------------------------------------------------------------

# 1- Categories of products that were sold 


SELECT DISTINCT(PRODUCTLINE) AS productline FROM sales;

-- We have 7 categories of products (productlines) 


# 2- How many types of products per product line do we have 


SELECT PRODUCTLINE AS productline, COUNT(DISTINCT(PRODUCTCODE)) AS number_of_products 
FROM sales
GROUP BY PRODUCTLINE
ORDER BY 2 DESC;                            -- We use distinct otherwise it counts every occurence of the same product rather than just counting it once 

-- Classic cars contains offers the biggest number of products (37 products).
-- On the other hand, the 'trains' productline offers the least number of product (3 products)


# 3- Did the number of products available change through the year ? 


SELECT YEAR_ID AS years, PRODUCTLINE AS productline, COUNT(DISTINCT(PRODUCTCODE)) AS number_of_products 
FROM sales
GROUP BY years, productline
ORDER BY 3 DESC; 

-- The number of available products hasn't changed in three years. 


-- ----------------------------------------------------------------------------------------------------------------------
# Summaries
-- --------------------------------------------------------------------------------------------------------------------

# 4- Summary table for the total sales, total quantities ordered, and total orders 


-- a) Per year 

CREATE VIEW view3 
AS 
SELECT YEAR_ID AS years, 
CAST(SUM(SALES) AS DECIMAL(9,2)) AS total_sales,
SUM(QUANTITYORDERED) AS total_quantities, 
COUNT(DISTINCT ORDERNUMBER) AS total_orders 
FROM sales
GROUP BY years;

SELECT * FROM view3;


-- b) By month per year 


CREATE VIEW view4 
AS 
SELECT YEAR_ID AS years, MONTH_ID AS months,CAST(SUM(SALES) AS DECIMAL(9,2)) AS sales_month,
SUM(QUANTITYORDERED) AS quantities_month, COUNT(DISTINCT ORDERNUMBER) AS orders_month
FROM sales
GROUP BY years, months;

SELECT * FROM view4;

SELECT *, 
SUM(sales_month) OVER (PARTITION BY years) AS year_sales,
SUM(quantities_month) OVER (PARTITION BY years) AS year_quantities,
SUM(orders_month) OVER (PARTITION BY years) AS year_orders
FROM view4
ORDER BY 1, 2;


# 5- Global summary of the the sales, quantities ordered, and oreders numbers for the three years (totals + averages) 


SELECT SUM(total_sales) AS gloabl_sales, SUM(total_quantities) AS global_quantities, SUM(total_orders) AS global_orders, 
CAST(AVG(total_sales) AS DECIMAL(9,2)) AS avg_year_sales, 
CAST(AVG(total_quantities) AS DECIMAL(9,2)) AS avg_year_quantities,
CAST(AVG(total_orders) AS DECIMAL(9,2)) AS avg_year_oredrs
FROM view3; 


-- ----------------------------------------------------------------------------------------------------------
# Products + Productline 
-- --------------------------------------------------------------------------------------------------------------------

# 6- Gloabl sales per productline for all years


SELECT PRODUCTLINE AS productline, SUM(CAST(SALES AS DECIMAL(9,2))) AS Total_sales
FROM sales
GROUP BY productline
ORDER BY 2 DESC;


# 7- Total sales, highest sale, quantities orders, and orders per productline per year 


SELECT YEAR_ID AS years, PRODUCTLINE AS productline, 
SUM(CAST(SALES AS DECIMAL(9,2))) AS Total_sales, 
MAX(SALES) AS highest_sale, 
SUM(QUANTITYORDERED) AS sold_quantity, 
SUM(DISTINCT ORDERNUMBER) AS total_orders
FROM sales
GROUP BY years, productline
ORDER BY 1, 2, 3; 


-- For March 2004


SELECT YEAR_ID AS years, MONTH_ID AS months, PRODUCTLINE AS productline, 
SUM(CAST(SALES AS DECIMAL(9,2))) AS Total_sales, 
MAX(SALES) AS highest_sale, 
SUM(QUANTITYORDERED) AS sold_quantity 
FROM sales
WHERE years=2004 AND months=3
GROUP BY productline
ORDER BY 4 DESC; 


# 8- Number of sold products per productline for each productcode 


SELECT PRODUCTLINE AS productline, PRODUCTCODE AS product, COUNT(PRODUCTCODE) AS quantity 
FROM sales
group by productline, product
ORDER BY 1, 3 DESC; 


# 9- Total quantity sold per product per year 


CREATE VIEW view_name 
AS
SELECT YEAR_ID AS years, PRODUCTCODE AS product, SUM(QUANTITYORDERED) AS quantity 
FROM sales
GROUP BY years, product
ORDER BY 1,3 DESC;  


-- For the products S12_1666 and S18_1662


SELECT * FROM view_name
WHERE product IN ('S12_1666', 'S18_1662')
ORDER BY 1,3 DESC; 


# 10- What is the global number of quantities sold for all productlines for 2003 in january, juin, and december (sub-query) 


SELECT YEAR_ID AS years, MONTH_ID AS months, PRODUCTLINE AS productline, 
SUM(quantity) OVER (ORDER BY PRODUCTLINE) AS total_products_quantity
FROM  
(SELECT YEAR_ID, MONTH_ID, PRODUCTLINE, SUM(QUANTITYORDERED) AS quantity 
FROM sales 
WHERE YEAR_ID=2003 AND MONTH_ID IN (1, 6, 12)
GROUP BY YEAR_ID, MONTH_ID, PRODUCTLINE
) as tab 
ORDER BY 2;


# 11- Most expensive product


WITH cte AS
(SELECT PRODUCTLINE AS productline, PRODUCTCODE AS product, MAX(PRICEEACH) AS price
FROM sales
GROUP BY productline, product
ORDER BY 1,3)

SELECT * , FIRST_VALUE(product) OVER (PARTITION BY productline ORDER BY price DESC)  AS most_expensive_product
FROM cte;


# 12- Most sold product per productline for november 2004


-- a) Using FIRST_VALUE()


WITH cte AS
(SELECT YEAR_ID AS years, PRODUCTLINE AS productline, PRODUCTCODE AS product, 
COUNT(PRODUCTCODE) AS quantity
FROM sales
GROUP BY yeas, productline, product)

SELECT * , FIRST_VALUE(product) OVER (PARTITION BY productline ORDER BY quantity DESC) AS max_ordered
FROM cte
ORDER BY 1, 2, 4;


-- b) Using LAST_VALUE() but for specifically the month of november 2004


WITH cte AS
(SELECT YEAR_ID AS years, MONTH_ID AS months, PRODUCTLINE AS productline, PRODUCTCODE AS product, COUNT(PRODUCTCODE) AS quantity
FROM sales
WHERE (YEAR_ID=2004 AND MONTH_ID=11)
GROUP BY productline, productcode
ORDER BY 1,3)

SELECT * , LAST_VALUE(product) OVER (PARTITION BY productline ORDER BY quantity 
RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS most_sold_product
FROM cte;

# 13- Least sold product per productline per year

WITH cte AS
(SELECT YEAR_ID AS years, PRODUCTLINE AS productline, PRODUCTCODE AS product, COUNT(PRODUCTCODE) AS quantity
FROM sales
GROUP BY years, productline, product)

SELECT * , LAST_VALUE(product) OVER (PARTITION BY productline ORDER BY quantity DESC
RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS max_ordered
FROM cte
ORDER BY 1, 2;


-- --------------------------------------------------------------------------------------------------------------------
# Orders
-- --------------------------------------------------------------------------------------------------------------------

# 14- Ordernumber with its orders and total of sales 


SELECT ORDERNUMBER AS ordernumber, PRODUCTCODE AS product, 
SUM(CAST(SALES AS DECIMAL(9,2))) OVER (PARTITION BY ORDERNUMBER RANGE BETWEEN UNBOUNDED PRECEDING AND
UNBOUNDED FOLLOWING) AS total
FROM sales
ORDER BY 3 DESC;


# 15- Order with the highest sale 


SELECT ORDERNUMBER AS ordernumber, CAST(SUM(SALES) AS DECIMAL(9,2)) AS total_sales_per_order
FROM sales
GROUP BY ordernumber
ORDER BY 2 DESC;


# 16- What is the 4th highest sales ordernumber 

 
WITH cte1 (years, ordernumber, product, total)
AS 
(SELECT YEAR_ID, ORDERNUMBER, PRODUCTCODE, SUM(CAST(SALES AS DECIMAL(9,2))) OVER (PARTITION BY ORDERNUMBER RANGE BETWEEN UNBOUNDED PRECEDING AND
UNBOUNDED FOLLOWING)
FROM sales
ORDER BY 4)
SELECT *, NTH_VALUE(ordernumber, 4) OVER (PARTITION BY years ORDER BY total RANGE BETWEEN UNBOUNDED PRECEDING AND
 UNBOUNDED FOLLOWING) AS fourth_order_sales
 FROM cte1
 ORDER BY 1, 4;


-- Or without PRODUCTCODE


WITH cte1 (years, ordernumber, total)
AS 
(SELECT YEAR_ID, ORDERNUMBER, SUM(CAST(SALES AS DECIMAL(9,2))) 
FROM sales
group by YEAR_ID, ORDERNUMBER)
SELECT *, NTH_VALUE(oredernumber, 4) OVER (PARTITION BY years ORDER BY total RANGE BETWEEN UNBOUNDED PRECEDING AND
 UNBOUNDED FOLLOWING) AS fourth_order_sales
 FROM cte1;
 
 
 -- For 2005 for january, march


WITH cte1 (years, months, ordernumber, product, total)
AS 
(SELECT YEAR_ID, MONTH_ID, ORDERNUMBER, PRODUCTCODE, 
SUM(CAST(SALES AS DECIMAL(9,2))) OVER (PARTITION BY ORDERNUMBER RANGE BETWEEN UNBOUNDED PRECEDING AND
UNBOUNDED FOLLOWING)
FROM sales
WHERE YEAR_ID=2005 AND MONTH_ID IN (1,3))
SELECT *, NTH_VALUE(ordernumber, 4) OVER (PARTITION BY years ORDER BY total RANGE BETWEEN UNBOUNDED PRECEDING AND
 UNBOUNDED FOLLOWING) AS fourth_order_sales
 FROM cte1
 ORDER BY 1, 2;
 
 
# 17-  details of the order 10159 country, orders, quantities, ..


SELECT ORDERNUMBER AS ordernumber, ORDERDATE AS order_date, PRODUCTLINE AS product, PRODUCTCODE, QUANTITYORDERED, SALES, 
SUM(CAST( SALES AS DECIMAL(9,2))) OVER () AS total_sales, COUNTRY AS country
FROM sales
WHERE ORDERNUMBER = '10159'
ORDER BY 3;


-- --------------------------------------------------------------------------------------------------------------------
# Some descriptive statistics 
-- --------------------------------------------------------------------------------------------------------------------

# 18- Highest solding month per year 


SELECT *, LAST_VALUE(months) OVER (PARTITION BY years ORDER BY total 
RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS highest_sales_month
FROM
(SELECT YEAR_ID AS years, MONTH_ID AS months, CAST(SUM(SALES) AS DECIMAL(9,2)) AS total
FROM sales
GROUP BY years, months) AS tab
ORDER BY 1,2;


# 19- Perecntages of productline share of orders and sales (JOIN + subquery)


SELECT tab.YEAR_ID AS years, PRODUCTLINE AS productline, 
CAST(all_sales AS DECIMAL(9,2)) AS all_sales, all_orders, 
CAST(productline_sales AS DECIMAL(9,2)) AS productline_sales, productline_orders,
CAST(productline_sales*100/all_sales AS DECIMAL(9,2)) AS share_sales, CAST(productline_orders*100/all_orders AS DECIMAL(9,2)) AS share_orders
FROM
(SELECT YEAR_ID, PRODUCTLINE, SUM(SALES) AS productline_sales, COUNT(DISTINCT ORDERNUMBER) AS productline_orders
FROM sales
GROUP BY YEAR_ID, PRODUCTLINE
ORDER BY 1, 2) tab
JOIN 
(SELECT YEAR_ID, SUM(SALES) AS all_sales, COUNT(DISTINCT ORDERNUMBER) AS all_orders
FROM sales GROUP BY YEAR_ID) tab2
ON tab.YEAR_ID = tab2.YEAR_ID; 


# 20- average sales  


-- a) Per year 


SELECT *, CAST(AVG(total) OVER (ORDER BY years RANGE BETWEEN UNBOUNDED PRECEDING AND
 UNBOUNDED FOLLOWING) AS DECIMAL(9,2)) AS average_sales_per_year
FROM 
(SELECT YEAR_ID AS years, CAST(SUM(SALES) AS DECIMAL(9,2)) AS total
FROM sales
GROUP BY years) AS tab;


-- b) Per month 


      -- a) Using subqueries only


SELECT cte2.years AS years, sales_month, orders_month, quantities_month, avg_sales, avg_orders, avg_quantities
FROM view4 JOIN 
(SELECT years, CAST(AVG(sales_month) AS DECIMAL(9,2)) AS avg_sales, 
CAST(AVG(orders_month) AS UNSIGNED) AS avg_orders, 
CAST(AVG( quantities_month) AS UNSIGNED) AS avg_quantities 
FROM view4
GROUP BY years) AS cte2
ON view4.years=cte2.years;


      -- b) Using ctes 


WITH 
cte2 AS 
(SELECT years, months, CAST(AVG(sales_month) OVER
(PARTITION BY years RANGE BETWEEN UNBOUNDED PRECEDING AND
UNBOUNDED FOLLOWING) AS DECIMAL(9,2)) AS avg_sales, 

CAST(AVG(orders_month) OVER (PARTITION BY years RANGE BETWEEN UNBOUNDED PRECEDING AND
UNBOUNDED FOLLOWING) AS UNSIGNED) AS avg_orders, 

CAST(AVG( quantities_month) OVER (PARTITION BY years RANGE BETWEEN UNBOUNDED PRECEDING AND
UNBOUNDED FOLLOWING) AS UNSIGNED) AS avg_quantities 
FROM view4)# PARTITION BY 

SELECT cte2.years, view4.months, sales_month, orders_month, 
quantities_month, avg_sales, avg_orders, avg_quantities
FROM view4 JOIN 
cte2 ON view4.years=cte2.years
AND view4.months=cte2.months;


    -- c) Using a TEMPORARY TABLE 


DROP TABLE avg_sales_year;

CREATE TEMPORARY TABLE avg_sales_year (
years INT UNSIGNED,
months INT UNSIGNED,
sales_month DECIMAL(9,2),
oredrs_month INT UNSIGNED,
quantities_month INT UNSIGNED,
avg_sales DECIMAL(9,2),
avg_orders INT UNSIGNED,
avg_quantities INT UNSIGNED
);
INSERT INTO avg_sales_year
SELECT view4.years, view4.months, sales_month, orders_month, quantities_month, avg_sales, avg_orders, avg_quantities
FROM 
(SELECT years, months, CAST(AVG(sales_month) OVER (PARTITION BY years RANGE BETWEEN UNBOUNDED PRECEDING AND
UNBOUNDED FOLLOWING) AS DECIMAL(9,2)) AS avg_sales, 
CAST(AVG(orders_month) OVER (PARTITION BY years RANGE BETWEEN UNBOUNDED PRECEDING AND
UNBOUNDED FOLLOWING) AS UNSIGNED) AS avg_orders, 
CAST(AVG( quantities_month) OVER (PARTITION BY years RANGE BETWEEN UNBOUNDED PRECEDING AND
UNBOUNDED FOLLOWING) AS UNSIGNED) AS avg_quantities 
FROM view4) AS tab2
JOIN 
view4 
ON tab2.years=view4.years
AND tab2.months=view4.months;

SELECT * FROM avg_sales_year ORDER BY years, months;


# 21- products sales that are less or more than the averag sales per year (use fct or procedure) or if or case


SELECT * FROM avg_sales_year
WHERE sales_month > avg_sales
AND oredrs_month > avg_orders
AND quantities_month > avg_quantities
ORDER BY years, months;


# 22- labeling months according to wether the sales made were higher or lower than the average month 


-- Labels are : Above average sales, Below average sales


SELECT *, 
CASE 
WHEN sales_month > avg_sales THEN 'Above average sales'
ELSE 'Below average sales' 
END  AS avg_comparision
FROM avg_sales_year;


# 23- CUME_DIST FOR PRODUCTS


WITH 
tab1 AS (SELECT YEAR_ID AS years, PRODUCTCODE AS product, SUM(SALES) as total
FROM sales 
WHERE years=2005 AND product='MOTORCYCLES'
GROUP BY product)

SELECT *, CAST(CUME_DIST() OVER (ORDER BY total DESC)*100 AS DECIMAL(9,2)) AS CUMULATIVE_DIST
FROM tab1;

-- PLUS DE 30% DU TOTAL DU CHIFFRE D'AFFAIRE DE CETTE GAMME DE PRODUIT A ÉTÉ RÉALISE PAR LES 3 PREMIERS PRD


-- --------------------------------------------------------------------------------------------------------------------
# Countries
-- --------------------------------------------------------------------------------------------------------------------

# 24- Summary for countries 


CREATE TEMPORARY TABLE country_totals
(SELECT YEAR_ID AS years, COUNTRY AS country, CAST(SUM(SALES) AS DECIMAL(9,2)) AS t_sales, 
SUM(QUANTITYORDERED) AS t_quantities, SUM(DISTINCT ORDERNUMBER) as t_orders 
FROM sales
GROUP BY years, country);


# 25- General ranking of the countries per year based on the total sales 


SELECT years, country, t_sales, ROW_NUMBER() OVER (PARTITION BY years ORDER BY t_sales) AS year_sales_ranking
FROM 
country_totals;


# 26- Country with the highest number of orders, sales, quantities orderd


SELECT *, FIRST_VALUE(country) OVER (ORDER BY t_sales DESC) AS highest_sales,  
FIRST_VALUE(country) OVER (ORDER BY t_quantities DESC) AS highest_quantities,
FIRST_VALUE(country) OVER (ORDER BY t_orders DESC) AS highest_orders
FROM country_totals
WHERE years=2005
ORDER BY 3 DESC;


# 27- Country with the least ones with cte 

 
WITH cte AS
(SELECT YEAR_ID AS years, COUNTRY AS country, SUM(SALES) AS total, 
SUM(QUANTITYORDERED) AS t_quantities, SUM(DISTINCT ORDERNUMBER) as t_orders 
FROM sales
WHERE years = '2005'
GROUP BY country
ORDER BY 2 DESC)
SELECT *, FIRST_VALUE(country) OVER (ORDER BY total ) AS highest_sales,  
FIRST_VALUE(country) OVER (ORDER BY t_quantities)  AS highest_quantities,
FIRST_VALUE(country) OVER (ORDER BY t_orders ) AS highest_orders
FROM cte;


# 28- NTILE for countries


WITH 

tab1 AS (SELECT years, country, t_sales 
FROM country_totals
WHERE years=2005),

tab2 AS (SELECT *, NTILE(5) OVER (ORDER BY t_sales DESC) AS sales_level
FROM tab1)

SELECT years, country, t_sales, 
CASE 
WHEN tab2.sales_level=1 THEN 'High sales level'
WHEN tab2.sales_level=2 THEN 'Medium sales level'
WHEN tab2.sales_level=3 THEN 'Acceptable sales level'
WHEN tab2.sales_level=4 THEN 'above low sales level'
WHEN tab2.sales_level=5 THEN 'Low sales level'
END AS sales_level
FROM tab2;

-- NTILES BUT WITH % OR CUME_DIST (TOP SALES, LOW SALES, ..) MAYBE WITH PRODUCTS


# 29- Percentages for countries (yearly too) 


WITH
cte2 AS
(SELECT YEAR_ID AS years, SUM(SALES) AS total_sales, 
SUM(DISTINCT ORDERNUMBER) AS total_orders, 
SUM(QUANTITYORDERED) AS total_quantities
FROM sales
GROUP BY YEAR_ID) 

SELECT cte2.years, country, 
CAST(t_sales*100/total_sales AS DECIMAL(9,2)) AS percent_sales, 
CAST(t_orders*100/total_orders AS DECIMAL(9,2)) AS percent_orders, 
CAST(t_quantities*100/total_quantities AS DECIMAL(9,2)) AS percent_quantities
FROM country_totals JOIN cte2 
ON country_totals.years = cte2.years;


# 30- percent rank for France 


WITH 
tab1 AS (SELECT years, country, t_sales
FROM country_totals
WHERE years=2005)

SELECT *, 
CAST(PERCENT_RANK() OVER (ORDER BY t_sales)*100 AS DECIMAL(9,2)) AS percent_ranking
FROM tab1;

-- France makes more sales than 87% of the countries


-- Using cumulative distribution


WITH 
tab1 AS (SELECT years, country, t_sales
FROM country_totals
WHERE years=2005)

SELECT *, CAST(CUME_DIST() OVER (ORDER BY t_sales DESC)*100 AS DECIMAL(9,2)) AS CUMULATIVE_DIST
FROM tab1;














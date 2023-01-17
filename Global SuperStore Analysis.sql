USE global_store;

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
	[Row ID] int,
    [Order ID] text,
    [Order Date] text,
    [Ship Date] text,
    [Ship Mode] text,
    [Customer ID] text,
    [Customer Name] text,
    [Segment] text,
    [City] text,
    [State] text,
    [Country] text,
    [Postal Code] text,
    [Market] text,
    [Region] text,
    [Product ID] text,
    [Category] text,
    [Sub-Category] text,
    [Product Name] text,
    [Sales] float,
    [Quantity] int,
    [Discount] float,
    [Profit] float,
    [Shipping Cost] float,
    [Order Priority] text
);
    
LOAD DATA LOCAL INFILE 'C:/Users/Administrator/Downloads/Global Superstore.xls - Orders.csv' 
INTO TABLE orders 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

show global variables like 'local_infile';
set global local_infile=true;

UPDATE orders
SET `order date` = DATE_FORMAT(STR_TO_DATE(`order date`,'%m/%d/%Y'),'%Y/%m/%d');

ALTER TABLE orders
ADD `Order Date1` date after `order date`;

UPDATE orders
SET `order date1` = `order date`;

ALTER TABLE orders
DROP `order date`;

UPDATE orders
SET `ship date` = DATE_FORMAT(STR_TO_DATE(`ship date`,'%m/%d/%Y'),'%Y/%m/%d');

ALTER TABLE orders
ADD `Ship Date1` date after `order date`;

UPDATE orders
SET `ship date1` = `ship date`;

ALTER TABLE orders
DROP `ship date`;

# Start of Analysis

SELECT * FROM orders;
SELECT * FROM returns;
SELECT * FROM people;

SELECT `order id`,count(*) FROM orders GROUP BY `order id`;

SELECT `customer id`,`customer name`,`order id`,count(`order id`) as num_of_items,ROUND(sum(`sales`),2) as amount FROM orders WHERE `customer name` = 'Rick Hansen' GROUP BY `order id`;

commit;

# Number of orders per year including returns
WITH total_order_date AS (SELECT `order date1`,`order id` FROM orders GROUP BY `order id`)
SELECT year(`order date1`) as year , count(*) as num_orders FROM total_order_date GROUP BY year(`order date1`);

#Number of Customers and their names
SELECT count(DISTINCT `customer name`) FROM orders;
SELECT `customer name` FROM orders GROUP BY `customer name` ORDER BY `customer name`; 

#Gross income for each month in each year , for each year and Total Gross income for each month in all years , for all years 
SELECT COALESCE(month,'TOTAL'),COALESCE(year,'TOTAL'),gross_income FROM
((SELECT COALESCE(EXTRACT(month from `order date1`),'TOTAL') as month , year(`order date1`) as year, SUM(sales) as gross_income FROM orders GROUP BY month,year with rollup ORDER BY month,year )
UNION 
(SELECT COALESCE(EXTRACT(month from `order date1`),'TOTAL') as month , year(`order date1`) as year, SUM(sales) as gross_income FROM orders GROUP BY year,month with rollup ORDER BY month,year ))t1 ORDER BY month ASC;

#Average Shipping Duration for each type of ship mode
SELECT * FROM (
SELECT AVG(DATEDIFF(`ship date1`,`order date1`)) as average_time FROM orders  WHERE `ship mode` = 'First Class' GROUP BY `ship mode` UNION
SELECT AVG(DATEDIFF(`ship date1`,`order date1`)) as average_time FROM orders  WHERE `ship mode` = 'Second Class' GROUP BY `ship mode` UNION
SELECT AVG(DATEDIFF(`ship date1`,`order date1`)) as average_time FROM orders  WHERE `ship mode` = 'Standard Class' GROUP BY `ship mode`) T1;

#Number of Orders per each Customer , Number of items per Customer

#COMBINED OUTPUT along with avg items / order
DROP TABLE IF EXISTS orders_1;

CREATE TABLE orders_1 as 
SELECT * FROM orders GROUP BY `order id`;

WITH combined_num_orders_items as (SELECT o.`customer name` AS `customer name`,count(o.`order id`) as num_orders,T1.num_items as num_items FROM orders_1 o JOIN(SELECT `customer name`,sum(quantity) as num_items FROM orders GROUP BY `customer name` ORDER BY num_items DESC)T1 ON T1.`customer name` = o.`customer name` GROUP BY `customer name` ORDER BY num_items DESC)
SELECT *,AVG(num_items/num_orders) as avg_items_order FROM combined_num_orders_items GROUP BY `customer name`;

#Individual Outputs
WITH total_orders_customer AS (SELECT * FROM orders WHERE `customer name` = `customer name` GROUP BY `order id`)
SELECT `customer name`,count(`order id`) as num_orders FROM total_orders_customer GROUP BY `customer name` ORDER BY num_orders DESC;
SELECT `customer name`,sum(quantity) as num_items FROM orders GROUP BY `customer name` ORDER BY num_items DESC;
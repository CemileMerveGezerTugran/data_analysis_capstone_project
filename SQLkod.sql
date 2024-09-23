----OVERWİEV----

---Brüt kazancı hesaplayalım;

SELECT ROUND(CAST(SUM(unit_price*quantity) AS numeric),2) AS gross_profit
FROM order_details;

---Net kazancı hesaplayalım;

SELECT ROUND((SUM((unit_price - unit_price * discount) * quantity))::numeric, 2) AS net_profit
FROM order_details;

---Toplam Discount hesaplayalım;

SELECT ROUND(CAST(SUM(unit_price*discount*quantity) AS numeric),2) AS total_discount
FROM order_details;

---Sipariş sayısına bakalım;

SELECT COUNT(*) AS total_orders FROM orders;

---Müşteri sayısına bakalım;

SELECT * FROM customers;
SELECT COUNT(*) AS count_customers FROM customers;

---Kategori Analizi

WITH category_analysis AS(
SELECT c.category_name, COUNT(od.order_id) AS order_count,
ROUND(SUM(od.unit_price*od.quantity*od.discount)::numeric,2) AS total_discount,
ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::numeric,2) AS net_profit,
ROUND(SUM(od.unit_price * od.quantity)::numeric,2) AS gross_profit
FROM categories AS c
JOIN products AS p ON p.category_id=c.category_id
JOIN order_details AS od ON od.product_id=p.product_id
JOIN orders AS o ON o.order_id=od.order_id
GROUP BY 1
ORDER BY 5 DESC
)
SELECT 
	category_name,
	order_count,
	gross_profit,
	net_profit,
	total_discount
FROM category_analysis 
ORDER BY 4 DESC

--Ay bazında net satışa bakalım;

SELECT
TO_CHAR(o.order_date, 'Month') AS month_name,
EXTRACT(MONTH FROM o.order_date) AS months,
ROUND(SUM(od.quantity * od.unit_price)::numeric, 2) AS total_price
FROM orders AS o
JOIN order_details AS od ON o.order_id = od.order_id
GROUP BY 1,2
ORDER BY 2 DESC;

---Ülkelere göre sipariş sayılarına bakalım;

SELECT c.country,
COUNT(o.order_id) AS total_orders
FROM customers AS c
JOIN orders AS  o ON c.customer_id = o.customer_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

---Ortalama kargo süresine bakalım;

WITH ShippingTime AS (
SELECT order_id, (shipped_date - order_date) AS ShippingTime
FROM orders
WHERE shipped_date IS NOT NULL AND order_date IS NOT NULL
)
SELECT ROUND(AVG(ShippingTime)::numeric,2) AS Avg_shipping_time
FROM ShippingTime;


---PRODUCTS---

---Product sayısına bakalım;

SELECT COUNT(*) AS total_products FROM products;

---Shipped orders;

SELECT * FROM orders;
SELECT COUNT(shipped_date) AS shipped_products FROM orders;

---Discointed products;

SELECT * FROM products;
SELECT COUNT(discontinued) FROM products
WHERE discontinued = 1


---En çok sipariş verilen ilk 5 ürüne bakalım;

SELECT p.product_name,COUNT(od.order_id) AS order_count
FROM order_details AS od
JOIN products AS p ON od.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

---En az sipariş verilen ilk 5 ürüne bakalım;

SELECT * FROM products;

SELECT p.product_name,COUNT(od.order_id) AS order_count
FROM order_details AS od
JOIN products AS p ON od.product_id = p.product_id
GROUP BY 1
ORDER BY 2 ASC
LIMIT 5;

--Ürünlerin toplam stok ve sipariş miktarına bakalım;

SELECT p.product_name, p.unit_in_stock, 
SUM(od.quantity) AS total_ordered_quantity
FROM order_details AS od
JOIN products AS p ON od.product_id = p.product_id
GROUP BY 1,2;


--Kategorilerin toplam stoğuna bakalım;

SELECT c.category_name, SUM(p.unit_in_stock) AS total_stock
FROM products AS p
JOIN categories AS c ON p.category_id = c.category_id
GROUP BY 1;

---CUSTOMERS---

---Ülke sayısına bakalım;

SELECT * FROM customers;

SELECT COUNT(DISTINCT(country)) AS count_country FROM customers;

---Şehir sayısına bakalım;

SELECT COUNT(DISTINCT(city)) AS count_city FROM customers;

---Müşteri ID'sine göre en çok sipariş veren müşterilere bakalım;

SELECT COUNT(DISTINCT(o.order_id)) AS total_orders, customer_id
FROM orders AS o
JOIN order_details AS od ON od.order_id=o.order_id
GROUP BY 2
ORDER BY 1 DESC;

SELECT COUNT(o.order_id) AS total_orders, customer_id
FROM orders AS o
JOIN order_details AS od ON od.order_id=o.order_id
GROUP BY 2
ORDER BY 1 DESC;

---Ülkelere göre sipariş sayılarına bakalım;

SELECT c.country,
COUNT(o.order_id) AS total_orders
FROM customers AS c
JOIN orders AS  o ON c.customer_id = o.customer_id
GROUP BY 1
ORDER BY 2 DESC;

---Müşterilerin ödediği kargo bedeline bakalım;

SELECT c.customer_id, c.company_name, c.country,
SUM(o.freight) AS total_freight
FROM customers AS c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 10;

---SHIPPING---

---NotShipped

SELECT COUNT(*) AS NotShipped
FROM orders
WHERE shipped_date IS NULL;

---Shippers

SELECT COUNT(DISTINCT(ship_via)) AS shippers
FROM orders;

---Toplam Navlun tutarına bakalım;

SELECT SUM(freight) AS total_freight FROM orders;

---Kargo firmalarının toplam maliyetine bakalım;

SELECT sp.company_name, COUNT(order_id) AS total_orders, ROUND(SUM(freight)::numeric,2) AS total_freight
FROM orders AS o
JOIN shippers AS sp ON o.ship_via=sp.shipper_id
GROUP BY 1
ORDER BY 3 DESC;

----Ülkelere teslim süresine bakalım;

WITH delivery_speed AS (
SELECT order_id, ship_country, (shipped_date - order_date) AS shipping_time
FROM orders
WHERE shipped_date IS NOT NULL AND order_date IS NOT NULL
)
SELECT ship_country, ROUND(AVG(shipping_time)::numeric,2) AS Avg_shipping_time
FROM delivery_speed
GROUP BY 1
ORDER BY 2 DESC;

---Kaç ürün zamanında teslim edildi, geç teslim edildi ve gönderilmedi?

SELECT s.company_name,
COUNT(CASE WHEN o.shipped_date IS NULL THEN 1 END) AS Not_Shipped,
COUNT(CASE WHEN o.shipped_date <= o.required_date THEN 1 END) AS On_Time,
COUNT(CASE WHEN o.shipped_date > o.required_date THEN 1 END) AS Late
FROM orders AS o
JOIN shippers AS s ON s.shipper_id = o.ship_via
GROUP BY 1
ORDER BY 1

---EMPLOYEES---

---Çalışan sayısına bakalım;

SELECT COUNT(*) AS count_employees FROM employees;

---Ofis sayısına bakalım;

SELECT COUNT(DISTINCT(country)) AS offices
FROM employees;

---Çalışanlar işe girdiği zaman kaç yaşındaydı ona bakalım;

SELECT EXTRACT(YEAR FROM AGE(hire_date,birth_date)) AS age,first_name || ' ' || last_name AS employee_name
FROM employees;

---Çalışanların işe girdiği zamanki ortalama yaşına bakalım;

SELECT ROUND(AVG(EXTRACT(YEAR FROM AGE(hire_date,birth_date))),2) AS avg_age
FROM employees;

---Çalışanların performansına bakalım;

WITH employee_performance AS (
SELECT e.first_name || ' ' || e.last_name AS full_name, e.title AS title,
p.product_name,
COUNT(od.quantity) AS total_quantity,
ROUND(SUM((od.unit_price - od.unit_price * od.discount) * od.quantity)::numeric, 2) AS net_profit
FROM orders AS o
JOIN employees AS e ON o.employee_id=e.employee_id
JOIN order_details AS od ON o.order_id=od.order_id
JOIN products AS p ON od.product_id=p.product_id
GROUP BY 1,2,3
ORDER BY 5 DESC
)
SELECT full_name, title, COUNT(total_quantity) AS total_quantity,
SUM(net_profit) AS net_profit
FROM employee_performance
GROUP BY 1,2
ORDER BY 3 DESC;


----PYTHON----

---Müşteri/Ülke Analizi	
	
SELECT c.country,
COUNT(o.order_id) AS order_count
FROM customers AS c
JOIN orders AS o ON c.customer_id = o.customer_id
GROUP BY 1
ORDER BY 2 DESC;

---Kargo şirketi analizi;

SELECT s.shipper_id, s.company_name,
COUNT(DISTINCT o.order_id) AS total_orders,
ROUND(AVG(o.freight)::numeric,2) AS avg_freight,
ROUND(AVG(EXTRACT(DAY FROM (o.shipped_date - o.order_date) * interval '1 DAY'))::numeric,0) AS avg_shipping_days
FROM shippers AS s
JOIN orders AS o ON s.shipper_id = o.ship_via
GROUP BY 1,2

---Aylara göre toplam ciroya bakalım;

SELECT 
EXTRACT(MONTH FROM order_date) AS month_number, 
TO_CHAR(order_date, 'Month') AS month_name,
COUNT(o.order_id) AS total_orders,
ROUND(SUM(od.quantity * od.unit_price)::numeric, 2) AS total_price
FROM orders AS o
JOIN order_details AS od ON od.order_id = o.order_id
GROUP BY 1, 2
ORDER BY 1

---Her kategoride en çok satan ürünlere bakalım;

WITH top_selling_category AS(
SELECT c.category_id, c.category_name, product_name,
SUM(od.quantity) AS top_product,
RANK() OVER (PARTITION BY c.category_name ORDER BY sum(od.quantity) DESC) AS RANK
FROM categories AS c
JOIN products AS p ON p.category_id=c.category_id
JOIN order_details AS od ON od.product_id=p.product_id
GROUP BY 1,2,3)
SELECT * FROM top_selling_category WHERE rank=1
ORDER BY top_product DESC;


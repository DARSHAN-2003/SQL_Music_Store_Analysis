/* Question Set 1 - Easy */

/* Q1: Senior most employee */
SELECT title, last_name, first_name 
FROM employee
ORDER BY levels DESC
LIMIT 1;

/* Q2: Countries with most invoices */
SELECT COUNT(*) AS c, billing_country 
FROM invoice
GROUP BY billing_country
ORDER BY c DESC;

/* Q3: Top 3 values of total invoice */
SELECT total 
FROM invoice
ORDER BY total DESC
LIMIT 3;

/* Q4: City with highest total invoice */
SELECT billing_city, SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC
LIMIT 1;

/* Q5: Best customer */
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_spending
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spending DESC
LIMIT 1;



/* Question Set 2 - Moderate */

/* Q1: Rock music listeners */
SELECT DISTINCT c.email, c.first_name, c.last_name, g.name AS genre_name
FROM customer c
JOIN invoice i ON i.customer_id = c.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN genre g ON g.genre_id = t.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email;

/* Q2: Top 10 rock artists */
SELECT a.artist_id, a.name, COUNT(*) AS number_of_songs
FROM track t
JOIN album al ON al.album_id = t.album_id
JOIN artist a ON a.artist_id = al.artist_id
JOIN genre g ON g.genre_id = t.genre_id
WHERE g.name = 'Rock'
GROUP BY a.artist_id, a.name
ORDER BY number_of_songs DESC
LIMIT 10;

/* Q3: Tracks longer than average */
SELECT name, milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds) 
    FROM track
)
ORDER BY milliseconds DESC;



/* Question Set 3 - Advanced */

/* Q1: Amount spent by each customer on best-selling artist */
WITH best_selling_artist AS (
    SELECT a.artist_id, a.name AS artist_name, 
           SUM(il.unit_price * il.quantity) AS total_sales
    FROM invoice_line il
    JOIN track t ON t.track_id = il.track_id
    JOIN album al ON al.album_id = t.album_id
    JOIN artist a ON a.artist_id = al.artist_id
    GROUP BY a.artist_id, a.name
    ORDER BY total_sales DESC
    LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
       SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = al.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
ORDER BY amount_spent DESC;



/* Q2: Most popular genre per country */

/* Method 1: Using CTE */
WITH popular_genre AS (
    SELECT COUNT(il.quantity) AS purchases, c.country, g.name AS genre_name, g.genre_id,
           ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS RowNo
    FROM invoice_line il
    JOIN invoice i ON i.invoice_id = il.invoice_id
    JOIN customer c ON c.customer_id = i.customer_id
    JOIN track t ON t.track_id = il.track_id
    JOIN genre g ON g.genre_id = t.genre_id
    GROUP BY c.country, g.name, g.genre_id
)
SELECT * 
FROM popular_genre
WHERE RowNo = 1;

/* Method 2: Recursive CTE */
WITH RECURSIVE sales_per_country AS (
    SELECT COUNT(*) AS purchases_per_genre, c.country, g.name AS genre_name, g.genre_id
    FROM invoice_line il
    JOIN invoice i ON i.invoice_id = il.invoice_id
    JOIN customer c ON c.customer_id = i.customer_id
    JOIN track t ON t.track_id = il.track_id
    JOIN genre g ON g.genre_id = t.genre_id
    GROUP BY c.country, g.name, g.genre_id
),
max_genre_per_country AS (
    SELECT country, MAX(purchases_per_genre) AS max_genre_number
    FROM sales_per_country
    GROUP BY country
)
SELECT spc.* 
FROM sales_per_country spc
JOIN max_genre_per_country mg 
  ON spc.country = mg.country
WHERE spc.purchases_per_genre = mg.max_genre_number;



/* Q3: Top customer per country */

/* Method 1: Using CTE */
WITH customer_with_country AS (
    SELECT c.customer_id, c.first_name, c.last_name, i.billing_country, 
           SUM(i.total) AS total_spending,
           ROW_NUMBER() OVER(PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) AS RowNo
    FROM invoice i
    JOIN customer c ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, i.billing_country
)
SELECT * 
FROM customer_with_country 
WHERE RowNo = 1;

/* Method 2: Recursive */
WITH RECURSIVE customer_with_country AS (
    SELECT c.customer_id, c.first_name, c.last_name, i.billing_country, SUM(i.total) AS total_spending
    FROM invoice i
    JOIN customer c ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, i.billing_country
),
country_max_spending AS (
    SELECT billing_country, MAX(total_spending) AS max_spending
    FROM customer_with_country
    GROUP BY billing_country
)
SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customer_with_country cc
JOIN country_max_spending ms ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY cc.billing_country;

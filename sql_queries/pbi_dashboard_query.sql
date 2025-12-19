/* EVERGREEN LIBRARY POWERBI PROJECT */

-- Creating DATE TABLE for PowerBI Project

CREATE TABLE IF NOT EXISTS calendar(
			date date PRIMARY KEY,
			year INT,
			month INT,
			day INT,
			month_name TEXT,
			week_num INT,
			week_name TEXT
);



-- Creating Date Recursive to generate date dataset

WITH RECURSIVE dates(d) AS (
    SELECT DATE '2023-01-01'
    UNION ALL
    SELECT (d + INTERVAL '1 day')::date
    FROM dates
    WHERE d < DATE '2030-01-01'
)
INSERT INTO calendar(date)
SELECT d
FROM dates;


UPDATE calendar
SET year = EXTRACT(YEAR FROM date),
    month = EXTRACT(MONTH FROM date),
		day = EXTRACT(DAY FROM date),
    month_name = TO_CHAR(date, 'Mon'),
		week_num = EXTRACT(DOW FROM date),
		week_name = TO_CHAR(date, 'Day');


SELECT *
FROM calendar;

-------------------------------------------------------------------------------------------------


-- 1. Creating Aggregation For PowerBI

CREATE VIEW kpi_cards AS
WITH kpi_cards AS(
	SELECT COUNT(*) AS total_loans,
				 COUNT(*) FILTER (WHERE return_date IS NOT NULL) AS returned_loans,
				 COUNT(*) FILTER (WHERE return_date IS NULL) AS active_loans,
				 COUNT(*) FILTER (
				   WHERE (return_date IS NOT NULL AND return_date > due_date)
				      OR (return_date IS NULL AND due_date < CURRENT_DATE)) AS overdue_loans
	FROM book_loans 
),
revenue AS (
	SELECT SUM(amount) AS total_revenue
	FROM payments
),
book_stocks AS(
	SELECT SUM(stock) AS total_stocks,
	       COUNT(*) AS total_books
	FROM books
),
staffs AS (
	SELECT COUNT(*) AS total_staff,
				ROUND(AVG(salary),2 ) AS avg_salary
	FROM staff
),
average_rating AS (
	SELECT ROUND(AVG(rating), 2) AS avg_rating,
	       COUNT(reviews) AS total_reviews
	FROM reviews
)
SELECT total_loans,
       returned_loans,
			 active_loans,
			 overdue_loans,
			 ROUND((overdue_loans::decimal / total_loans)*100, 2) AS overdue_in_percent,
			 total_revenue,
			 (total_stocks - active_loans) AS available_copies,
			 total_books,
			 total_staff,
			 avg_salary,
			 avg_rating,
			 total_reviews
FROM kpi_cards, revenue, book_stocks, staffs, average_rating;


DROP VIEW kpi_cards;
-------------------------------------------------------------------------------------



------------------------------------------------------------------------------------


-- 2. CREATING KPI Aggregation 2 

CREATE VIEW kpi_group_by AS 
WITH kpi_group_by AS (
    SELECT 
        b.book_id,
        b.title,
        b.stock,
        COUNT(bl.loan_id) FILTER (WHERE bl.return_date IS NULL) AS active_loans
    FROM books AS b
    LEFT JOIN book_loans AS bl
        ON bl.book_id = b.book_id
    GROUP BY b.book_id, 
						 b.title, 
						 b.stock
),
stock_out AS (
    SELECT 
        book_id,
        (stock - active_loans) AS available_copies
    FROM kpi_group_by
),
most_reservations AS (
	SELECT bl.book_id,
				 COUNT(r.reservation_id) FILTER (WHERE status = 'Pending') AS active_reservations,
	       MIN(bl.due_date) AS next_available_date
	FROM book_loans AS bl
	LEFT JOIN reservations AS r
	ON bl.book_id = r.book_id
	WHERE bl.return_date IS NULL 
	GROUP BY bl.book_id
)
SELECT 
    k.book_id,
    k.title,
    k.stock,
    k.active_loans,
    s.available_copies,
    CASE 
        WHEN k.stock > 0 
        THEN ROUND((s.available_copies::decimal / k.stock) * 100, 2)
        ELSE 0
    END AS stock_out_risk_percentage,
		m.active_reservations,
		m.next_available_date
FROM kpi_group_by AS k
LEFT JOIN stock_out AS s
ON k.book_id = s.book_id
LEFT JOIN most_reservations AS m
ON m.book_id = k.book_id
WHERE s.available_copies <= 0


------------------------------------------------------------------------------

------------------------------------------------------------------------------

-- 3. for members table
CREATE OR REPLACE VIEW members_table AS
SELECT 
    m.member_id,
    m.first_name || ' ' || m.last_name AS member_name,
		m.join_date,
		ROUND((CURRENT_DATE - m.join_date) * 100.0 / NULLIF((m.expiry_date - m.join_date),0),2) AS completion_progress,
		(m.expiry_date - CURRENT_DATE) AS remaining_days,
    COUNT(bl.loan_id) AS total_loans,
    SUM(p.amount) AS total_payments,
    COUNT(bl.loan_id) FILTER (
        WHERE (bl.return_date > bl.due_date) 
           OR (CURRENT_DATE > bl.due_date AND bl.return_date IS NULL)
    ) AS overdue_count
FROM members AS m
LEFT JOIN book_loans AS bl ON m.member_id = bl.member_id
LEFT JOIN payments AS p ON m.member_id = p.member_id
GROUP BY m.member_id, member_name, m.join_date;

DROP VIEW members_table;

------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------


--- 4. Scatter Plot Price v/s Loan

CREATE OR REPLACE VIEW price_vs_loan AS
SELECT 
    b.book_id,
    b.title,
    b.price,
		g.genre_name,
    COUNT(bl.loan_id) AS total_loans
FROM books AS b
LEFT JOIN book_loans AS bl ON b.book_id = bl.book_id
LEFT JOIN genres AS g
ON g.genre_id = b.genre_id
GROUP BY b.book_id, b.title, b.price, g.genre_name
ORDER BY 5 DESC;

--------------------------------------------------------------------------------------------------------

--- 5. New_members and Avg_Revenue KPI

CREATE VIEW last_30_day_member AS
WITH last_30_day_member AS (
SELECT COUNT(*) AS new_members_last_6_months
FROM members
WHERE join_date > CURRENT_DATE - INTERVAL '6 Months'
),
avg_revenue_by_member AS (
SELECT ROUND(AVG(p.amount), 2) AS avg_revenue_per_member
FROM members AS m
LEFT JOIN payments AS p
ON p.member_id = m.member_id
)
SELECT new_members_last_6_months,
       avg_revenue_per_member
FROM last_30_day_member, avg_revenue_by_member;



---------------------------------------------------------------------------


--- 6. Genre Slicer

CREATE OR REPLACE VIEW genre_slicer AS
SELECT g.genre_id,
			 g.genre_name
FROM genres AS g;

---------------------------------------------------------------------------------------------------------------


--- 7. Loans By Month

CREATE OR REPLACE VIEW loans_by_month AS 
SELECT COUNT(*) AS total_book_loans,
       TO_CHAR(DATE_TRUNC('month', loan_date), 'Mon') AS by_month,
			 TO_CHAR(DATE_TRUNC('year', loan_date), 'YYYY') AS by_year,
			 EXTRACT(MONTH FROM loan_date) AS by_month_num
FROM book_loans
WHERE  TO_CHAR(DATE_TRUNC('month', loan_date), 'Mon') IS NOT NULL AND
       TO_CHAR(DATE_TRUNC('year', loan_date), 'YYYY') IS NOT NULL
GROUP BY DATE_TRUNC('month', loan_date),
         DATE_TRUNC('year', loan_date),
				 EXTRACT(MONTH FROM loan_date)
ORDER BY by_year,  DATE_TRUNC('month', loan_date), EXTRACT(MONTH FROM loan_date) ASC;



--------------------------------------------------------------------------------------------------


--- 8. Membership Types Distribution

CREATE VIEW membership_types_distribution AS
SELECT COUNT(*) AS members_count,
       membership_type
FROM members
GROUP BY membership_type;



-------------------------------------------------------------------------------------------------


--- 9. Top 5 Authors

CREATE OR REPLACE VIEW top_5_authors AS 
SELECT COUNT(bl.loan_id) AS total_loans,
       a.author_name,
			 g.genre_name
FROM authors AS a
INNER JOIN books AS b
ON b.author_id = a.author_id
INNER JOIN book_loans AS bl
ON b.book_id = bl.book_id
INNER JOIN genres AS g
ON g.genre_id = b.genre_id
GROUP BY a.author_id,
         g.genre_id
ORDER BY total_loans DESC;


-------------------------------------------------------------------------------------------------------------------


--- 10. Payments TYPE

CREATE VIEW payment_type AS
SELECT COUNT(*) AS payments,
       payment_type
FROM payments
GROUP BY payment_type;


---------------------------------------------------------------------------------------------------------------------


--- 11. Average rating per genre 

CREATE VIEW average_rating_per_genre AS
SELECT ROUND(AVG(r.rating), 2) AS avg_rating,
       g.genre_name
FROM books AS b
INNER JOIN genres AS g
ON g.genre_id = b.genre_id
INNER JOIN reviews AS r
ON r.book_id = b.book_id
GROUP BY g.genre_id



---------------------------------------------------------------------------------------------------------------------

--- 12. Ratings vs Loans

CREATE VIEW rating_vs_fine AS
SELECT g.genre_name,
       ROUND(AVG(r.rating), 2) AS avg_rating,
       COUNT(review_id) AS reviewers
FROM genres AS g
LEFT JOIN books AS b
ON g.genre_id = b.genre_id
LEFT JOIN reviews AS r
ON b.book_id = r.book_id
GROUP BY g.genre_name;


SELECT g.genre_name,
       ROUND(AVG(r.rating), 2) AS avg_rating,
       SUM(bl.fine) AS total_fine
FROM genres AS g
LEFT JOIN books AS b
ON g.genre_id = b.genre_id
LEFT JOIN reviews AS r
ON b.book_id = r.book_id
LEFT JOIN book_loans AS bl
ON bl.book_id = b.book_id
GROUP BY g.genre_name


DROP VIEW rating_vs_fine;





------------------------------------------------------------------------------------------------------------------------

--- 13. Staff by Position

CREATE VIEW staff_by_position AS
SELECT COUNT(*) AS staff_count,
       position
FROM staff
GROUP BY position;


---------------------------------------------------------------------------------------------------------------------------

--- 14. Last 30 days Reviews 

CREATE VIEW las_30_days_reviews AS
SELECT m.first_name || ' ' || m.last_name AS member_name,
       r.review_id,
       r.rating,
			 r.comments,
       ROW_NUMBER() OVER (PARTITION BY r.rating ORDER BY r.review_date DESC) AS review_index 
FROM reviews AS r
INNER JOIN members AS m
ON m.member_id = r.member_id
WHERE review_date > CURRENT_DATE - INTERVAL '180 Days';

---------------------------------------------------------------------------------------------
DROP VIEW las_30_days_reviews;

---------------------------------------------------------------------------------------------------------------------------

--- 15. Loan Date Slicer

CREATE OR REPLACE VIEW loan_date_slicer AS
SELECT loan_date
FROM book_loans;


------------------------------------------------------------------------------------------------------------------------------


--- 16. All books and Authors Data

CREATE OR REPLACE VIEW all_books_data AS
WITH all_books_data AS (
    SELECT 
        b.book_id,
        b.title,
				a.author_name,
				g.genre_name,
        b.stock,
        COUNT(bl.loan_id) FILTER (WHERE bl.return_date IS NULL) AS active_loans
    FROM books AS b
    LEFT JOIN book_loans AS bl
        ON bl.book_id = b.book_id
		LEFT JOIN authors AS a
		ON a.author_id = b.author_id
		LEFT JOIN genres AS g
		ON g.genre_id = b.genre_id
    GROUP BY b.book_id, 
						 b.title, 
						 b.stock,
						 g.genre_id,
						 a.author_name
),
stock_out AS (
    SELECT 
        book_id,
        (stock - active_loans) AS available_copies
    FROM all_books_data
)
SELECT 
    a.book_id,
    a.title,
		a.author_name,
		a.genre_name,
    s.available_copies,
		CASE 
        WHEN a.stock > 0 
        THEN ROUND((s.available_copies::decimal / a.stock) * 100, 2)
        ELSE 0
    END AS stock_out_risk_percentage
FROM all_books_data AS a
LEFT JOIN stock_out AS s
ON a.book_id = s.book_id;

-----------------------------------
SELECT * FROM books;
----------------------------------------------------------------------------------------------------------------------------

-- 17. Top And Low Review Count In a Month and Year

CREATE OR REPLACE VIEW top_and_low_review AS
WITH top_reviews AS (
SELECT TO_CHAR(DATE_TRUNC('month', review_date), 'Mon') AS month_name_t,
       TO_CHAR(DATE_TRUNC('year', review_date), 'YYYY') AS year_name,
			 COUNT(review_id) AS review_count_t,
			 ROW_NUMBER() OVER(PARTITION BY DATE_TRUNC('year', review_date) ORDER BY COUNT(review_id) DESC) AS top_review
FROM reviews
GROUP BY DATE_TRUNC('month', review_date),
         DATE_TRUNC('year', review_date)
),
lowest_reviews AS (
SELECT TO_CHAR(DATE_TRUNC('month', review_date), 'Mon') AS month_name_l,
       TO_CHAR(DATE_TRUNC('year', review_date), 'YYYY') AS year_name,
			 COUNT(review_id) AS review_count,
			 ROW_NUMBER() OVER(PARTITION BY DATE_TRUNC('year', review_date) ORDER BY COUNT(review_id) ASC) AS lowest_review
FROM reviews
GROUP BY DATE_TRUNC('month', review_date),
         DATE_TRUNC('year', review_date)
)
SELECT t.year_name,
       t.month_name_t,
			 t.review_count_t,
			 t.top_review,
			 l.month_name_l,
			 l.review_count_l,
			 l.lowest_review
FROM top_reviews AS t
INNER JOIN lowest_reviews AS l
ON l.year_name = t.year_name
WHERE t.top_review = 1 AND
      l.lowest_review = 1;
			 
------------------------------------------------------------------------------------------------------------------------------

-- 18. over_due loans by year

SELECT TO_CHAR(DATE_TRUNC('Year', loan_date), 'YYYY') AS loan_year,
       COUNT(*) FILTER (
				   WHERE (return_date IS NOT NULL AND return_date > due_date)
				      OR (return_date IS NULL AND due_date < CURRENT_DATE)) AS overdue_loans
FROM book_loans 
GROUP BY DATE_TRUNC('Year', loan_date) 


-----------------------------------------------------------------------------------------------------------------------------

--19. Loan By Week Days

CREATE OR REPLACE VIEW loan_by_week AS
SELECT COUNT(loan_id) AS loans,
       TO_CHAR(DATE_TRUNC('Day', loan_date), 'FMDy') AS dow,
			 TO_CHAR(DATE_TRUNC('Day', loan_date), 'FMd') AS dow_index,
			 TO_CHAR(DATE_TRUNC('Month', loan_date), 'Mon') AS mon,
			 TO_CHAR(DATE_TRUNC('Month', loan_date), 'MM') AS mon_index
FROM book_loans
GROUP BY DATE_TRUNC('Day', loan_date),
         DATE_TRUNC('Month', loan_date)
ORDER BY DATE_TRUNC('Day', loan_date) ASC;


DROP VIEW loan_by_week;
-----------------------------------------------------------------------------------------------------------------------------



--- CREATING INDEX FOR FASTER RESULTS

CREATE INDEX idx_book_loans_book_id ON book_loans(book_id);
CREATE INDEX idx_book_loans_return_date ON book_loans(return_date);
CREATE INDEX idx_book_loans_due_date ON book_loans(due_date);
DROP INDEX IF EXISTS idx_book_loans_member_id;
CREATE INDEX idx_book_loans_member_id ON book_loans(member_id);
CREATE INDEX idx_book_loans_loan_date ON book_loans(loan_date);
CREATE INDEX idx_reservations_book_id ON reservations(book_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_payments_member_id ON payments(member_id);
CREATE INDEX idx_books_author_id ON books(author_id);
CREATE INDEX idx_books_genre_id ON books(genre_id);
CREATE INDEX idx_reviews_book_id ON reviews(book_id);
CREATE INDEX idx_reviews_member_id ON reviews(member_id);





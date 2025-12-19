-- Mix Set Of Practice Questions On Topics: Procedure, Triggers, Views & Materialised Views, Temp Table

-- First Create Table 'audit_logs' TABLE

DROP TABLE IF EXISTS audit_logs;											
CREATE TABLE audit_logs (
    log_id SERIAL PRIMARY KEY,             -- unique log id
    event_type VARCHAR(10) NOT NULL,       -- 'INSERT', 'UPDATE', 'DELETE'
    book_id INT,                           -- reference from book_loans
    member_id INT,                         -- reference from book_loans
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- when event happened
    old_data JSONB,                        -- optional: store old row data (for UPDATE/DELETE)
    new_data JSONB                         -- optional: store new row data (for INSERT/UPDATE)
);



/* Q1 Whenever a member takes a loan (new row inserted into practice_loans), the system 
should automatically insert a record into practice_logs with the member’s ID, loan ID, 
and current timestamp. */


CREATE OR REPLACE FUNCTION new_loan_log()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN 
     INSERT INTO practice_logs(action_type, table_name, member_id)
                VALUES('New Loan', 'practice_loans', NEW.member_id);

		 RAISE NOTICE 'New Book Loan! Added to Logs.';

		 RETURN NEW;
END;
$$;

CREATE TRIGGER loan_log
AFTER INSERT ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION new_loan_log();



/* Q2. When a book is returned (book_loans.return_date updated):
- Update the book_loans table with the return date.
- If the return is late, calculate a fine (fine = 10 * days_late) and update the loan record.
- Increase the books.stock by 1. */


CREATE OR REPLACE PROCEDURE book_return(p_loan_id INT)
LANGUAGE plpgsql
AS $$
DECLARE 
    v_due_date DATE;
    v_book_id INT;
    v_fine INT DEFAULT 0;
    v_return_date DATE := CURRENT_DATE; -- set once
BEGIN
    -- Fetch book_id and due_date
    SELECT book_id, due_date
    INTO v_book_id, v_due_date
    FROM book_loans
    WHERE loan_id = p_loan_id;

    -- Check late return
    IF v_return_date > v_due_date THEN
        v_fine := (v_return_date - v_due_date) * 10;

        -- Update with fine
        UPDATE book_loans
        SET return_date = v_return_date,
            fine = v_fine
        WHERE loan_id = p_loan_id;

        UPDATE books
        SET stock = stock + 1
        WHERE book_id = v_book_id;

        RAISE NOTICE 'Late return! Fine = %', v_fine;

    ELSE
        -- Update with no fine
        UPDATE book_loans
        SET return_date = v_return_date,
            fine = 0
        WHERE loan_id = p_loan_id;

        UPDATE books
        SET stock = stock + 1
        WHERE book_id = v_book_id;

        RAISE NOTICE 'Thanks for returning on time!';
    END IF;
END;
$$;

-- Example call
CALL book_return(3);



/* Q3. You are asked to create a view that shows each customer’s name, country, and 
their total number of orders from the customers and orders tables. */


CREATE OR REPLACE VIEW orders_by_customers
AS
SELECT bl.member_id,
       m.first_name ||' '|| m.last_name AS full_name,
			 m.address,
			 COUNT(bl.book_id) AS total_books_on_loan
FROM members m
INNER JOIN book_loans bl  -- use mebers and book_loans table cause the table in question I dont have.
ON m.member_id = bl.member_id
GROUP BY bl.member_id,
         m.first_name,
				 m.last_name,
				 m.address
ORDER BY 4 DESC;



CREATE ROLE khanna
LOGIN 
PASSWORD 'Gour@v8505';

GRANT SELECT ON orders_by_customers TO khanna;



/* Q4. Suppose your library system runs daily reports. You need to speed up 
performance for a query that calculates:
- Each genre_name
- Total number of books in that genre
- Average price of books in that genre
Since the books table is very large, management asks you to use a materialized 
view instead of a normal view. */


CREATE MATERIALIZED VIEW genres_report
AS
SELECT g.genre_id,
       g.genre_name,
       COUNT(b.book_id) AS total_no_books,
			 ROUND(AVG(b.price:: decimal), 2) AS avg_book_price
FROM genres AS g
INNER JOIN books AS b
ON b.genre_id = g.genre_id
GROUP BY g.genre_name,
         g.genre_id;


REFRESH MATERIALIZED VIEW genres_report; -- to refresh genre_id



/* Q5. Your team needs a temporary table to store a list of members who currently have 
overdue books (where due_date < CURRENT_DATE and return_date IS NULL). */


CREATE LOCAL TEMP TABLE overdue_members
AS
SELECT bl.member_id,
       m.first_name || ' ' || m.last_name AS full_name
FROM book_loans AS bl
INNER JOIN members AS m
ON m.member_id = bl.member_id
WHERE bl.due_date < CURRENT_DATE
  AND bl.return_date IS NULL;



/* Q6. Your library manager wants to track whenever a reservation status changes 
(e.g., from Pending to Approved or Cancelled).
- Create a trigger on the reservations table.
The trigger should insert a record into a log table 
- reservation_logs(reservation_id, old_status, new_status, change_date) 
- every time the status column is updated. */


CREATE OR REPLACE FUNCTION reservation_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
     IF OLD.status != NEW.status THEN
		 INSERT INTO practice_logs(reservation_id, old_status, new_status, change_date)
		              VALUES(OLD.reservation_id, OLD.status, NEW.status, CURRENT_DATE);
     END IF;

		 RETURN NEW;
END;
$$;

CREATE TRIGGER reservation_log
AFTER INSERT OF status ON reservations
FOR EACH ROW
EXECUTE FUNCTION reservation_status();



/* Q7. Your system needs a stored procedure to handle member payments. Requirements:
- Procedure should accept p_member_id and p_amount.
- Insert a record into the payments table with today’s date and payment type = 'Online'.
- Update the member’s expiry_date in members table by adding 1 year if payment is successful. */


CREATE OR REPLACE PROCEDURE member_payments(p_member_id INT, p_amount NUMERIC(10,2))
LANGUAGE plpgsql
AS $$
BEGIN
	    INSERT INTO payments(member_id, amount, payment_date, payment_type)
	                  VALUES(p_member_id, p_amount, CURRENT_DATE, 'Online');
	
			UPDATE members
			SET expiry_date = CASE 
										      WHEN expiry_date > CURRENT_DATE 
												  THEN expiry_date + INTERVAL '1 year'
													ELSE CURRENT_DATE + INTERVAL '1 year'
										    END
    WHERE member_id = p_member_id;

    RAISE NOTICE 'Payment recorded for member % of amount %', p_member_id, p_amount;

END;
$$;


CALL member_payments(490, 111.6);



/* Q8. Your library wants to prevent members from borrowing a new book if they 
already have more than 3 active loans (where return_date IS NULL).
- Create a BEFORE INSERT trigger on the book_loans table.
- The trigger should check how many books the member currently has on loan.
- If it’s more than 3, raise an exception:
- Member already has maximum allowed active loans (3). */


CREATE OR REPLACE FUNCTION no_loan()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
v_count INT;
BEGIN
      SELECT COUNT(loan_id) 
							 INTO v_count
				FROM book_loans
				WHERE return_date IS NULL
				AND member_id = NEW.member_id
				ORDER BY COUNT(loan_id) ASC;

			IF v_count > 3 THEN	
			RAISE EXCEPTION 'Member already has maximum allowed active loans (3).';
	    END IF;

		  RETURN NEW;
END;
$$;

CREATE TRIGGER not_loan
BEFORE INSERT ON book_loans -- If we create new loan then it shows exception
FOR EACH ROW
EXECUTE FUNCTION no_loan();



/* Q9. FULL CONCEPT OF PROCEDURE + TRIGGERS */

/* Write SQL procedures and triggers to handle the complete library flow:
Borrow Procedure
- When a member borrows a book:
- Check if a copy is available (total_copies > active loans for that book).
- If available → insert into book_loans.
- If not available → insert into reservations. */


CREATE OR REPLACE PROCEDURE borrow_book(p_member_id INT, p_book_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
v_stock INT;
BEGIN
			SELECT b.stock INTO v_stock  -- checking total stock for a book
			FROM books AS b
			WHERE b.book_id = p_book_id
			FOR UPDATE;

	  IF NOT EXISTS (SELECT 1 FROM members -- If member and book not in datset then exception
											WHERE member_id = p_member_id) 
			 OR NOT EXISTS (SELECT 1 FROM books
											WHERE book_id = p_book_id) THEN 
		RAISE EXCEPTION 'Invalid member or book';

		ELSIF EXISTS (SELECT 1
		              FROM book_loans -- If loan is created for same book then member can't place a new loan
									WHERE member_id = p_member_id
									  AND book_id = p_book_id
										AND return_date IS NULL) THEN
		RAISE EXCEPTION 'You already have availed a loan for same book!'; 								
		
		
		ELSIF v_stock > 0 THEN -- If book_id is in stock then create a loan for member and update stock table
			INSERT INTO book_loans(book_id, member_id, loan_date, due_date, return_date, fine)
								    VALUES(p_book_id, p_member_id, CURRENT_DATE, CURRENT_DATE + INTERVAL '14 Days', NULL, 0.00);
	    UPDATE books
			SET stock = v_stock - 1
			WHERE book_id = p_book_id;

			RAISE NOTICE 'Loan created for member %.', p_member_id;
			
		ELSIF EXISTS (SELECT 1
		              FROM reservations  -- If member is already in reservation for book then show exception.
									WHERE book_id = p_book_id
									 AND member_id = p_member_id
									 AND status = 'Pending') THEN
					RAISE EXCEPTION 'You''re already reserved for the book_id: %.', p_book_id;

		ELSE
				 INSERT INTO reservations(book_id, member_id, reservation_date, status) -- Else insert member in reservation table to reserve a book.
						VALUES(p_book_id, p_member_id, CURRENT_DATE, 'Pending');
						RAISE NOTICE 'No copies available — reservation created!';
    END IF;
END;
$$;

BEGIN; -- start a query
CALL borrow_book(palce_member_id, place_book_id); -- creation of new book loan and if not then in reservation table


ROLLBACK; -- delete query
COMMIT; -- or save query

				 
/* Reservation Trigger
- Prevent the same member from reserving the same book more than once.
- Raise an exception if attempted. */

CREATE OR REPLACE FUNCTION exclude_duplicate()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
   IF EXISTS (SELECT 1 
	            FROM reservations
							WHERE book_id = NEW.book_id 
							  AND member_id = NEW.member_id
							  AND status = 'Pending') THEN
	 RAISE EXCEPTION 'A member with same member_id: % and book_id: % already exists!', NEW.member_id, NEW.book_id;
	 END IF;

	 RETURN NEW;	 
END;
$$;

CREATE TRIGGER no_duplicate_member -- This TRIGGER and FUNCTION checks If member is in reservation table then dont allowed it
BEFORE INSERT ON reservations  -- if it's not then INSERT It.
FOR EACH ROW 
EXECUTE FUNCTION exclude_duplicate();



SELECT *
FROM book_loans;

SELECT *
FROM books;

SELECT *
FROM reservations
WHERE book_id = 370;

/* Return Procedure
When a member returns a book:
- Update book_loans.return_date.
- Check if someone is waiting in reservations for this book.
- If yes → automatically create a new loan for the first reservation in line (earliest date).
- Remove that reservation entry. */


CREATE OR REPLACE PROCEDURE returning_the_book(p_member_id INT, p_book_id INT)
LANGUAGE plpgsql
AS $$
DECLARE 
    v_due_date DATE;
    v_return_date DATE;
    v_days_late INT;
    v_fine NUMERIC(10, 2);
    v_member_id INT;
    v_stock INT;
BEGIN
    -- Get loan details
    SELECT due_date,
           return_date,
           (CURRENT_DATE - due_date),
           fine
    INTO v_due_date, v_return_date, v_days_late, v_fine
    FROM book_loans
    WHERE member_id = p_member_id
      AND book_id = p_book_id
      AND return_date IS NULL;

    -- Get first reservation (if any)
    SELECT member_id INTO v_member_id
    FROM reservations
    WHERE book_id = p_book_id
      AND status = 'Pending'
    ORDER BY reservation_date ASC
    LIMIT 1;

    -- Always update the loan as returned first
    IF v_due_date > CURRENT_DATE THEN
        UPDATE book_loans
        SET return_date = CURRENT_DATE
        WHERE book_id = p_book_id
          AND member_id = p_member_id
          AND return_date IS NULL;

        RAISE NOTICE 'book_id: % returned successfully!', p_book_id;
    ELSE
        UPDATE book_loans
        SET return_date = CURRENT_DATE,
            fine = v_days_late * 5
        WHERE book_id = p_book_id
          AND member_id = p_member_id
          AND return_date IS NULL;

        RAISE NOTICE 'You''re % days late to return the book_id: %. You''ve to pay fine of %',
                     v_days_late, p_book_id, v_days_late * 5;
    END IF;

    -- Increase stock temporarily (return adds back one copy)
    UPDATE books
    SET stock = stock + 1
    WHERE book_id = p_book_id;

    -- Now handle reservation if exists
    IF v_member_id IS NOT NULL THEN
        -- Create a new loan for reserved member
        INSERT INTO book_loans(book_id, member_id, loan_date, due_date, return_date, fine)
        VALUES(p_book_id, v_member_id, CURRENT_DATE, CURRENT_DATE + INTERVAL '14 days', NULL, 0.00);

        RAISE NOTICE 'Book auto-loaned to reservation member with book_id: % and member_id: %',
                     p_book_id, v_member_id;

        -- Mark reservation as completed
        UPDATE reservations
        SET status = 'Completed'
        WHERE book_id = p_book_id
          AND member_id = v_member_id;

        -- Decrease stock again (since that reserved member took it immediately)
        UPDATE books
        SET stock = stock - 1
        WHERE book_id = p_book_id;
    ELSE
        RAISE NOTICE 'Book returned successfully, no reservation pending';
    END IF;
END; 
$$;

BEGIN;
CALL returning_the_book(book_id, member_id); 


ROLLBACK;

COMMIT;
     
		 


/* Test the Flow
- Insert 2 copies of a book.
- Have 3 members try to borrow it.
- The first 2 get loans.
- The 3rd is added to reservations.
- When 1 copy is returned, the 3rd member should automatically get a loan. */


-- Inserting a new book with 2 stock
  INSERT INTO books(book_id, title, author_id, genre_id, published_year, price, stock)
              VALUES(1001, 'Intersepter', 253, 19, 2025, 76.18, 2);

-- Insert 3 members
INSERT INTO members(member_id, first_name, last_name, email, phone, address, membership_type, join_date, expiry_date)
			VALUES(501, 'Charles', 'Lerry', 'charleslerry@gmail.com', '(952) 7564091', '6839 Sherpherd Trace, New Cynthia, OR 95505', 'Regular', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 Year');

INSERT INTO members(member_id, first_name, last_name, email, phone, address, membership_type, join_date, expiry_date)
			VALUES(502, 'Becky', 'Rely', 'beckyrely90@gmail.com', '(532) 7564091', '7070 Jordan Crescent, East Steven, WA 04505', 'Student', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 Year');

INSERT INTO members(member_id, first_name, last_name, email, phone, address, membership_type, join_date, expiry_date)
			VALUES(503, 'Brock', 'Rollins', 'rollinsbrock43@gmail.com', '(629) 8878091', '325 Michael Crescent, Kellyberg, IN 55723', 'Student', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 Year');


ALTER TABLE reservations
ALTER COLUMN reservation_id ADD GENERATED ALWAYS AS IDENTITY; -- changing reservation_id serial wise

SELECT setval('reservations_reservation_id_seq', (SELECT MAX(reservation_id) FROM reservations)+1); -- changing reservation_id serial wise


-- borrow book on loan insert into book_loans if not available then reservations
CALL borrow_book(501, 1001); -- book_id + member_id. loan created for member 501
CALL borrow_book(502, 1001); -- loan created for member 502 as stock given 1 of 2.
CALL borrow_book(503, 1001); -- member 503 goes to resrvations table casue stock is 0 of 2. No stock of book.ABORT


-- book 1 of 2 stock of a book returned and loan created for first reserved person for same book.
CALL returning_the_book(503, 1001);



DELETE FROM book_loans
WHERE book_id = 1001
AND member_id IN (501, 502, 503); -- query not working so deleted loan_id created

DELETE FROM reservations
WHERE book_id = 1001
AND member_id = 503;

UPDATE books
SET stock = 2   --- updated stock to 2 of 2 again
WHERE book_id = 1001;

-----------------------------------------------------------------------
-----------------------------------------------------------------------

/* Q10. Every time a book_loans row is INSERTED, UPDATED, or DELETED, record the 
event in a new table audit_logs.
- Restriction Rule
- If a member already has 5 active loans (return_date IS NULL), the trigger should 
- prevent inserting another loan and raise an exception:
- "Member % already has 5 active loans. Cannot borrow more." */


-- Use a BEFORE INSERT OR UPDATE OR DELETE trigger on book_loans.

-- Demonstrates both auditing (common in interviews) and business rules enforcement (real-world use case).

 
CREATE OR REPLACE FUNCTION audit_logs()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_loans INT;
BEGIN
    -- Count only for the member making the change (INSERT case)
    IF TG_OP = 'INSERT' THEN
        SELECT COUNT(*) INTO v_total_loans
        FROM book_loans
        WHERE return_date IS NULL
          AND member_id = NEW.member_id;

        IF v_total_loans >= 5 THEN
            RAISE EXCEPTION 
              'Member % already has 5 or more active loans. Cannot borrow more.', 
              NEW.member_id;
        END IF;
    END IF;

    -- Always insert into audit_logs (for INSERT, UPDATE, DELETE)
    INSERT INTO audit_logs(event_type, book_id, member_id, old_data, new_data)
    VALUES (
        TG_OP,                          
        CASE
            WHEN TG_OP = 'INSERT' THEN NEW.book_id
            WHEN TG_OP = 'UPDATE' THEN NEW.book_id
            WHEN TG_OP = 'DELETE' THEN OLD.book_id
        END,
        CASE
            WHEN TG_OP = 'INSERT' THEN NEW.member_id
            WHEN TG_OP = 'UPDATE' THEN NEW.member_id
            WHEN TG_OP = 'DELETE' THEN OLD.member_id
        END,
        row_to_json(OLD),   -- old data (NULL for insert)
        row_to_json(NEW)    -- new data (NULL for delete)
    );

    RETURN NEW;
END;
$$;


CREATE TRIGGER audit_log
BEFORE INSERT OR DELETE OR UPDATE
ON book_loans
FOR EACH ROW
EXECUTE FUNCTION audit_logs();

-- checking if TRIGGER working or NOT
INSERT INTO book_loans(book_id, member_id, return_date, fine)
          VALUES(1001, 156, NULL, 0.00);


---------------------------------------------------
---------------------------------------------------

SELECT *
FROM audit_logs;

SELECT *
FROM payments;

SELECT *
FROM reservations
WHERE book_id = 1001;

SELECT *
FROM members;

SELECT *
FROM books

SELECT COUNT(*),
       member_id
FROM book_loans
WHERE return_date IS NULL
GROUP BY member_id
HAVING COUNT(*) < 3;

SELECT *
FROM practice_logs;

SELECT *
FROM practice_loans;

SELECT *
FROM practice_members;

/* Practice Session of PROCEDURE */

CREATE PROCEDURE say_hello()
LANGUAGE plpgsql                               -- This is Procedure Syntax
AS $$     
BEGIN 
  RAISE NOTICE 'Hello From Postgre!' ;
END;
$$;


CALL say_hello();   -- This is How to Call a Procedure



CREATE PROCEDURE greet_user(p_name TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
   RAISE NOTICE 'Hello, %!', p_name;
END;
$$;


CALL greet_user('Tushar');



-- Created a new table to use PROCEDURE

CREATE TABLE local_table
             (customer_id SERIAL PRIMARY KEY,
              name TEXT,
							country TEXT
						 );

ALTER TABLE local_table
ADD COLUMN country TEXT;

CREATE OR REPLACE PROCEDURE add_new_name(p_name TEXT, country TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO local_table(name, country)
		                 VALUES(p_name, country);
END;					
$$;


CALL add_new_name('Gaurav');

SELECT * FROM local_table;



/* QUESTION SOLVING ON PROCEDURE TOPIC */


-- Task 1 — Say Hello (Warm-up)
-- Create a procedure say_hello() that prints the message:


CREATE OR REPLACE PROCEDURE say_hello(p_name TEXT)
LANGUAGE plpgsql
AS $$
BEGIN 
   RAISE NOTICE 'Hello from PostgreSQL Procedure!';
END;
$$;

CALL say_hello('Sagar');



-- Task 2 — Greeting with Name
-- Create a procedure greet_user(p_name TEXT) that prints:

CREATE OR REPLACE PROCEDURE greet_user(p_name TEXT)
LANGUAGE plpgsql
AS $$
BEGIN 
  RAISE NOTICE 'Hello, %!', p_name;
END;
$$;

CALL greet_user('Gaurav');



-- Task 3 — Insert into a Table
-- Create a procedure add_user(p_name TEXT, p_country TEXT) to insert a new record into this table.

CREATE OR REPLACE PROCEDURE add_details(p_customer_id INT, p_name TEXT, p_country TEXT, p_quantity INT)
LANGUAGE plpgsql
AS $$
BEGIN 
   INSERT INTO local_table(customer_id, name, country, quantity)
	                  VALUES(p_customer_id, p_name, p_country, p_quantity);
END;
$$;

CALL add_details('Sunil', 'India');
CALL add_details('Gaurav', 'India');

SELECT * FROM local_table;



-- Task 4 — Delete a User by ID

CREATE PROCEDURE delete_user(p_customer_id INT)
LANGUAGE plpgsql
AS $$
BEGIN 
   DELETE FROM local_table
	   WHERE customer_id = p_customer_id;
   RAISE NOTICE 'User Deleted Successfully';
END;
$$;


CALL delete_user(2);

SELECT * FROM local_table;



-- Task 5 — Conditional Insert

/* Create a procedure add_unique_user(p_name TEXT, p_country TEXT) that:
-- Checks if a user with the same name already exists.
-- If not, inserts the user.
-- If yes, prints a message "User already exists" without inserting. */


CREATE OR REPLACE PROCEDURE add_unique_user(p_name TEXT, p_country TEXT)
LANGUAGE plpgsql 
AS $$
BEGIN
   IF NOT EXISTS (SELECT 1 
	                FROM local_table
									WHERE name = p_name
									  AND country = p_country
									)
	    THEN INSERT INTO local_table(name, country)
			                   VALUES(p_name, p_country);
	 ELSE RAISE NOTICE '% User Already Exists!', p_name;
   END IF;
END;
$$;


CALL add_unique_user('Sunil', 'India');



/* TOPIC: VARIABLE PROCEDURE */


-- TASK 1

SELECT * FROM local_table;

CREATE OR REPLACE PROCEDURE greet_country(p_country TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INTEGER; -- variable to store count
BEGIN
    -- Store the count of matching users in v_count
    SELECT COUNT(*) INTO v_count
    FROM local_table
    WHERE country = p_country;

    -- Check the value
    IF v_count > 0 THEN
        RAISE NOTICE 'Welcome, The total count is: %', v_count;
    ELSE
        RAISE NOTICE 'No User Found!';
    END IF;
END;
$$;


CALL greet_country('India');


/* Task 2 Write a procedure called check_user_name that:
- Takes one input parameter: p_name TEXT.
- Stores in a variable the number of times that name appears in local_table.
- If the count is more than 0, print: 
- NOTICE: User % found % time(s)! */


CREATE OR REPLACE PROCEDURE show_user_count(p_name TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INTEGER;
BEGIN 
		   SELECT COUNT(*) INTO v_count
			 FROM local_table
			 WHERE name = p_name;
   IF v_count >= 1 THEN 
	           RAISE NOTICE 'User % found % time(s)!', p_name, v_count;
	 ELSE RAISE NOTICE 'User % not found!', p_name;
END IF;
END;
$$


CALL show_user_count('Gaurav');  --- in dataset
CALL show_user_count('Sahil'); --- not in dataset


SELECT * FROM local_table;



/* Task 3. Create a procedure show_country_stats in PostgreSQL that:
- - Takes one input parameter: p_country TEXT
- Declares two variables:
- v_count → to store the number of users from that country
- v_avg_id → to store the average customer_id for that country
- Uses a single SELECT statement to store both values into the two variables
- If v_count is greater than 0, print:
- NOTICE: There are % users from %, with an average customer_id of 
- - If v_count is 0, print:
- NOTICE: No users found from %. */

CREATE OR REPLACE PROCEDURE show_country_stats(p_country TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INT;
	v_avg_id NUMERIC(10,2);
BEGIN
	     SELECT COUNT(*), AVG(customer_id)
			        INTO v_count, v_avg_id
			 FROM local_table
			 WHERE country = p_country;
	 IF v_count > 0 THEN 
	                 RAISE NOTICE 'There are % users from %, with an average customer_id of %.',
									               v_count, p_country, v_avg_id;
	 ELSE RAISE NOTICE 'No users found from %.', p_country;
	 END IF;
END;
$$;

CALL show_country_stats('Canada');

SELECT * FROM local_table;



/* LOOPS TOPIC: PROCEDURE */

CREATE OR REPLACE PROCEDURE list_users_and_count()
LANGUAGE plpgsql   -- PRACTICE QUERY BY CHATGPT
AS $$
DECLARE
    rec RECORD;        -- variable to store each row
    v_total INT := 0;  -- counter variable
BEGIN
    FOR rec IN SELECT * FROM local_table LOOP
        RAISE NOTICE 'Name: %, Country: %', rec.name, rec.country;
        v_total := v_total + 1;  -- increase count by 1
    END LOOP;

    RAISE NOTICE 'Total users: %', v_total;
END;
$$;

-- Call the procedure
CALL list_users_and_count();



/* Task 1. 
- Create a procedure loop_numbers that:
- Declares a variable i
- Loops from 1 to 5
- For each number, prints: NOTICE: Number is %  */

CREATE OR REPLACE PROCEDURE loop_numbers()
LANGUAGE plpgsql
AS $$
DECLARE
    i INT;  -- variable to store the current number
BEGIN
    FOR i IN 1..20 LOOP
        RAISE NOTICE 'Number is %', i;
    END LOOP;
END;
$$;

-- Call the procedure:
CALL loop_numbers();



---- PRACTICE LOOP WITH VARIABLE's


CREATE OR REPLACE PROCEDURE sum_numbers()
LANGUAGE plpgsql
AS $$
DECLARE
    i INT;       -- loop counter
    v_total INT; -- variable to store running total
BEGIN
    v_total := 0; -- start total at 0

    FOR i IN 1..5 LOOP
        v_total := v_total + i;  -- add current number to total
        RAISE NOTICE 'Added %, current total is %', i, v_total;
    END LOOP;

    RAISE NOTICE 'Final total is %', v_total;
END;
$$;

CALL sum_numbers();


/* Task 2. Create a procedure sum_customer_ids() that:
- Declares a variable v_sum (start at 0)
- Loops through all rows in local_table
- Adds each row’s customer_id to v_sum
- Prints the current running sum in each loop
- Prints the final sum at the end */


CREATE OR REPLACE PROCEDURE sum_customer_ids()
LANGUAGE plpgsql
AS $$
DECLARE 
   v_total INT;
	 rec record;
BEGIN 
   v_total := 0;
	 
   FOR rec IN 
	    SELECT customer_id
			FROM local_table
	 LOOP 
	   v_total := v_total+ rec.customer_id;
		 RAISE NOTICE 'Added Customer_id %, Current Sum Is: %', rec.customer_id, v_total;
	 END LOOP ;

	 RAISE NOTICE 'Final Sum Is: %', v_total;
END;
$$;


CALL sum_customer_ids();


-- Add DATA

CALL add_details(1, 'Gaurav', 'India', 3);
CALL add_details (2, 'Sahil', 'India', 5);
CALL add_details (3, 'Sagar', 'India', 6);
CALL add_details (4, 'Tushar', 'India', 2);
CALL add_details (5, 'Anuj', 'India', 11);
CALL add_details (6, 'Aryan', 'India', 1);
CALL add_details (7, 'Lakshay', 'India', 4);
CALL add_details (8, 'Deepak', 'India', 5);
CALL add_details(9, 'Yash', 'Canada', 6);


SELECT * FROM local_table;

TRUNCATE TABLE local_table;


/* PRACTICE: WHILE LOOP TOPIC */

DO $$
DECLARE
   counter INT := 1;
BEGIN
   WHILE counter <= 5 LOOP
      RAISE NOTICE 'Counter value is: %', counter;
      counter := counter + 1;  -- increase counter
   END LOOP;
END;
$$;


/* Practice Topic: IF Statement (Procedure) */

DO $$   --- 'DO $$' is used to start a procedure without CALLing it.
DECLARE
    score INT := 75;
BEGIN
    IF score >= 90 THEN
        RAISE NOTICE 'Grade A'
    ELSIF score >= 70 THEN
        RAISE NOTICE 'Grade B'
    ELSE
        RAISE NOTICE 'Grade C'
    END IF;
END $$;



/* TASK 1 Write a stored procedure that takes customer_id as input and returns the 
customer’s name, country, quantity, and a status based on quantity:
-- If quantity > 100 → return "High Order"
-- If quantity between 50 and 100 → return "Medium Order"
-- If quantity < 50 → return "Low Order"
-- Use a CASE expression inside the procedure to generate the status. */


CREATE OR REPLACE PROCEDURE status(p_customer_id INT)
LANGUAGE plpgsql
AS $$
DECLARE 
	  rec record;
		order_status TEXT;
BEGIN 

    FOR rec IN 
    SELECT name, 
					 country,
					 quantity
		FROM local_table
		WHERE customer_id = p_customer_id 
		LOOP
			 order_status :=
			 CASE
				 WHEN rec.quantity BETWEEN 1 AND 4 THEN 'Low Order'
				 WHEN rec.quantity BETWEEN 5 AND 7 THEN 'Medium Order'
				 WHEN rec.quantity BETWEEN 8 AND 11 THEN 'High Order'
			 END;
			 RAISE NOTICE 'Name: %, Country: %, Quantity: %, Status: %',
			 rec.name, rec.country, rec.quantity, order_status;
		END LOOP;
END;
$$;


CALL status(7);

SELECT * FROM local_table;


/* */


CREATE OR REPLACE PROCEDURE get_customer_status(
    p_customer_id INT,
    OUT customer_name TEXT,
    OUT order_status TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT name,
           CASE
               WHEN quantity BETWEEN 1 AND 4 THEN 'Low Order'
               WHEN quantity BETWEEN 5 AND 7 THEN 'Medium Order'
               WHEN quantity >= 8 THEN 'High Order'
           END
    INTO customer_name, order_status
    FROM local_table
    WHERE customer_id = p_customer_id;
END;
$$;

-- Call it
CALL get_customer_status(9, customer_name => NULL, order_status => NULL);


/* PRACTICE TOPIC: OUT PARAMETERS */

/* Task 1. Write a procedure called get_customer_info that:
- Accepts 2 parameters → p_customer_id INT and p_customer_name TEXT DEFAULT NULL.
- If p_customer_name is not provided (i.e., NULL), the procedure should fetch the 
customer details from local_table using p_customer_id.
- If p_customer_name is provided, it should fetch details using both p_customer_id 
and p_customer_name.
- Display the customer’s name, country, and quantity. */


CREATE OR REPLACE PROCEDURE get_customer_info(
                              p_customer_id INT,
															p_customer_name TEXT,
													OUT o_country TEXT,
													OUT o_quantity INT
															
)
LANGUAGE plpgsql
AS $$
BEGIN 
    IF p_customer_name IS NULL THEN
		    SELECT country,
							 quantity
							 INTO o_country, o_quantity
		    FROM local_table
				WHERE customer_id = p_customer_id;
				
		ELSE 
		     SELECT country,
							  quantity
							 INTO o_country, o_quantity
		    FROM local_table
				WHERE customer_id = p_customer_id
				  AND name = p_customer_name;
				END IF;

END;
$$;


CALL get_customer_info(1, NULL);
CALL get_customer_info(1, 'Gaurav');

DROP PROCEDURE get_customer_info;




/* SQL PROCEDURE ALL TOPIC REVISION */


/* Q1. Write a procedure proc_show_customers that simply selects all rows from your customers 
table. It should have no parameters. */


CREATE OR REPLACE PROCEDURE proc_show_customers()
LANGUAGE plpgsql
AS $$
DECLARE 
   rec record;
BEGIN
    FOR rec IN
    SELECT customer_id,
		       name,
					 country,
					 quantity
		FROM local_table
		LOOP

		RAISE NOTICE 'customer_id: %, name: %, country: %, quantity: %',
		              rec.customer_id, rec.name, rec.country, rec.quantity;
		END LOOP;
END;
$$;


CALL proc_show_customers();



/* Q2. Write a stored procedure named delete_user_by_id that takes a user_id as an input 
parameter and deletes that user from the users table.
- If the user exists, delete them.
- If the user does not exist, do nothing (no error). */


CREATE OR REPLACE PROCEDURE del_user_id(p_customer_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 
		           FROM local_table
							 WHERE customer_id = p_customer_id)
		  THEN DELETE FROM local_table
				   WHERE customer_id = p_customer_id;
				 RAISE NOTICE 'Deleted Successfully! Customer_id: %', p_customer_id;

	  ELSE RAISE NOTICE 'Not Exists! Customer_id: %', p_customer_id;
	 END IF;
END;
$$;


CALL del_user_id(9);



/* Q3. Create a function that updates a customer’s country in the customers table, 
given a customer_id and a new country.
- If the customer_id exists → update the country and return a success message.
- If it does not exist → return a failure message. */


CREATE OR REPLACE PROCEDURE update_customer(p_customer_id INT, p_country TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
	   IF EXISTS (SELECT 1 FROM local_table
		            WHERE customer_id = p_customer_id
						     )
		    THEN UPDATE local_table
						 SET country = p_country
						 WHERE customer_id = p_customer_id;
				RAISE NOTICE 'Customer_id: % Updated Successfully', p_customer_id;
		 ELSE RAISE NOTICE 'Customer_id: % Not Exists', p_customer_id;
	END IF;
END;
$$;


CALL update_customer(1, 'India');

SELECT * FROM local_table;



/* Q4. Write a stored procedure that declares a variable to hold a user’s country from the 
table local_table. The procedure should take a user_id as input, fetch the country of that 
user into the variable, and then return it (using RAISE NOTICE or SELECT). */


CREATE OR REPLACE PROCEDURE show_country(p_customer_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
   v_country TEXT;
BEGIN
   SELECT country INTO v_country FROM
	 local_table
	 WHERE customer_id = p_customer_id;

	 RAISE NOTICE 'User Detail''s,  Customer_id: %, Country: %',
	                               p_customer_id, v_country;
END;
$$;


CALL show_country(1);



/* Q5. Write a stored procedure in PostgreSQL that prints numbers from 1 to 10 using a simple LOOP. */


CREATE OR REPLACE PROCEDURE show_numbers()
LANGUAGE plpgsql
AS $$
DECLARE
  v_total INT := 0;
BEGIN
	    FOR i IN 1..10
			LOOP
			v_total := v_total+1;
			RAISE NOTICE 'NUMBER: %' , i;
		END LOOP;
END;
$$;

CALL show_numbers();



/* Q6. Write a stored procedure in PostgreSQL named countdown_timer that:
- Takes one input parameter p_start INT (starting number).
- Uses a LOOP with variables to count down from p_start to 1.
- Inside the loop, print each number using RAISE NOTICE.
- When the loop ends, display a final message "Countdown Finished!". */

CREATE OR REPLACE PROCEDURE countdown_timer(p_start INT)
LANGUAGE plpgsql
AS $$
DECLARE
    i INT;
BEGIN
    -- Loop from given start down to 1
    FOR i IN REVERSE p_start..1 LOOP
        RAISE NOTICE 'Count: %', i;
    END LOOP;

    RAISE NOTICE 'Countdown Finished';
END;
$$;

-- Call Example:
CALL countdown_timer(10);



/* Q7. Write a PL/pgSQL procedure using a WHILE loop that prints all even numbers from 
2 up to a given number p_limit. */


CREATE OR REPLACE PROCEDURE even_numbers(p_limit INT)
LANGUAGE plpgsql
AS $$
DECLARE
   i INT = 2;
BEGIN
    WHILE i <= p_limit LOOP
        RAISE NOTICE '%', i;
        i := i + 2;
    END LOOP;
END;
$$;

CALL even_numbers(4);



/* Q8. Write a procedure in PL/pgSQL that takes a number as input and uses a CASE statement 
to print whether the number is positive, negative, or zero. */


CREATE OR REPLACE PROCEDURE number(p_num INT)
LANGUAGE plpgsql
AS $$
DECLARE 
		v_num INT := 0;
BEGIN
   v_num := p_num;
	 
	 RAISE NOTICE '% is %', v_num,
	 CASE
	   WHEN p_num = 0 THEN 'ZERO'
		 WHEN p_num < 0 THEN 'NEGATIVE'
		 ELSE 'POSITIVE'
	 END;
END;
$$;



CREATE OR REPLACE PROCEDURE number(p_num INT)
LANGUAGE plpgsql
AS $$
DECLARE 
   v_num INT := 0;
BEGIN
   v_num := p_num;

   RAISE NOTICE '% is %', v_num,
   CASE
      WHEN p_num = 0 THEN 'ZERO'
      WHEN p_num < 0 THEN 'NEGATIVE'
      ELSE 'POSITIVE'
   END;
END;
$$;


CALL number(2);



/* Q10. Write a stored procedure using an OUT parameter that takes a customer_id as input and 
returns the total order amount for that customer through the OUT parameter. */


CREATE OR REPLACE PROCEDURE count_id(p_customer_id INT,
                                     OUT p_quantity INT
																		)
LANGUAGE plpgsql
AS $$
BEGIN
   SELECT COUNT(quantity) INTO p_quantity
	 FROM local_table
	 WHERE customer_id = p_customer_id;
END;
$$;

CALL count_id(5, NULL);


-- TOPIC PRACTICE: COMMIT/ROLLBACK IN PROCEDURE


CREATE OR REPLACE PROCEDURE insert_data(p_customer_id INT,
																				p_name TEXT,
																				p_country TEXT,
																				p_quantity INT
																				)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM local_table
		               WHERE customer_id = p_customer_id)
		THEN
		    INSERT INTO local_table(customer_id, name, country, quantity)
				                 VALUES(p_customer_id, p_name, p_country, p_quantity);
		ELSE RAISE NOTICE '% already exists!', p_customer_id;
		END IF;		
END;
$$;

BEGIN;
CALL insert_data(11, 'Roman', 'Australia', 4);


ROLLBACK;


COMMIT;

SELECT * FROM local_table;


/* Views & Materialized Views */

CREATE VIEW books_table   --- VIEW - A view create table as you want to show your clients or someone else
AS                        --- it works by running the only query you written it, doesn't load dataset in iteslf
SELECT *                  --- like MATERIALIZED VIEW.
FROM book_loans;

SELECT * FROM books_table;
SELECT * FROM book_loans;



CREATE MATERIALIZED VIEW mv_books_table   --- MATERIALIZED VIEW - A type of view, which stores all data in it
AS                                        --- it's faster than normal VIEW.
SELECT * FROM book_loans;


SELECT * FROM books_table;  -- View
SELECT * FROM book_loans;   -- normal table
SELECT * FROM mv_books_table; -- Materialized View


-----------------------------------------------

-- VIEW

CREATE OR REPLACE VIEW fine_by_member
AS
SELECT member_id,
       SUM(fine) AS total_fine
FROM book_loans
GROUP BY member_id 
ORDER BY 1;

SELECT * FROM fine_by_member; -- view
SELECT * FROM book_loans; -- normal table


-- MATERIALIZED VIEW


CREATE MATERIALIZED VIEW total_fine
AS
SELECT member_id,
       SUM(fine) AS total_fine
FROM book_loans
GROUP BY member_id
ORDER BY 1;

SELECT * FROM total_fine;



-------

-- Now We create a user to grant access to that user it can use our created VIEW.ABORT


CREATE ROLE tushar
LOGIN 
PASSWORD 'tushar';

GRANT SELECT ON total_fine TO tushar;  -- 



---
CREATE LOCAL TEMP TABLE opd
AS
SELECT *
FROM book_loans;


ALTER TABLE opd
DROP COLUMN loan_id;



CREATE TEMP TABLE opd_1
AS
SELECT *
FROM book_loans;

DROP TABLE opd_1;






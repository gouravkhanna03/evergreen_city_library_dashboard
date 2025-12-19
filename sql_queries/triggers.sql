/* TRIGGER AND FUNCTION PRACTICE */


-- A Trigger is like suppose you've a 'book_loans' table and in that table someone ordered a book on loan 
-- and you want to record every new customer coming, in a seperate table 'book_loan_logs'. For this you've
-- to create a 'TRIGGER' that trigger fires when you insert records in 'book_loans' and when you insert.
-- A same copy of this record save into the 'book_loan_logs' table on auto, on every new insert.
-- Trigger and Function Works together. To Fire a 'Trigger' we first have to create 'Function'


/* EXAMPLE TRIGGER AND FUNCTION */

CREATE TABLE audit_log (
		    log_id SERIAL PRIMARY KEY,
		    emp_id INT,
		    old_salary NUMERIC,      -- It's a sample version first we'created a logs table to record insert's or delete's
		    new_salary NUMERIC,
		    changed_at TIMESTAMP DEFAULT NOW()
);




CREATE OR REPLACE FUNCTION log_salary_change()
RETURNS TRIGGER AS $$  -- Create a function to use it later on TRIGGER 
BEGIN
    -- Insert old and new salary into log table
    INSERT INTO audit_log(emp_id, old_salary, new_salary)
    VALUES (OLD.id, OLD.salary, NEW.salary); -- .OLD means adding data from old table/ row before new row
    RETURN NEW;  -- .NEW the new value you're going to insert/ the row after update
END;
$$ LANGUAGE plpgsql;



-- Create a TRIGGER to fire when some values insert's in 'employees' table.
CREATE TRIGGER after_salary_update
AFTER UPDATE OF salary ON employees
FOR EACH ROW  
EXECUTE FUNCTION log_salary_change();


-- New Table for Practice
CREATE TABLE practice_members (
    member_id SERIAL PRIMARY KEY,
    member_name TEXT NOT NULL,
    join_date DATE
);

CREATE TABLE practice_loans (
    loan_id SERIAL PRIMARY KEY,
    member_id INT REFERENCES practice_members(member_id),
    loan_date DATE,
    due_date DATE,
    return_date DATE,
    fine NUMERIC DEFAULT 0
);


CREATE TABLE practice_logs (
    log_id SERIAL PRIMARY KEY,
    action_type TEXT,         -- e.g., 'INSERT', 'DELETE', 'UPDATE'
    table_name TEXT,          -- e.g., 'practice_members' or 'practice_loans'
    member_id INT,            -- ID of affected row
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



/* PRACTICE QUESTIONS FOR TRIGGER/FUNCTION */


SELECT *
FROM practice_members;

SELECT * FROM practice_loans;


/* Q1. When a new row is inserted into practice_members, if join_date is not provided, set it to current date. */

CREATE OR REPLACE FUNCTION members_insert()
RETURNS TRIGGER AS $$
BEGIN
   IF NEW.join_date IS NULL THEN
   NEW.join_date := CURRENT_DATE;
END IF;
	 RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER t_members_insert
BEFORE INSERT ON practice_members
FOR EACH ROW
EXECUTE FUNCTION members_insert();


INSERT INTO practice_members(member_name)
VALUES('Abhishek Banerjee');



/* Q2. Create a trigger that logs every new member insertion into practice_logs table with:
- log_id (auto-generated with SERIAL)
- action = 'INSERT'
- member_id (from inserted row)
- log_time = current timestamp */


-- FUNCTION
CREATE OR REPLACE FUNCTION update_logs()
RETURNS TRIGGER 
AS $$
BEGIN
    INSERT INTO practice_logs(action_type, table_name, member_id, log_date)
                       VALUES('Insert', 'practice_members', NEW.member_id, CURRENT_TIMESTAMP);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

-- TRIGGER
CREATE TRIGGER update_logs_table
AFTER INSERT ON practice_members
FOR EACH ROW
EXECUTE FUNCTION update_logs()

-- ACTIVATING TRIGGER BY INSERTING VALUES
INSERT INTO practice_members(member_name)
VALUES('Abhishek Banerjee');

SELECT *
FROM practice_members;

SELECT *
FROM practice_logs;

DELETE FROM practice_members;


ALTER SEQUENCE practice_members_member_id_seq RESTART WITH 1;



/* Q3. Create a trigger that logs every UPDATE on practice_members into practice_logs table.
The log should include:
- action_type = 'Update'
- table_name = 'practice_members'
- member_id (from the updated row)
-log_date = current timestamp */


CREATE OR REPLACE FUNCTION update_practice_logs()
RETURNS TRIGGER
AS $$
BEGIN 
   INSERT INTO practice_logs(action_type, table_name, member_id)
	                    VALUES('Update', 'practice_members', NEW.member_id);
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER update_in_logs
AFTER UPDATE ON practice_members
FOR EACH ROW
EXECUTE FUNCTION update_practice_logs();

-- checking work of trigger
UPDATE practice_members
SET member_name = 'Gaurav Khanna'
WHERE member_id = 1;

SELECT * FROM practice_logs;

SELECT * FROM practice_members;



/* Q4. Create a trigger that deletes all related log entries from practice_logs 
whenever a member is deleted from practice_members. */


CREATE OR REPLACE FUNCTION delete_logs()
RETURNS TRIGGER 
AS $$
BEGIN 
    DELETE FROM practice_logs
		WHERE member_id = OLD.member_id;
		
		RAISE NOTICE 'member_id: % is successfully deleted! You can''t get it back!!', OLD.member_id;
		RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER delete_from_logs
AFTER DELETE ON practice_members
FOR EACH ROW 
EXECUTE FUNCTION delete_logs();


DELETE FROM practice_members
WHERE member_id = 1;

SELECT * FROM practice_members;
SELECT * FROM practice_logs;



/* Q5. Create a trigger that prevents updating a member's name to an empty 
string ('') in the practice_members table. If someone tries to update 
member_name to an empty string, raise an error and do not allow the update. */


CREATE OR REPLACE FUNCTION exception_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	   IF NEW.member_name = '' THEN
		                RAISE EXCEPTION 'String/Blank Not Allowed In Place of member_name';
	   ELSE
		   INSERT INTO practice_logs(action_type, table_name, member_id)
		                      VALUES('Update', 'practice_members', NEW.member_id);
			 RETURN NEW;
		END IF;
END;
$$;
								

CREATE TRIGGER exception_trigger_logs
BEFORE UPDATE ON practice_members
FOR EACH ROW
EXECUTE FUNCTION exception_update();


INSERT INTO practice_members(member_id, member_name, join_date)
       VALUES(2, '', CURRENT_DATE);

-- checking trigger working or not
UPDATE practice_members
SET member_name = ''
WHERE member_id = 1;


SELECT * FROM practice_logs;
SELECT * FROM practice_members;



/* Q6. Create a trigger that prevents deletion of a record from practice_members if 
member_name is NULL or blank. If such a delete is attempted, raise an exception with 
a custom message like: 'Cannot delete a member with empty name'. */


CREATE OR REPLACE FUNCTION del_practice_members()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.member_name IS NULL OR OLD.member_name = '' THEN
		RAISE EXCEPTION 'Cannot delete a member with empty name';
    RETURN OLD;
   END IF;
END;
$$;


CREATE TRIGGER del_practice_name
BEFORE DELETE ON practice_members
FOR EACH ROW 
EXECUTE FUNCTION del_practice_members();


-- checking TRIGGER
DELETE FROM practice_members
WHERE member_name = '';



/* Q7. Write a trigger that automatically updates the join_date column to the 
current date whenever a member’s name is updated in the practice_members table. 
- Condition: It should only update join_date if the member_name is changed (not for any other update).
- Action: Update join_date to CURRENT_DATE. */


CREATE OR REPLACE FUNCTION update_date()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if member_name is changed
    IF NEW.member_name IS DISTINCT FROM OLD.member_name THEN
        NEW.join_date := CURRENT_DATE;
        RAISE NOTICE 'Join date updated for member_id %', NEW.member_id;
    END IF;

    RETURN NEW;  -- Must return NEW in BEFORE trigger
END;
$$;

CREATE TRIGGER update_current_date
BEFORE UPDATE OF member_name ON practice_members
FOR EACH ROW
EXECUTE FUNCTION update_date();


-- checking trigger working or NOT
SELECT *
FROM practice_members;


UPDATE practice_members
SET member_name = 'Rajesh Rathore'
WHERE member_id = 2;



/* Q8. Create a trigger that prevents inserting a member if join_date is in the future 
(greater than the current date). If the date is valid, insert the record and log the 
action in practice_logs with action_type = 'Insert' and table_name = 'practice_members'. */


CREATE OR REPLACE FUNCTION date_equal()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
     IF NEW.join_date > CURRENT_DATE THEN
		 RAISE EXCEPTION 'join_date is greater than Today''s Date';
		 END IF;

		 INSERT INTO practice_logs(action_type, table_name, member_id, log_date)
		                    VALUES('Insert', 'practice_members', NEW.member_id, CURRENT_TIMESTAMP);

				RAISE NOTICE 'Record Inserted Successfully';
   RETURN NEW;
END;
$$;


CREATE TRIGGER insert_date
BEFORE INSERT ON practice_members
FOR EACH ROW
EXECUTE FUNCTION date_equal();


INSERT INTO practice_members
                     VALUES(3, 'Rahul Singh');

SELECT *
FROM practice_members;


SELECT * 
FROM practice_loans;



/* Q9. A trigger that prevents updating join_date manually after insert (it should stay as original date, not be changed). 
If someone tries to update join_date, raise an exception. */


CREATE OR REPLACE FUNCTION not_update_date()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.join_date != NEW.join_date THEN
		 RAISE EXCEPTION 'Manual update of join_date is not allowed'; 
    END IF;
	RETURN NULL;
END;
$$;


CREATE TRIGGER update_join_date
BEFORE UPDATE ON practice_members
FOR EACH ROW 
EXECUTE FUNCTION not_update_date()

-- disable trigger
DROP TRIGGER update_join_date ON practice_members;

-- checking trigger working or NOT
UPDATE practice_members
SET join_date = '2025-09-03'
WHERE member_id = 3;


SELECT *
FROM practice_members;



/* Q10. Write a trigger that prevents deleting a member if their join_date is 
less than 30 days from today. If the deletion is allowed, insert a log entry in 
practice_logs with action_type='Delete'. */


-- FUNCTION
CREATE OR REPLACE FUNCTION del_date()          s
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
		   IF OLD.join_date > CURRENT_DATE - INTERVAL '30 Days' THEN
			 RAISE EXCEPTION 'you can''t delete this member!!';
			 END IF;
			 
	   INSERT INTO practice_logs(action_type, table_name, member_id)
		                    VALUES('Delete', 'practice_members', OLD.member_id);
     RAISE NOTICE 'User deleted successfully!';
	   RETURN OLD;
END;
$$;

--TRIGGER
CREATE TRIGGER del_date_user
BEFORE DELETE ON practice_members
FOR EACH ROW
EXECUTE FUNCTION del_date();

DROP TRIGGER del_date_user ON practice_members;

-- checking trigger working or NOT
DELETE FROM practice_members
WHERE member_id = 3;


INSERT INTO practice_members()



/* Q11. Create an AFTER UPDATE trigger on practice_members that:
Checks if member_name actually changed (compare OLD vs NEW).
If yes → insert a log into practice_logs with:
- action_type = 'Name Changed'
- table_name = 'practice_members'
- member_id = NEW.member_id
- log_date = CURRENT_TIMESTAMP
- If the name did NOT change, do nothing. */


CREATE OR REPLACE FUNCTION name_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
      IF OLD.member_name <> NEW.member_name THEN 
			INSERT INTO practice_logs(action_type, table_name, member_id, log_date)
			                   VALUES('Name Changed', 'pracitce_members', NEW.member_id, CURRENT_TIMESTAMP);
      END IF;
			  RETURN NULL;
END;
$$;


CREATE TRIGGER name_changing
AFTER UPDATE ON practice_members
FOR EACH ROW 
EXECUTE FUNCTION name_change();


-- checking trigger working or NOT
UPDATE practice_members
SET member_name = 'Sagar Khanna'
WHERE member_id = '2';

SELECT *
FROM practice_logs;


SELECT *
FROM practice_members;



/* Q12. Create a BEFORE UPDATE trigger on practice_members that:
- If someone tries to update member_name with the same value, raise an exception.
- If the name actually changes, allow the update and log it in practice_logs with:
- action_type = 'Valid Name Update'. */


CREATE OR REPLACE FUNCTION duplicate_name()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.member_name = NEW.member_name THEN
		RAISE EXCEPTION 'Member name is already the same, update not needed';
		END IF;

		INSERT INTO practice_logs(action_type, table_name, member_id)
		                   VALUES('Valid Name Update', 'practice_members', OLD.member_id);
		RETURN NEW;
END;
$$;

CREATE TRIGGER duplicate_member_name
BEFORE UPDATE ON practice_members
FOR EACH ROW
EXECUTE FUNCTION duplicate_name();


-- checking trigger working or NOT
UPDATE practice_members
SET member_name = 'Gaurav Khan'
WHERE member_id = '1';


SELECT * 
FROM practice_members; 

SELECT * 
FROM practice_logs; 



/* Q13. Create a BEFORE INSERT trigger on practice_loans that:
- Sets loan_date to CURRENT_DATE if it’s NULL.
- Sets due_date to loan_date + 14 days automatically if it’s NULL.
- If both values are already provided, keep them as is.
*/


CREATE OR REPLACE FUNCTION loan_date()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- If loan_date is NULL, set it to CURRENT_DATE
    IF NEW.loan_date IS NULL THEN
        NEW.loan_date := CURRENT_DATE;
    END IF;

    -- If due_date is NULL, set it to loan_date + 14 days
    IF NEW.due_date IS NULL THEN
        NEW.due_date := NEW.loan_date + INTERVAL '14 days';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER null_date_change
BEFORE INSERT ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION loan_date();



INSERT INTO practice_loans(loan_id, member_id, loan_date, due_date)
VALUES (101, 1, NULL, NULL);

	 
SELECT *
FROM practice_loans;

INSERT INTO practice_loans(loan_id, member_id, loan_date, due_date)
VALUES (102, 2, '2025-08-29', NULL);



/* Q14. Create a trigger on the practice_loans table that prevents any loan record 
from being deleted if its due date has not passed yet.
- Condition: If due_date is greater than today's date, raise an exception.
- Task: If deletion is allowed, insert a log in practice_logs with:
action_type = 'Loan Deleted'
table_name = 'practice_loans'
member_id = OLD.member_id */


CREATE OR REPLACE FUNCTION not_and_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN 
		 IF OLD.due_date > CURRENT_DATE THEN
		 RAISE EXCEPTION 'You cannot delete a loan record before its due date!';
		 END IF;

		 INSERT INTO practice_logs(action_type, table_name, member_id)
		                    VALUES('Loan Delete', 'practice_loans', OLD.member_id);
		 RAISE NOTICE 'member_id: % deleted successfully', OLD.member_id;
     RETURN OLD;
END;
$$;


CREATE TRIGGER del_due_date
BEFORE DELETE ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION not_and_delete();


-- checking trigger working or NOT
DELETE FROM practice_loans
WHERE member_id = 1;



/* Q15. Create a trigger to automatically calculate and update the fine when a book is 
returned after its due date.
- If return_date > due_date, fine = (number of late days × 10).
- If return_date <= due_date, fine = 0.
- The trigger should work whenever return_date is updated in practice_loans. */


CREATE OR REPLACE FUNCTION fine_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
      IF NEW.return_date > NEW.due_date THEN 
			NEW.fine := (NEW.return_date - NEW.due_date) * 10;
			ELSE NEW.fine := 0;
      END IF;
			
			RETURN NEW;
END;
$$;


CREATE TRIGGER fine_on_date
BEFORE UPDATE OF return_date ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION fine_update();



-- checking trigger working or NOT
UPDATE practice_loans
SET return_date = '2025-09-04'
WHERE member_id = 1;



/* Q16. Create a trigger that prevents inserting a loan if the due_date is 
earlier than the loan_date.
- If someone tries to insert a record where due_date < loan_date,
- Raise an exception: 'Due date cannot be before loan date!'.
- Otherwise, allow the insert. */


CREATE OR REPLACE FUNCTION earlier_due_date()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN 
     IF NEW.due_date < NEW.loan_date THEN
		    RAISE EXCEPTION 'Due date cannot be before loan date!';
		 END IF;

		 RETURN NEW;
END;
$$;


CREATE TRIGGER earlier_date_stop
BEFORE INSERT ON practice_loans
FOR EACH ROW 
EXECUTE FUNCTION earlier_due_date();


-- checking TRIGGER working or NOT
-- it's working



/* Q17. Create a trigger that automatically calculates an additional penalty if 
a book is returned more than 30 days after the due_date.
- If return_date > due_date + INTERVAL '30 days', then:
- Add an extra penalty of ₹200 on top of the existing fine.
- If delay ≤ 30 days, no extra penalty.
- Trigger fires when return_date is updated. */


CREATE OR REPLACE FUNCTION addi_fine()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
      IF NEW.return_date > OLD.due_date + INTERVAL '30 days' THEN 
			NEW.fine := NEW.fine + 200;
			RAISE NOTICE 'You''re 30 days late than due_date. You''ve to pay additional fine!';
			END IF;
      RETURN NEW;
END;
$$;

CREATE TRIGGER extra_fine
BEFORE UPDATE ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION addi_fine();



-- checking TRIGGER working or NOT
UPDATE practice_loans
SET return_date = '2025-10-28'
WHERE loan_id = 5;



/* Q18. Write a trigger that raises an exception if someone tries to update a record in 
practice_loans where NEW.fine becomes greater than 500.
- If the fine is greater than 500, stop the update and show an error message. */


CREATE OR REPLACE FUNCTION fine_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
     IF NEW.fine > 500 THEN RAISE EXCEPTION 'Fine limit exceeded! Cannot update this record.';
     END IF;
		 RETURN NEW;
END;
$$;


CREATE TRIGGER fine_limit_500
BEFORE UPDATE ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION fine_limit();



/* Q19. Create a trigger on practice_loans that prevents changing the loan_date once it is set.
- If someone tries to update loan_date, the trigger should raise an exception saying:
"Loan date cannot be modified after creation."
- Other columns can still be updated normally. */


CREATE OR REPLACE FUNCTION fix_loan_date()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
     IF OLD.loan_date != NEW.loan_date THEN
		    RAISE EXCEPTION 'Loan date cannot be modified after creation.';
		 END IF;
		 RETURN NEW;
END;
$$;


CREATE TRIGGER loan_date_fix
BEFORE UPDATE ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION fix_loan_date();

DROP TRIGGER loan_date_fix ON practice_loans;

-- checking TRIGGER working ro NOT
UPDATE practice_loans
SET loan_date = '2025-09-05'
WHERE loan_id = 3;



/* Q20. Write a trigger that calculates the number of remaining days until the due date 
whenever the return_date is updated in the practice_loans table.
- If return_date is NULL, no calculation is needed.
- The calculation should be:
remaining_days = due_date - CURRENT_DATE */


CREATE OR REPLACE FUNCTION remaning_days()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    remaining_days INTEGER;
BEGIN
    IF NEW.return_date IS NOT NULL THEN
		remaining_days := (NEW.due_date - CURRENT_DATE);
		RAISE NOTICE 'Remaining days until due date: %', remaining_days;
		END IF;
		RETURN NEW;
END;
$$;


CREATE TRIGGER rem_days
AFTER UPDATE OF return_date ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION remaning_days();


-- drop TRIGGER
DROP TRIGGER rem_days ON practice_loans;

-- checking TRIGGER working or NOT
UPDATE practice_loans
SET return_date = NULL 
WHERE loan_id = 1;



/* Q21. Create a trigger that prevents inserting a loan record if loan_date is 
a weekend (Saturday or Sunday).
- If the loan_date falls on a weekend, raise an exception:
- "Loans cannot be issued on weekends!". */


CREATE OR REPLACE FUNCTION week_date()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
     IF TO_CHAR(NEW.loan_date, 'FMDay') = 'Saturday' OR TO_CHAR(NEW.loan_date, 'FMDay') = 'Sunday' THEN
		    RAISE EXCEPTION 'Loans cannot be issued on weekends!';
		 END IF;

		 RETURN NEW;
END;
$$;

CREATE TRIGGER excep_loan_date
BEFORE INSERT ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION week_date();

-- checking TRIGGER working or NOT
INSERT INTO practice_loans(member_id, loan_date)
VALUES(1, '2025-09-07');



/* Q22. Create a trigger that automatically sets return_date to CURRENT_DATE when a member 
returns the book and updates fine accordingly, but only if return_date was previously NULL. */


CREATE OR REPLACE FUNCTION return_current_date()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN 
      IF OLD.return_date IS NULL THEN NEW.return_date := CURRENT_DATE;
			END IF;

      RETURN NEW;
END;
$$;

CREATE TRIGGER return_date
BEFORE UPDATE OF return_date ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION return_current_date();


-- checking trigger working or NOT
UPDATE practice_loans
SET return_date = '2025-09-06'
WHERE loan_id = 1;



/* Q23. Create a trigger that prevents deleting a record from practice_loans if the 
book has not been returned yet (return_date IS NULL).
- If someone tries, show an error message:
- "Cannot delete! This loan is still active because the book is not returned." */


CREATE OR REPLACE FUNCTION donot_del()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
      IF OLD.return_date IS NULL THEN
			RAISE EXCEPTION '"Cannot delete! This loan is still active because the book is not returned.';
			END IF;
			RETURN NULL;
END;
$$;

CREATE TRIGGER dont_del_loan
BEFORE DELETE ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION donot_del();


-- checking trigger working or NOT
DELETE FROM practice_loans
WHERE loan_id = 10;



/* Q24. Create a trigger that logs any attempt to update the due_date field. 
The log should include:
- Action type: "Due Date Change Attempt"
- Table name: "practice_loans"
- Member ID (from the updated row)
- Old due date and new due date
- Insert this data into practice_logs. */


CREATE OR REPLACE FUNCTION log_loans()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
      INSERT INTO practice_logs(action_type, table_name, member_id)
			VALUES('Due Date changed from ' || OLD.due_date || ' to ' || NEW.due_date, 'practice_loans', NEW.member_id);

			RETURN NEW;
END;
$$;

CREATE TRIGGER log_in_loans
AFTER UPDATE OF due_date ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION log_loans();

-- checking TRIGGER working or NOT
UPDATE practice_loans
SET due_date = CURRENT_DATE
WHERE loan_id = 1;



/* Q25. Create a trigger that prevents updating loan_date OR due_date if the loan 
has already been returned (i.e., return_date is NOT NULL).
- If someone tries to update these dates, raise an exception:
- "Cannot update loan_date or due_date for a returned book!" */


CREATE OR REPLACE FUNCTION dont_update_loan()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
     IF OLD.return_date IS NOT NULL THEN
		 RAISE EXCEPTION 'Cannot update loan_date or due_date for a returned book!';
		 END IF;

		 RETURN NEW;
END;
$$;



CREATE TRIGGER not_update_loan
BEFORE UPDATE OF due_date, loan_date ON practice_loans
FOR EACH ROW
EXECUTE FUNCTION dont_update_loan();

-- DROP TRIGGER
DROP TRIGGER not_update_loan ON practice_loans;

-- checking TRIGGER working or NOT
UPDATE practice_loans
SET due_date = '2025-09-06'
WHERE loan_id = 4;



/* Q26. Create a trigger on practice_loans that will automatically log overdue books 
into practice_logs whenever a record is updated and the return_date is still NULL 
but the due_date has already passed today’s date.
- The trigger should insert into practice_logs with action_type = 'Overdue Loan'.
- The log should capture member_id, table_name, and the current timestamp. */


CREATE OR REPLACE FUNCTION due_logs()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.due_date < CURRENT_DATE AND OLD.return_date IS NULL THEN 
    RAISE NOTICE 'Due_Date is crossed today''s date';

		INSERT INTO practice_logs(action_type, table_name, member_id)
                       VALUES('Overdue Loan', 'practice_loans', NEW.member_id);
											 
		END IF;

		RETURN NEW;
END;
$$;

CREATE TRIGGER loan_due_logs
AFTER UPDATE ON practice_loans
FOR EACH ROW 
EXECUTE FUNCTION due_logs();



SELECT *
FROM practice_logs;

SELECT * 
FROM practice_loans;

SELECT * 
FROM practice_members;


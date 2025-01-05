-- Library_Managment_Task

-- ### 2. CRUD Operations

-- Task 1. Create a New Book Record
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO dbo.books
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- Task 2: Update an Existing Member's Address

UPDATE dbo.members
SET member_address = 'Atladara,Vadodara'
WHERE member_id = 'C119'

-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS104' from the issued_status table.

DELETE FROM dbo.issued_status
WHERE issued_id = 'IS104'

-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT issued_emp_id AS emp_id,
       issued_book_name AS Books 
FROM dbo.issued_status 
WHERE issued_emp_id = 'E101'


-- Task 5: List Members Who Have Issued More Than One Book
-- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT member_id,
       member_name,
       COUNT(issued_member_id) AS Book_issued_cnt
FROM dbo.issued_status I
JOIN dbo.members M
ON I.issued_member_id = M.member_id
GROUP BY member_id,member_name
HAVING COUNT(issued_member_id) > 1

-- ### 3. Data Analysis & Findings

-- Task 6. **Retrieve All Books in a Specific Category:

SELECT * 
FROM dbo.books
WHERE category = 'Classic'

-- Task 7: Find Total Rental Income by Category:

SELECT B.category,
       SUM(rental_price) AS Rental_income,
	   COUNT(issued_id) AS Book_issued_cnt
FROM dbo.books B
JOIN dbo.issued_status IB
ON B.isbn = IB.issued_book_isbn
GROUP BY B.category
ORDER BY Rental_income

-- Task 8. **List Members Who Registered in the Last 180 Days**:
--Updating some records with recent dates

UPDATE dbo.members
SET reg_date = '2024-11-01'
WHERE member_id = 'C118'

UPDATE dbo.members
SET reg_date = '2024-12-01'
WHERE member_id = 'C119'
-------

WITH cte_tbl1
AS
(
SELECT *,
      DATEDIFF(DD,reg_date,GETDATE()) AS Days_tillnow
FROM dbo.members
)
SELECT member_id,
       member_name
FROM cte_tbl1
WHERE Days_tillnow < 180

-- Task 9: List Employees with Their Branch Manager's Name and their branch details**:

SELECT E.emp_id,
       E.emp_name,
	   B.manager_id,
	   E2.emp_name AS Manager_name
FROM dbo.employees E 
    JOIN dbo.branch B 
	ON E.branch_id = B.branch_id
	JOIN dbo.employees E2
	ON E2.emp_id = B.manager_id	

-- Task 10. Create a View of Books with Rental Price Above a Certain Threshold

CREATE VIEW Vw_Expensive_books
AS
SELECT * 
FROM dbo.books
WHERE rental_price > 7

-- Task 11: Retrieve the List of Books Not Yet Returned

SELECT DISTINCT IST.issued_book_name AS Books_notreturn,
       IST.issued_book_isbn AS Book_isbn
FROM dbo.issued_status IST
    LEFT JOIN dbo.return_status RST
	ON IST.issued_id = RST.issued_id
WHERE RST.return_id IS NULL


 /*
 Task 12: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's name, book title, issue date, and days overdue.
*/

SELECT M.member_id,M.member_name,
       IS_.issued_book_name,IS_.issued_date,
   --  RS.return_date,
	   DATEDIFF(DAY,issued_date,GETDATE()) AS Overdue_Days
FROM dbo.issued_status IS_
    JOIN dbo.members M
	ON IS_.issued_member_id = M.member_id
	LEFT JOIN dbo.return_status RS
	ON RS.issued_id = IS_.issued_id
WHERE RS.return_date IS NULL
      AND
	  DATEDIFF(DAY,issued_date,GETDATE()) >30
ORDER BY M.member_id


/*
Task 13: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes"
when they are returned (based on entries in the return_status table).
*/

--Creation of SP
CREATE PROC add_return_records
(
 @P_return_id Varchar(10),
 @P_issued_id Varchar(10),
 @P_book_quality Varchar(15)
)
AS

DECLARE  @V_bookisbn Varchar(50),
         @V_booktitle Varchar(80)

BEGIN

	INSERT INTO dbo.return_status (return_id,issued_id,return_date,book_quality)
	VALUES (@P_return_id,@P_issued_id,CAST(GETDATE() AS date),@P_book_quality);

    SELECT   @V_bookisbn = issued_book_isbn,
	         @V_booktitle = issued_book_name
	FROM dbo.issued_status
	WHERE issued_id = @P_issued_id;

	UPDATE dbo.books 
	SET status = 'Yes'
	WHERE isbn = @V_bookisbn;

	PRINT concat('Thank you for returning the book : ', @V_booktitle);

END;


--Testing SP add_return_records 
--Book selected sapiens
SELECT *
FROM dbo.issued_status      
WHERE issued_id = 'IS135'      --The book is issued on 8-4-24

SELECT *
FROM dbo.return_status
WHERE issued_id = 'IS135'    --Result null indicating the book is not returned yet

SELECT *
FROM dbo.books                   -- Staus of book is no 
WHERE isbn = '978-0-307-58837-1' -- After exec procedure the status of book will chanege to yes indicating it's returned & now available  

--Using SP
EXEC add_return_records 'RS140','IS135','Good'


/*
Task 14: Create view of Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, 
the number of books returned, and the total revenue generated from book rentals.
*/

CREATE VIEW Vw_Branch_Performance
AS
SELECT B.branch_id,
       COUNT(IS_.issued_id) AS Books_issued,
	   COUNT(RS.return_id) AS Books_returned,
       SUM(BO.rental_price) AS Revenue_generated 
FROM dbo.branch B
    JOIN dbo.employees E 
	ON B.branch_id = E.branch_id
	JOIN dbo.issued_status IS_
	ON IS_.issued_emp_id = E.emp_id
	LEFT JOIN dbo.return_status RS
	ON RS.issued_id = IS_.issued_id
	JOIN dbo.books Bo
	ON Bo.isbn = IS_.issued_book_isbn
GROUP BY B.branch_id


/*
Task 15: Create a View of Active Members
Use view to create new table of active_members 
containing members who have issued at least one book in the last 2 months.
*/

SELECT M.member_id,M.member_name
FROM dbo.members M
    JOIN dbo.issued_status IS_  
	ON M.member_id = IS_.issued_member_id
WHERE DATEDIFF(MONTH,IS_.issued_date,GETDATE()) < 2

--OR
CREATE VIEW Vw_Active_Members
AS
SELECT * FROM members
WHERE member_id IN 
                   (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE DATEDIFF(MONTH,issued_date,GETDATE()) < 2
                    )

/*
Task 16: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues.
Display the employee name, number of books processed, and their branch.
*/

SELECT TOP 3
       B.branch_id,
       E.emp_name,
	   COUNT(IS_.issued_id) AS books_processed
FROM dbo.employees E
    JOIN dbo.branch B
	ON E.branch_id = B.branch_id
	JOIN dbo.issued_status IS_
	ON IS_.issued_emp_id = E.emp_id
GROUP BY B.branch_id,E.emp_name
ORDER BY books_processed DESC

/*
Task 17: Stored Procedure
Objective: Create a stored procedure to manage the status of books in a library system.
Description: Write a stored procedure that updates the status of a book based on its issuance or return.
Specifically:
    If a book is issued, the status should change to 'no'.
    If a book is returned, the status should change to 'yes'.
*/

CREATE PROC issue_books 
(
 @P_Issued_id Varchar(10),
 @P_Issued_member_id Varchar(10),
 @P_Issued_book_isbn Varchar(50),
 @P_issued_Emp_id Varchar(10)
)
AS

DECLARE @V_status Varchar(10);

BEGIN

	SELECT @V_status = [status]  
	FROM dbo.books
	WHERE isbn = @P_Issued_book_isbn;

	IF @V_status = 'Yes' 
	  BEGIN
		  INSERT INTO dbo.issued_status (issued_id,issued_member_id,issued_date,issued_book_isbn,issued_emp_id)
		  VALUES (@P_issued_id,@P_Issued_member_id,CAST(GETDATE() AS date),@P_Issued_book_isbn,@P_issued_Emp_id);

		  UPDATE dbo.books 
		  SET [status] = 'No'
		  WHERE isbn = @P_Issued_book_isbn;

		  PRINT CONCAT('Book record added successfuly for the book_isbn : ',@P_Issued_book_isbn);
	  END
    ELSE 
	  BEGIN
		   PRINT CONCAT('sorry to inform you the book you have requested is unavailable book_isbn : ',@P_Issued_book_isbn);
	  END
END


SELECT * FROM dbo.books
WHERE isbn = '978-0-553-29698-2'
--978-0-553-29698-2  'Yes'
--978-0-375-41398-8  'No'

EXEC dbo.issue_books 'IS155','C108','978-0-553-29698-2','E104'

EXEC dbo.issue_books 'IS156','C109','978-0-375-41398-8','E105'

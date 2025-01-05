-- INSERT INTO book_issued in last 30 days
-- SELECT * from employees;
-- SELECT * from books;
-- SELECT * from members;
-- SELECT * from issued_status


INSERT INTO issued_status(issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
VALUES
('IS151', 'C118', 'The Catcher in the Rye', CAST(DATEADD(D,-24,GETDATE()) AS DATE),  '978-0-553-29698-2', 'E108'),
('IS152', 'C119', 'The Catcher in the Rye', CAST(DATEADD(D,-24,GETDATE()) AS DATE),  '978-0-553-29698-2', 'E109'),
('IS153', 'C106', 'Pride and Prejudice', CAST(DATEADD(D,-24,GETDATE()) AS DATE),  '978-0-14-143951-8', 'E107'),
('IS154', 'C105', 'The Road', CAST(DATEADD(D,-24,GETDATE()) AS DATE),  '978-0-375-50167-0', 'E101');

-- Adding new column in return_status

ALTER TABLE dbo.return_status
ADD book_quality VARCHAR(15) DEFAULT('Good');

UPDATE return_status
SET book_quality = 'Damaged'
WHERE issued_id 
    IN ('IS112', 'IS117', 'IS118');
SELECT * FROM return_status;

--Use below query coz default value 'Good' didn't get inserted in column
/*
UPDATE return_status
SET book_quality = 'Good'
WHERE book_quality IS NULL 
*/

--SELECT CAST(GETDATE() AS date)
--SELECT CAST(DATEADD(D,-5,GETDATE()) AS DATE)

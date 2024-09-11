CREATE TABLE UPI_Transaction (
    Transaction_ID VARCHAR(255),
    Time_stamp TIMESTAMP,
    Sender_Name VARCHAR(255),
    Sender_UPI_ID VARCHAR(255),
    Receiver_Name VARCHAR(255),
    Receiver_UPI_ID VARCHAR(255),
    Amount_INR DECIMAL(10,2),
    Status VARCHAR(50)
);


SELECT * from upi_transaction

COPY UPI_transaction
FROM 'D:\transactions.csv'
DELIMITER ','
CSV HEADER
	
--Removed Duplicates----
DELETE FROM UPI_Transaction
WHERE Transaction_ID IN (
    SELECT Transaction_ID
    FROM UPI_Transaction
    GROUP BY Transaction_ID
    HAVING COUNT(*) > 1
);


ALTER TABLE UPI_Transaction
ADD Transaction_Date DATE,
ADD Transaction_Hour INT;

UPDATE UPI_Transaction
SET Transaction_Date = CAST(Time_stamp AS DATE),
    Transaction_Hour = EXTRACT(HOUR FROM Time_stamp);

--Q1: Find the total number of transactions and the average transaction amount for each sender. Exclude failed transactions.

SELECT Sender_Name, 
       COUNT(*) AS total_transactions, 
       AVG(Amount_INR) AS avg_transaction_amount
FROM UPI_Transaction
WHERE Status = 'SUCCESS'
GROUP BY Sender_Name
ORDER BY total_transactions DESC;


--Q2: Identify the hour of the day (Transaction_Hour) with the highest total transaction amount.

SELECT Transaction_Hour, 
       SUM(Amount_INR) AS total_amount
FROM UPI_Transaction
WHERE Status = 'SUCCESS'
GROUP BY Transaction_Hour
ORDER BY total_amount DESC
LIMIT 1;


---Q3: Calculate the transaction success rate for each sender. Return the sender's name, total transactions, successful transactions, and success rate (as a percentage).
SELECT Sender_Name, 
       COUNT(*) AS total_transactions,
       SUM(CASE WHEN Status = 'SUCCESS' THEN 1 ELSE 0 END) AS successful_transactions,
       (SUM(CASE WHEN Status = 'SUCCESS' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS success_rate
FROM UPI_Transaction
GROUP BY Sender_Name
ORDER BY success_rate DESC;

---Q4: Find the day with the highest number of transactions.

SELECT Transaction_Date, 
COUNT(*) AS total_transactions
FROM UPI_Transaction
GROUP BY Transaction_Date
ORDER BY total_transactions DESC
LIMIT 1;


--Q5: For each pair of sender and receiver, find the total number of transactions between them and the total amount transacted.

SELECT Sender_Name, 
       Receiver_Name, 
       COUNT(*) AS total_transactions, 
       SUM(Amount_INR) AS total_amount
FROM UPI_Transaction
WHERE Status = 'SUCCESS'
GROUP BY Sender_Name, Receiver_Name
ORDER BY total_transactions DESC;

--Q6: Find all the transactions where the amount is greater than twice the average transaction amount.

WITH avg_amount AS (
    SELECT AVG(Amount_INR) AS avg_transaction
    FROM UPI_Transaction
    WHERE Status = 'SUCCESS'
)
SELECT * 
FROM UPI_Transaction, avg_amount
WHERE Amount_INR > 2 * avg_transaction
AND Status = 'SUCCESS';


---Q7: Calculate the percentage of failed transactions for each day.

SELECT Transaction_Date, 
       (SUM(CASE WHEN Status = 'FAILED' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS failed_percentage
FROM UPI_Transaction
GROUP BY Transaction_Date
ORDER BY failed_percentage DESC;


--Q8: List the top 5 sender-receiver pairs based on the number of successful transactions.

SELECT Sender_Name, 
       Receiver_Name, 
       COUNT(*) AS transaction_count
FROM UPI_Transaction
WHERE Status = 'SUCCESS'
GROUP BY Sender_Name, Receiver_Name
ORDER BY transaction_count DESC
LIMIT 5;


--Q9: For each day, find the largest single successful transaction amount.

SELECT Transaction_Date, 
       MAX(Amount_INR) AS largest_transaction
FROM UPI_Transaction
WHERE Status = 'SUCCESS'
GROUP BY Transaction_Date
ORDER BY Transaction_Date;

---Q10: Find the sender who has transferred the highest total amount. Also, return the total amount transferred by that sender.

SELECT Sender_Name, 
       SUM(Amount_INR) AS total_transferred
FROM UPI_Transaction
WHERE Status = 'SUCCESS'
GROUP BY Sender_Name
ORDER BY total_transferred DESC
LIMIT 1;

---Q12: Calculate the total amount transferred for each bank, identified by the bank identifier in the Sender_UPI_ID (e.g., '@okaxis', '@oksbi'). Group the results by the bank identifier and return the total transaction amount per bank.

SELECT SUBSTRING(Sender_UPI_ID FROM POSITION('@' IN Sender_UPI_ID)) AS Bank_Identifier, 
       SUM(Amount_INR) AS total_transferred
FROM UPI_Transaction
WHERE Status = 'SUCCESS'
GROUP BY Bank_Identifier
ORDER BY total_transferred DESC;

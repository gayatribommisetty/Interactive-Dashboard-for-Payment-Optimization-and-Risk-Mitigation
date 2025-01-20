-- Use the database containing the transaction data
USE Credit_card_data;

-- Display all rows and columns from the table to inspect the data
SELECT * FROM multi_channel_payment_transactions_final;

-- Rename the table to "transactions" for easier reference and future queries
RENAME TABLE multi_channel_payment_transactions_final TO transactions;

-- Verify that the table was successfully renamed
SELECT * FROM transactions;

-- Count the total number of rows to understand the dataset size
SELECT COUNT(*) FROM transactions;

-- Retrieve a list of all unique payment methods used in the transactions
SELECT DISTINCT PaymentMethod FROM transactions;

-- Retrieve a list of all unique regions where transactions took place
SELECT DISTINCT Region FROM transactions;

-- Find transactions where either TransactionAmount or ProcessingFee is NULL
-- Useful for identifying incomplete or corrupted data
SELECT * FROM transactions WHERE TransactionAmount IS NULL OR ProcessingFee IS NULL;

-- Calculate the total revenue generated across all transactions
-- Revenue = TransactionAmount - ProcessingFee
SELECT ROUND(SUM(Revenue),2) AS TotalRevenue FROM transactions;

-- Calculate the average profit per payment method
-- Helps to identify which payment methods are the most profitable
SELECT PaymentMethod, ROUND(AVG(Profit),2) AS AvgProfit
FROM transactions
GROUP BY PaymentMethod;

-- Count the number of transactions grouped by region
-- Sort by the highest number of transactions to identify the busiest regions
SELECT Region, COUNT(*) AS TotalTransactions
FROM transactions
GROUP BY Region
ORDER BY TotalTransactions DESC;

-- Calculate the fraud rate for each region
-- FraudRate = (Number of fraudulent transactions / Total transactions) * 100
SELECT Region, 
       COUNT(*) AS TotalTransactions,
       SUM(FraudStatus) AS FraudulentTransactions,
       (SUM(FraudStatus) * 100.0 / COUNT(*)) AS FraudRate
FROM transactions
GROUP BY Region
ORDER BY FraudRate DESC;

-- Calculate the fraud rate for each payment method
-- Useful for identifying high-risk payment methods
SELECT PaymentMethod, 
       COUNT(*) AS TotalTransactions,
       SUM(FraudStatus) AS FraudulentTransactions,
       (SUM(FraudStatus) * 100.0 / COUNT(*)) AS FraudRate
FROM transactions
GROUP BY PaymentMethod
ORDER BY FraudRate DESC;

-- Calculate the total profit grouped by region
-- Sort by the highest profit to find the most profitable regions
SELECT Region, ROUND(SUM(Profit)) AS TotalProfit
FROM transactions
GROUP BY Region
ORDER BY TotalProfit DESC;

-- Calculate monthly revenue trends and sort by month
-- Useful for understanding revenue seasonality or trends over time
SELECT DATE_FORMAT(TransactionDate, '%Y-%m') AS Month, SUM(Revenue) AS TotalRevenue
FROM transactions
GROUP BY Month
ORDER BY Month;

-- Count the number of transactions for each day and sort by date
-- Useful for analyzing daily transaction volume
SELECT DATE(TransactionDate) AS Date, COUNT(*) AS DailyTransactions
FROM transactions
GROUP BY Date
ORDER BY Date;

-- Identify the top 10 customers based on their total revenue
-- Useful for targeting high-value customers for loyalty programs or promotions
SELECT CustomerID, SUM(Revenue) AS TotalRevenue
FROM transactions
GROUP BY CustomerID
ORDER BY TotalRevenue DESC
LIMIT 10;

-- Count the total number of transactions for each customer segment (e.g., Premium or Regular)
-- Useful for understanding the contribution of different customer segments
SELECT CustomerSegment, COUNT(*) AS TransactionCount
FROM transactions
GROUP BY CustomerSegment;

-- Rank transactions within each region based on their revenue
-- Useful for identifying high-value transactions in each region
SELECT 
    TransactionID, 
    Region, 
    Revenue, 
    RANK() OVER (PARTITION BY Region ORDER BY Revenue DESC) AS RevenueRank
FROM transactions;

-- Calculate cumulative revenue for each region over time
-- Helps visualize revenue growth within regions
SELECT 
    Region, 
    TransactionDate, 
    SUM(Revenue) OVER (PARTITION BY Region ORDER BY TransactionDate) AS CumulativeRevenue
FROM transactions;

-- Identify payment methods with above-average profits using a CTE
-- CTE simplifies the query structure for complex operations
WITH AvgProfit AS (
    SELECT 
        PaymentMethod, 
        AVG(Profit) AS AvgProfit
    FROM transactions
    GROUP BY PaymentMethod
)
SELECT * 
FROM AvgProfit
WHERE AvgProfit > (SELECT AVG(Profit) FROM transactions);

-- Identify transactions where revenue exceeds the regional average revenue
-- This uses a CTE for calculating average regional revenue
WITH RegionalAvg AS (
    SELECT 
        Region, 
        AVG(Revenue) AS AvgRegionalRevenue
    FROM transactions
    GROUP BY Region
)
SELECT t.*
FROM transactions t
JOIN RegionalAvg r ON t.Region = r.Region
WHERE t.Revenue > r.AvgRegionalRevenue;

-- Calculate fraud rates grouped by customer segment and region
-- Helps identify high-risk customer segments in specific regions
SELECT 
    CustomerSegment, 
    Region, 
    SUM(FraudStatus) AS TotalFraud,
    COUNT(*) AS TotalTransactions,
    (SUM(FraudStatus) * 100.0 / COUNT(*)) AS FraudRate
FROM transactions
GROUP BY CustomerSegment, Region
ORDER BY FraudRate DESC;

-- Calculate monthly revenue trends and the percentage change compared to the previous month
-- Useful for identifying revenue growth or decline over time
SELECT 
    DATE_FORMAT(TransactionDate, '%Y-%m') AS Month, 
    SUM(Revenue) AS TotalRevenue,
    LAG(SUM(Revenue)) OVER (ORDER BY DATE_FORMAT(TransactionDate, '%Y-%m')) AS PreviousMonthRevenue,
    (SUM(Revenue) - LAG(SUM(Revenue)) OVER (ORDER BY DATE_FORMAT(TransactionDate, '%Y-%m'))) / LAG(SUM(Revenue)) OVER (ORDER BY DATE_FORMAT(TransactionDate, '%Y-%m')) * 100 AS PercentChange
FROM transactions
GROUP BY DATE_FORMAT(TransactionDate, '%Y-%m');

-- Identify regions with fraud rates higher than the global average fraud rate
-- Uses the HAVING clause to filter by fraud rate
SELECT Region, 
       SUM(FraudStatus) AS TotalFraud, 
       COUNT(*) AS TotalTransactions,
       (SUM(FraudStatus) * 100.0 / COUNT(*)) AS FraudRate
FROM transactions
GROUP BY Region
HAVING FraudRate > (SELECT (SUM(FraudStatus) * 100.0 / COUNT(*)) FROM transactions);

-- Create a pivot table for revenue by payment method and region
-- Useful for summarizing revenue distribution across regions and payment methods
SELECT 
    Region,
    SUM(CASE WHEN PaymentMethod = 'Credit Card' THEN Revenue ELSE 0 END) AS CreditCardRevenue,
    SUM(CASE WHEN PaymentMethod = 'Debit Card' THEN Revenue ELSE 0 END) AS DebitCardRevenue,
    SUM(CASE WHEN PaymentMethod = 'PayPal' THEN Revenue ELSE 0 END) AS PayPalRevenue
FROM transactions
GROUP BY Region;

-- Create an index on the Region column to optimize query performance
-- A key length of 50 is specified to handle TEXT data types
CREATE INDEX idx_region ON transactions (Region(50));

-- Explain the execution plan for a query filtering by region
-- Useful for understanding how MySQL executes the query
EXPLAIN SELECT * FROM transactions WHERE Region = 'North America';

-- Categorize transaction amounts into Low, Medium, and High
-- Useful for understanding fraud patterns by transaction size
SELECT 
    CASE 
        WHEN TransactionAmount < 100 THEN 'Low'
        WHEN TransactionAmount BETWEEN 100 AND 500 THEN 'Medium'
        ELSE 'High'
    END AS AmountCategory,
    COUNT(*) AS TotalTransactions,
    SUM(FraudStatus) AS FraudulentTransactions,
    (SUM(FraudStatus) * 100.0 / COUNT(*)) AS FraudRate
FROM transactions
GROUP BY AmountCategory
ORDER BY FraudRate DESC;

-- Calculate the average profit by customer segment and payment method
-- Helps to identify the most profitable combinations of customer type and payment method
SELECT 
    CustomerSegment,
    PaymentMethod,
    ROUND(AVG(Profit), 2) AS AvgProfit
FROM transactions
GROUP BY CustomerSegment, PaymentMethod
ORDER BY AvgProfit DESC;

-- Calculate the total revenue for premium customers grouped by region
-- Useful for identifying high-performing regions for premium customers
SELECT 
    Region, 
    SUM(Revenue) AS TotalRevenue
FROM transactions
WHERE CustomerSegment = 'Premium'
GROUP BY Region
ORDER BY TotalRevenue DESC;

-- Calculate monthly profit and the growth compared to the previous month
-- Useful for tracking profit growth trends
SELECT 
    DATE_FORMAT(TransactionDate, '%Y-%m') AS Month,
    SUM(Profit) AS MonthlyProfit,
    SUM(Profit) - LAG(SUM(Profit)) OVER (ORDER BY DATE_FORMAT(TransactionDate, '%Y-%m')) AS ProfitGrowth
FROM transactions
GROUP BY DATE_FORMAT(TransactionDate, '%Y-%m');

-- Calculate processing fees, total revenue, and total profit grouped by payment method
-- Useful for understanding the cost and revenue dynamics of each payment method
SELECT 
    PaymentMethod,
    ROUND(SUM(ProcessingFee), 2) AS TotalProcessingFees,
    ROUND(SUM(Revenue), 2) AS TotalRevenue,
    ROUND(SUM(Profit), 2) AS TotalProfit
FROM transactions
GROUP BY PaymentMethod
ORDER BY TotalProcessingFees DESC;

-- Calculate the cost-to-revenue ratio for each payment method
-- Useful for identifying the efficiency of payment methods
SELECT 
    PaymentMethod,
    ROUND(SUM(ProcessingFee) / SUM(Revenue) * 100, 2) AS CostToRevenueRatio
FROM transactions
GROUP BY PaymentMethod
ORDER BY CostToRevenueRatio ASC;

SHOW VARIABLES LIKE 'secure_file_priv';

SELECT * FROM transactions;
[mysqld]
secure-file-priv="";



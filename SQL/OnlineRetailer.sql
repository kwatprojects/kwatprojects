-- Data exploratory and performance evaluation of this online retailer based in UK

-- this dataset can be found on Kaggle: https://www.kaggle.com/datasets/ulrikthygepedersen/online-retail-dataset/data

-- DATA EXPLORATION: UNDERSTANDING THE DATASET --
-- dateset date range: 2010-12-01 08:26:00 UTC through 2011-12-09 12:50:00 UTC
SELECT MIN(InvoiceDate) AS MinDate
  ,MAX(InvoiceDate) AS MaxDate
FROM Online_Retail.transactions
;


-- dateset date range: 2010-12-01 08:26:00 UTC through 2011-12-09 12:50:00 UTC
SELECT MIN(Quantity) AS MinDate
  ,MAX(Quantity) AS MaxDate
FROM Online_Retail.transactions
;


-- number of distinct orders: 22064
SELECT  count(distinct InvoiceNo),
FROM Online_Retail.transactions
WHERE lower(InvoiceNo) NOT LIKE 'c%'
;


-- number of transaction: 532621
SELECT count(InvoiceNo)
FROM Online_Retail.transactions
WHERE lower(InvoiceNo) NOT LIKE 'c%'
;


-- number of canceled transactions: 9288
SELECT count(InvoiceNo)
FROM Online_Retail.transactions
WHERE lower(InvoiceNo) LIKE 'c%'
; 


-- number of countries: 38
SELECT count(distinct Country)
FROM Online_Retail.transactions
WHERE lower(InvoiceNo) NOT LIKE 'c%'
;


-- number of products: 4059
SELECT count(distinct StockCode)
FROM Online_Retail.transactions
WHERE lower(InvoiceNo) NOT LIKE 'c%'
;


-- number of items sold: 5454024
SELECT sum(Quantity)
FROM Online_Retail.transactions
WHERE lower(InvoiceNo) NOT LIKE 'c%'
;


-- number of items sold by country
SELECT Country
  ,sum(Quantity) AS items
FROM Online_Retail.transactions
WHERE lower(InvoiceNo) NOT LIKE 'c%'
GROUP BY Country
ORDER BY items desc
;


-- SALES PERFORMANCE --
-- number of items sold by year
with years AS 
  (SELECT *,extract(year from InvoiceDate) AS year
  FROM Online_Retail.transactions
  )

SELECT years.year
  ,sum(Quantity) AS items
FROM years
WHERE lower(InvoiceNo) NOT LIKE 'c%'
GROUP BY years.year
ORDER BY items desc
;

-- most bought items by year
with years AS 
  (SELECT *
    ,extract(year from InvoiceDate) AS year
  FROM Online_Retail.transactions
  WHERE lower(StockCode) NOT LIKE '%c%' AND
    Quantity > 0
  )
  
SELECT StockCode, Description
  ,year
  ,RANK() OVER( PARTITION BY years.year ORDER BY sum(Quantity) DESC) AS ranking
  ,Sum(Quantity) as items
  FROM years
  WHERE lower(InvoiceNo) NOT LIKE 'c%'
  GROUP BY year, StockCode, Description
  ORDER BY ranking, year
  LIMIT 10
;

-- Most returned items by year
-- VANILLA SCENT CANDLE JEWELLED BOX (StockCode 72802C) was the most returned item in 2011, with 505 items returned.
with years AS 
  (SELECT *
    ,extract(year from InvoiceDate) AS year
  FROM Online_Retail.transactions
  WHERE lower(StockCode) LIKE '%c%' AND
    Quantity < 0
  )
  
SELECT StockCode, Description
  ,year
  ,RANK() OVER( PARTITION BY years.year ORDER BY sum(Quantity) ) AS ranking
  ,Sum(Quantity) as items
  FROM years
  WHERE lower(InvoiceNo) LIKE '%c%'
  GROUP BY year, StockCode, Description
  ORDER BY ranking, year
  LIMIT 10
;

-- Return rate of VANILLA SCENT CANDLE JEWELLED BOX (StockCode 72802C) in 2011
-- Return rate was 39%
with 
Base AS (
  SELECT *
  FROM Online_Retail.transactions
  WHERE StockCode = '72802C'
    AND Description = 'VANILLA SCENT CANDLE JEWELLED BOX'
    AND EXTRACT(YEAR FROM InvoiceDate) = 2011
),

R AS (
  SELECT StockCode
    ,Description
    ,abs(sum(Quantity)) AS Return
  FROM Base
  WHERE lower(InvoiceNo) LIKE '%c%'
  GROUP BY StockCode, Description
),

P AS(
  SELECT StockCode
    ,Description
    ,sum(Quantity) AS Purchase
  FROM Base
  WHERE lower(InvoiceNo) NOT LIKE '%c%'
  GROUP BY StockCode, Description
)

SELECT R.StockCode
  ,R.Description
  ,ROUND(R.Return/P.Purchase, 2) AS Return_Rate
FROM R
JOIN P ON R.StockCode = P.StockCode
;


-- Highest revenue product
with base AS (
  SELECT *
    ,Quantity*UnitPrice AS Revenue
  FROM Online_Retail.transactions
  WHERE extract(YEAR FROM InvoiceDate) = 2011
    AND CustomerID IS NOT NULL
    AND StockCode <> 'POST'
)

SELECT StockCode
  ,Description
  ,SUM(Quantity) AS Quantity
  ,ROUND(Avg(UnitPrice),2) AS Avg_UnitPrice
  ,ROUND(SUM(Revenue),2) AS Sales
FROM base
GROUP BY StockCode, Description
ORDER BY Sales DESC
;


-- Largest customer
-- Largest customer was from the Netherlands, who purchased over 189k items and contributed over $269k in sales.
with base AS (
  SELECT *
    ,Quantity*UnitPrice AS Revenue
  FROM Online_Retail.transactions
  WHERE extract(YEAR FROM InvoiceDate) = 2011
    AND CustomerID IS NOT NULL
    AND StockCode <> 'POST'
)

SELECT CustomerID
  ,Country
  ,SUM(Quantity) AS items_purchased
  ,ROUND(SUM(Revenue),2) AS Sales
FROM base
GROUP BY CustomerID, Country
ORDER BY Sales DESC
;

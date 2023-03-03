

USE E_Commers_Projekt ;


/*
Analyze the data by finding the answers to the questions below:
*/

/*
1. Using the columns of “market_fact”, “cust_dimen”, “orders_dimen”, 
	“prod_dimen”, “shipping_dimen”, Create a new table, named as
	“combined_table”. 
*/

CREATE VIEW combined_table
AS
SELECT	
		C.First_name,
		C.Last_name,
		C.Region,
		C.Customer_Segment,
		
		P.Prod_Main_id,
		P.Product_Sub_Category,
		
		O.Order_Date,
		O.Order_Priority,

		S.Order_ID,
		S.Ship_Mode,
		S.Ship_Date,
		
		M.Ship_id,
		M.Ord_id,
		M.Prod_id,
		M.Cust_id,
		M.Sales,
		M.Discount,
		M.Order_Quantity,
		M.Product_Base_Margin
FROM dbo.market_fact M
LEFT JOIN	dbo.prod_dimen P ON M.Prod_id = P.Prod_id
LEFT JOIN	dbo.orders_dimen O ON M.Ord_id = O.Ord_id
LEFT JOIN	dbo.shipping_dimen S ON M.Ship_id = S.Ship_id
LEFT JOIN	dbo.cust_dimen C ON M.Cust_id = C.Cust_id
;

SELECT TOP	10 *
FROM		combined_table
;

/*
2. Find the top 3 customers who have the maximum count of orders.
*/

SELECT TOP	3 Cust_id, First_name, Last_name, COUNT(Ord_id) AS cnt_ord
FROM		combined_table
GROUP BY	Cust_id, First_name, Last_name
ORDER BY	cnt_ord DESC
;

/*
3. Create a new column at combined_table as DaysTakenForDelivery 
	that contains the date difference of Order_Date and Ship_Date.
*/

SELECT		*, DATEDIFF(DAY, Order_Date, Ship_Date) DaysTakenForDelivery
FROM		combined_table
;

-----------------------------------------------------------------------
/*
4. Find the customer whose order took the maximum time to get delivered.
*/

SELECT TOP		1 First_name, Last_name, Order_ID, Order_Priority, Order_Date, Ship_Date, 
				DATEDIFF(DAY, Order_Date, Ship_Date) DaysTakenForDelivery
FROM			combined_table
ORDER BY		DaysTakenForDelivery DESC
;

----------------------------------------------------------------------
/*
5. Count the total number of unique customers in January
	and how many of them came back every month over the entire year in 2011.
*/

SELECT	MONTH(Order_Date) Month_2011, 
		COUNT(DISTINCT Cust_id) Order_Counts
FROM	combined_table
WHERE	Cust_id IN
		(
		SELECT DISTINCT Cust_id
		FROM	combined_table
		WHERE	YEAR(Order_Date) = 2011 
		AND		MONTH(Order_Date) = 1
		)
AND		 YEAR(Order_Date) = 2011 
GROUP BY MONTH(Order_Date)
;

----------------------------------------------------------------------
/*
6. Write a query to return for each user the time elapsed between the first purchasing 
	and the third purchasing, in ascending order by Customer ID.
*/

SELECT	Cust_id,
		DATEDIFF(DAY, first_order, third_order) date_diff
FROM	(
		SELECT	C.Cust_id, O.Ord_id,
				MIN(O.Order_Date)	OVER (PARTITION BY C.Cust_id ORDER BY O.Order_Date) first_order,
				LEAD(Order_Date, 2) OVER (PARTITION BY C.Cust_id ORDER BY O.Order_Date) third_order,
				ROW_NUMBER()		OVER (PARTITION BY C.Cust_id ORDER BY O.Order_Date) row_num
		FROM	orders_dimen O, market_fact M, cust_dimen C
		WHERE	O.Ord_id = M.Ord_id
		AND		M.Cust_id = C.Cust_id
		) A
WHERE	row_num = 1
AND		DATEDIFF(DAY, first_order, third_order) IS NOT NULL

-----------------------------------------------------------
/*
7. Write a query that returns customers who purchased both product 11 and product 14, 
	as well as the ratio of these products to the total number of products purchased by the customer.
*/


WITH RatioTable 
AS (
SELECT Cust_id ,
		SUM(CASE WHEN Prod_id = 11 THEN order_quantity else 0 end) Sum_prod11,
		SUM(CASE WHEN Prod_id = 14 THEN order_quantity else 0 end) Sum_prod14,
		SUM (Order_Quantity) Sum_prod
FROM combined_table
GROUP BY Cust_id
HAVING	SUM(CASE WHEN Prod_id = 11 THEN order_quantity else 0 end) >= 1
AND		SUM(CASE WHEN Prod_id = 14 THEN order_quantity else 0 end) >= 1
	)
SELECT Cust_id,sum_prod11,sum_prod14,	
		CAST (1.0*sum_prod11 / sum_prod AS NUMERIC (3,2)) AS Ratio_p11,
		CAST (1.0*sum_prod14 / sum_prod AS NUMERIC (3,2)) AS Ratio_p14
FROM RatioTable;


---------------- CUSTOMER SEGMENTATION --------------------

/*
Categorize customers based on their frequency of visits. The following steps will guide you. 
	If you want, you can track your own way.
*/

/*
1. Create a “view” that keeps visit logs of customers on a monthly basis. 
	(For each log, three field is kept: Cust_id, Year, Month)
*/

CREATE VIEW VisitLog
AS
(
	SELECT		Year(Order_Date) as year_of_order, 
				Month(Order_Date) as month_of_order, 
				Cust_id
	FROM		combined_table
	GROUP BY	Cust_id, Year(Order_Date), Month(Order_Date)
)
;

SELECT		*
FROM		VisitLog
ORDER BY	1, 2, 3
;

----------------------------------------------------------
/*
2. Create a “view” that keeps the number of monthly visits by users. 
	(Show separately all months from the beginning business)
*/

CREATE VIEW MonthlyVisit AS
(
	SELECT		Cust_id, First_name, Last_name, 
				YEAR(Order_Date) AS Order_year, 
				MONTH(Order_Date) AS Order_month,
				COUNT (Order_Date) monthly_visit_num
	FROM		combined_table
	GROUP BY	Cust_id,First_name, Last_name, YEAR(Order_Date), MONTH (Order_Date)
)
;

SELECT	*
FROM	[dbo].[MonthlyVisit]
;

-----------------------------------------------------------
/*
3. For each visit of customers, create the next month of the visit as a separate column.
*/

SELECT DISTINCT Cust_id, First_name, Last_name, 
				YEAR(Order_Date) AS Order_year, 
				MONTH(Order_Date) AS Order_month,
				LEAD(Order_Date) OVER(PARTITION BY Cust_id ORDER BY Order_Date) Next_Visit
FROM			combined_table
GROUP BY		Cust_id, First_name, Last_name, Order_Date
;

-----------------------------------------------------------
/*
4. Calculate the monthly time gap between two consecutive visits by each customer.
*/

SELECT	*,
		DATEDIFF(MONTH, Order_Date, Next_Visit) Time_Gap
FROM
		(
		SELECT		M.Cust_id, O.Order_Date, 
					LEAD(Order_Date) OVER(PARTITION BY Cust_id ORDER BY Order_Date) Next_Visit
		FROM		market_fact M, orders_dimen O
		WHERE		M.Ord_id = O.Ord_id
		) A

-----------------------------------------------------------
/*
5. Categorise customers using average time gaps. 
	Choose the most fitted labeling model for you.

For example: 
o Labeled as churn if the customer hasn't made another purchase 
	in the months since they made their first purchase.
o Labeled as regular if the customer has made a purchase every month. Etc.
*/

CREATE VIEW TimeGapsAsMonth
AS
SELECT	*,
		DATEDIFF(MONTH, Order_Date, next_visit) Time_Gap
FROM
		(
		SELECT		M.Cust_id, O.Order_Date, 
					LEAD(Order_Date) OVER(PARTITION BY Cust_id ORDER BY Order_Date) Next_Visit
		FROM		market_fact M, orders_dimen O
		WHERE		M.Ord_id = O.Ord_id
		) A

CREATE VIEW TotalAvgGap
AS
SELECT AVG(Avg_Time_Gap*1.0) Avg_Gap
FROM
	(
	SELECT Cust_id, AVG(Time_Gap) Avg_Time_Gap
	FROM  TimeGapsAsMonth
	GROUP BY Cust_id
	) A
;

SELECT cust_id, Avg_Time_Gap,
	CASE
		WHEN Avg_Time_Gap <= (SELECT * FROM TotalAvgGap) THEN 'Regular'
		WHEN (Avg_Time_Gap > (SELECT * FROM TotalAvgGap)) or (avg_time_gap IS NULL) THEN 'Churn'
	END Cust_Avg_Time_Gaps
FROM 
		(
		SELECT		Cust_id, AVG(Time_Gap) Avg_Time_Gap
		FROM		TimeGapsAsMonth
		GROUP BY	Cust_id
		) A


---------------- MONTH-WISE RETENTION RATE ------------------------

/*
Find month-by-month customer retention rate since the start of the business.
There are many different variations in the calculation of Retention Rate. 
But we will try to calculate the month-wise retention rate in this project.
So, we will be interested in how many of the customers in the previous month could 
	be retained in the next month.
Proceed step by step by creating “views”. You can use the view you got 
	at the end of the Customer Segmentation section as a source.
*/

/*
1. Find the number of customers retained month-wise. (You can use time gaps)
*/

CREATE VIEW MonthWiseRetention AS
SELECT DISTINCT	*,
				COUNT(Cust_id)	OVER (PARTITION BY Next_Visit ORDER BY Cust_id, Next_Visit) Retention_Month
FROM			TimeGapsAsMonth
WHERE			Time_Gap = 1
;

SELECT		COUNT(Retention_Month) Montly_Retained_Customers
FROM		MonthWiseRetention
GROUP BY	Time_Gap
;


/*
2. Calculate the month-wise retention rate.
Month-Wise Retention Rate = 
	1.0 * Number of Customers Retained in The Current Month / 
									Total Number of Customers in the Current Month
If you want, you can track your own way.
*/

CREATE VIEW RetainedOnes
AS
SELECT	Cust_id, 
		Month(Order_Date) AS Month_of_Order,
		YEAR(Order_Date) AS Year_of_Order,
		Time_Gap,
		CASE
			WHEN time_gap = 1 THEN 'Retained'
		END AS Retained
FROM  TimeGapsAsMonth
;


SELECT	*
FROM	RetainedOnes
;


CREATE VIEW MontlyTotalRetained
AS
SELECT	Year_of_Order,
		Month_of_order, 
		COUNT(Cust_id) as Total_Retained
FROM	RetainedOnes
WHERE	Retained = 'Retained'
GROUP BY  Year_of_Order, Month_of_order
;

SELECT  *
FROM    MontlyTotalRetained
ORDER BY 1, 2
;

CREATE VIEW MontlyTotalCustomers
AS
SELECT DISTINCT	YEAR(Order_date) AS Year_of_Order, 
				MONTH(Order_Date) as Month_of_order, 
				COUNT(Cust_id) OVER (PARTITION BY YEAR(Order_date), MONTH(Order_Date)) as Monthly_Customers
FROM			combined_table
GROUP BY		YEAR(Order_date), MONTH(Order_Date), Cust_id
;

SELECT *
FROM MontlyTotalCustomers
ORDER BY 1, 2
;

WITH RetainedTable AS 
(
SELECT  A.*, B.Total_Retained, 
        MIN(1.0*B.Total_Retained/A.Monthly_Customers) OVER (PARTITION BY A.Year_of_Order, A.Month_of_order) AS Retention
FROM    MontlyTotalCustomers A, MontlyTotalRetained B
WHERE   A.Year_of_Order = B.Year_of_Order AND A.Month_of_order = B.Month_of_Order
)
SELECT	Year_of_Order, 
		Month_of_order, 
		CAST(Retention AS NUMERIC (3,2)) as Retention_Rate
FROM	RetainedTable
;

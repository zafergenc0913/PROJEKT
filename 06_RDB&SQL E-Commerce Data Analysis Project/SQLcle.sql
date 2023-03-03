-- market_fact id--

select *
from dbo.market_fact
order by Ord_id

UPDATE dbo.market_fact
SET Prod_id = REPLACE (Prod_id, 'Prod_','')

UPDATE dbo.market_fact
SET Ship_id = REPLACE (Ship_id, 'SHP_','')

UPDATE dbo.market_fact
SET Cust_id = REPLACE (Cust_id, 'Cust_','')

UPDATE dbo.market_fact
SET Ord_id = REPLACE (Ord_id, 'Ord_','')

--cust_dimen id--
select *
from dbo.cust_dimen
order by Cust_id

UPDATE dbo.cust_dimen
SET Cust_id = REPLACE (Cust_id, 'Cust_','')

--orders_dimen id--
select *
from dbo.orders_dimen

UPDATE dbo.orders_dimen
SET Ord_id = REPLACE (Ord_id, 'Ord_','')

UPDATE dbo.orders_dimen
SET Order_Date=CONVERT(DATE, Order_Date);



--prod_dimen id--
select *
from dbo.prod_dimen

UPDATE dbo.prod_dimen
SET Prod_id = REPLACE (Prod_id, 'Prod_','')

--shipping_dimen id--
select *
from dbo.shipping_dimen

UPDATE dbo.shipping_dimen
SET Ship_id = REPLACE (Ship_id, 'SHP_','')

UPDATE shipping_dimen
SET Ship_Date=CAST(Ship_Date as DATE);
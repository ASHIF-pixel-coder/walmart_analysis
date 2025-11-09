use WALMART_DATA

--select all from walmart_sales
SELECT * FROM walmart_sales

----total transaction count
select count(*) FROM walmart_sales

--count payment_method & no_of_transaction  by payment_method 
select payment_method,count(*) as no_of_transaction 
FROM walmart_sales
group by payment_method


--count distinct branches
select count(distinct Branch) FROM walmart_sales

--find minimum qty sold
select min(quantity) FROM walmart_sales 

--find different payment method,no_of_transaction and qty sold by payment method
select payment_method,count(*) as no_of_transaction,sum(quantity) as total_qtysold 
FROM walmart_sales
group by payment_method

--identify top 3 highest rated category
select top 3 Branch,category,max(rating) as top_ratings
FROM walmart_sales
group by Branch,category

--identify highest average rating by Branch and category 
select Branch,category,avg_ratings FROM
(select Branch,category,avg(rating) as avg_ratings,
RANK() OVER(PARTITION  by Branch order by avg(rating) DESC) AS ranking
FROM walmart_sales
group by Branch,category) as ranked 
where ranking = 1 

---calculate the total quantity of items sold per payment method 
select payment_method,sum(quantity) as total_qtysold from walmart_sales
group by payment_method

--determine the avg,min,max ratings of categories for each city
select category,city,
avg(rating) as avg_ratings,
min(rating) as min_ratings,
max(rating) as max_ratings
from walmart_sales
group by category,city

--calculate the total profit for each  category 
select category,
sum(unit_price * quantity * profit_margin) as total_profit
from walmart_sales
group by category
order by total_profit desc

---determine most common payment_method for each branch

WITH CTE AS 
(select Branch,payment_method,count(*) as no_of_transaction,
RANK() OVER(PARTITION BY Branch ORDER BY count(*) DESC)AS RANKINGS
from walmart_sales
group by Branch,payment_method)
select Branch,payment_method as preferred_method from CTE where RANKINGS = 1

--IDENTIFY THE BUSIEST DAY  FOR EACH BRANCH BASED ON THE NO OF TRANSACTION

select Branch,DAY_NAME,no_of_transaction from
(SELECT Branch,DATENAME(WEEKDAY, CONVERT(DATE, [date], 3)) AS Day_Name,
count(*) as no_of_transaction,
rank() over(partition by Branch order by count(*) desc) as rankings 
from walmart_sales
group by Branch,DATENAME(WEEKDAY, CONVERT(DATE, [date], 3))) AS RANKED
WHERE rankings = 1

---categorize sales in morning,afternoon,evening shifts
select Branch,
         case
		  when DATEPART(hour,[time]) < 12 then 'MORNING'
		  WHEN DATEPART(hour,[time]) BETWEEN 12 AND 17 then 'AFTERNOON'
		  ELSE 'EVENING'
		END AS shifting,
	count(*) as no_of_invoices 
	from walmart_sales
	group by Branch,
	case
		  when DATEPART(HOUR,[time]) < 12 then 'MORNING'
		  WHEN DATEPART(HOUR,[time]) BETWEEN 12 AND 17 then 'AFTERNOON'
		  ELSE 'EVENING'
	end
		  order by Branch,no_of_invoices desc

--identify the 5 branches with highest revenue decrease rate from last year to current year (eg.2022 & 2023)

with revenue_2022 as (
select Branch,
sum(TOTAL) as revenue
FROM walmart_sales
where datename(year,convert(date,[date],3)) = 2022
group by Branch),

revenue_2023 as (
select Branch,
sum(TOTAL) as revenue
FROM walmart_sales
where datename(year,convert(date,[date],3)) = 2023
group by Branch)

select top 5 
r2022.Branch,
r2022.revenue as last_yr_revenue,
r2023.revenue as current_yr_revenue,
ROUND(((r2022.revenue - r2023.revenue)/r2022.revenue)*100,2) as REVENUE_DECREASE_RATIO
FROM revenue_2022 as r2022 join revenue_2023 as r2023 
on r2022.Branch = r2023.Branch
where r2022.revenue > r2023.revenue
order by REVENUE_DECREASE_RATIO
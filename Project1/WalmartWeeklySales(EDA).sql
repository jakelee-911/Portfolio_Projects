-- 1>Which Store has maximum Sales

Select top 1 Store,sum(Weekly_Sales) as TotalSales
from PortfolioProject1..Walmart_WeeklySales$
group by Store
order by TotalSales desc


-- 2> Which store has good quarterly growth rate in Q3’2012

--Normalize Date Column and Convert it from Character String to Date Data Type
With sub1 as(Select Store,Convert(date,REPLACE(Date,'-','/'),103) as Date, Weekly_Sales
			From PortfolioProject1..Walmart_WeeklySales$),

--Calculate Total Sales in Q2 and Q3 of 2012
sub2 as(SELECT Store, datepart(QUARTER,Date) as Quarter, sum(Weekly_Sales) as TotalQuarterSales
	From Sub1
	Where (datepart(year,Date)=2012) and (datepart(QUARTER,Date) in (2,3))
	Group by Store, datepart(QUARTER,Date)
	),

--Calculate Total Growth Rate in Q3
sub3 as(Select Store, Quarter, Round(TotalQuarterSales/Lag(TotalQuarterSales,1) over(partition by Store order by Quarter),2) as Total_Growth_Q3
		From sub2)

Select Store, Quarter, Total_Growth_Q3
From sub3
Where Total_Growth_Q3 is not NULL and Total_Growth_Q3 > 1
Order by 3 desc

-- 3>Which store has maximum standard deviation, the sales vary a lot. Also, find out the coefficient of mean to standard deviation

--Calculate the Standard_Deviation and Mean Sales per Store
With standard_deviation as(	Select Store, Round(STDEV(weekly_Sales),2) as Standard_Deviation, Round(AVG(weekly_Sales),2) as Mean
								From PortfolioProject1..Walmart_WeeklySales$
								Group by Store)
--Calculate the Store with maximum standard deviation
Select top 1 Store, Standard_Deviation,Mean
from standard_deviation
order by 2
--Caculate the correlation between Mean and Standard_Deviation
With standard_deviation as(	Select Store, Round(STDEV(weekly_Sales),2) as Standard_Deviation, Round(AVG(weekly_Sales),2) as Mean
								From PortfolioProject1..Walmart_WeeklySales$
								Group by Store)

SELECT 
(Avg(Mean * Standard_Deviation) - (Avg(Mean) * Avg(Standard_Deviation))) / (StDevP(Mean) * StDevP(Standard_Deviation))  as Correlation
FROM standard_deviation


--4) Some holidays have a negative impact on sales. Find out holidays which have higher sales than the mean sales in non-holiday season for all stores together

--Caculate the TotalSales per Day for every Stores
With sub1 as(Select Date,Holiday_Flag,Weekly_Sales
			From Walmart_WeeklySales$ as ww
			Inner Join Walmart_Outside_Condition$ as wo
			on ww.SalesID=wo.SalesID),
--Caculate The TotalSales only for Holidays
sub2 as(Select Date,sum(Weekly_Sales) as Holiday_Sales
			From sub1
			Where Holiday_Flag=1
			Group by Date),
--Calculate the TotalSales only for Non-Holidays
sub3 as(Select Date,sum(Weekly_Sales) as NonHoliday_Sales
			From sub1
			Where Holiday_Flag=0
			Group by Date)
--Find out which Holidays sales higher than the Mean of Non-Holidays 
Select Date, Holiday_Sales
From sub2
Where Holiday_Sales > (Select Avg(NonHoliday_Sales)
						from sub3)

--5) Pivot Table
--Calculate Index based on Year 2010-2012
With sub1 as(Select SalesID, Store,Convert(date,REPLACE(Date,'-','/'),103) as Date, Weekly_Sales
			From PortfolioProject1..Walmart_WeeklySales$),

sub2 as(Select sub1.SalesID, Store, datepart(year,Date) as Year, Weekly_Sales, Holiday_Flag, Temperature, Fuel_Price, CPI, Unemployment
			From sub1
			Inner join Walmart_Outside_Condition$ as wc
			on sub1.SalesID=wc.SalesID
			Inner join Walmart_Economic_Index$ as we
			on we.SalesID = wc.SalesID)
--Create Pivot Table (Average CPI and Average Unemployment each Stores on year 2010-2012 and the Total)
Select Store, Year, avg(CPI) as AverageCPI_PerYear,avg(Unemployment) as AverageUE_PerYear
From sub2
Group by Rollup(Year,Store)

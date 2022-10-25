--Check Data Types of Table
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'AB_NYC_2019$'

--Change the column name
EXEC sp_rename 'dbo.AB_NYC_2019$.latitude', 'lat', 'COLUMN';
EXEC sp_rename 'dbo.AB_NYC_2019$.longitude', 'long', 'COLUMN';

--Count Null Values in Each Column

Select Sum(Case when id is null then 1 else 0 end) as id,
	Sum(Case when name is null then 1 else 0 end) as name,
	Sum(Case when host_id is null then 1 else 0 end) as host_id,
	Sum(Case when host_name is null then 1 else 0 end) as host_name,
	Sum(Case when neighbourhood_group is null then 1 else 0 end) as neighbourhood_group,
	Sum(Case when neighbourhood is null then 1 else 0 end) as neighbourhood,
	Sum(Case when lat is null then 1 else 0 end) as latitude,
	Sum(Case when long is null then 1 else 0 end) as longitude,
	Sum(Case when room_type is null then 1 else 0 end) as room_type,
	Sum(Case when price is null then 1 else 0 end) as price,
	Sum(Case when minimum_nights is null then 1 else 0 end) as minimum_nights,
	Sum(Case when number_of_reviews is null then 1 else 0 end) as number_of_reviews,
	Sum(Case when last_review is null then 1 else 0 end) as last_review,
	Sum(Case when reviews_per_month is null then 1 else 0 end) as reviews_per_month,
	Sum(Case when calculated_host_listings_count is null then 1 else 0 end) as calculated_host_listings_count,
	Sum(Case when availability_365 is null then 1 else 0 end) as availability_365
From AB_NYC_2019$


--Delete Rows with Name(16 rows) or Host_Name(21 rows) are null
DELETE
From AB_NYC_2019$
Where name is null or host_name is null

--Remove Special Characters in column name and host_name
--First, Convert Error Encoding String Value
Update AB_NYC_2019$
Set name = CONVERT(varchar(100),name) Collate SQL_Latin1_General_CP1253_CI_AI

--Another step to normalize column values
Update AB_NYC_2019$
Set name =REPLACE(name,' w ','with')

--Create Function Remove Special Characters except WhiteSpace
Create Function [dbo].[RemoveSpecialCharacters](@Input VarChar(1000))
Returns VarChar(1000)
AS
Begin
    Declare @KeepValues as varchar(50)
    Set @KeepValues = '%[^a-zA-Z0-9 ]%'
    While PatIndex(@KeepValues, @Input) > 0
        Set @Input = Stuff(@Input, PatIndex(@KeepValues, @Input), 1, '')
    Return @Input
End

--Apply Function to column name
Update AB_NYC_2019$
Set name = [dbo].[RemoveSpecialCharacters](name)

--Do the same for column host_name
Update AB_NYC_2019$
Set host_name = CONVERT(varchar(100),host_name) Collate SQL_Latin1_General_CP1253_CI_AI

Update AB_NYC_2019$
Set host_name = REPLACE(REPLACE(REPLACE(host_name,'&','and'),'+','and'),'/','and')

Update AB_NYC_2019$
Set host_name = [dbo].[RemoveSpecialCharacters](host_name)

-- Check if any duplicate values in dataset and delete it
With sub1 as (
	Select *,ROW_NUMBER() over(partition by id,name,host_id,host_name,neighbourhood_group order by id) as row
	from AB_NYC_2019$
	)

Select * from sub1
where row>1--(No duplicate value)

--Change Datatype to Reduce Memory
AlTER TABLE AB_NYC_2019$
ALTER COLUMN availability_365 smallint NULL

AlTER TABLE AB_NYC_2019$
ALTER COLUMN calculated_host_listings_count smallint NULL

AlTER TABLE AB_NYC_2019$
ALTER COLUMN number_of_reviews smallint NULL

AlTER TABLE AB_NYC_2019$
ALTER COLUMN minimum_nights smallint NULL

AlTER TABLE AB_NYC_2019$
ALTER COLUMN price smallint NULL

AlTER TABLE AB_NYC_2019$
ALTER COLUMN last_review date NULL

--Replace Null Values of the column review_per_month
With Average_Score as ( Select *,round(avg(reviews_per_month)over(partition by neighbourhood_group,room_type),2) as Avg
						from AB_NYC_2019$)

Update AB_NYC_2019$
Set AB_NYC_2019$.reviews_per_month = COALESCE(Average_Score.reviews_per_month,Average_Score.Avg)
From Average_Score
where AB_NYC_2019$.id=Average_Score.id

--Delete none-using column
AlTER TABLE AB_NYC_2019$
DROP COLUMN last_review
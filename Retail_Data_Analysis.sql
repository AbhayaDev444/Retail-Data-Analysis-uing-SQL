
Use Retail_Data

-----------Adding customer_id as primary key to table customer

Alter table Customer
add constraint PK_Customer primary key (customer_id)

--------Adding constraint foreign keys fk_customerid aand fk_prod_cat_code and prod_subcat_code to table 'Transactions'
ALTER TABLE Transactions
ADD CONSTRAINT FK_Cutsomer
FOREIGN KEY (cust_id) REFERENCES Customer(customer_id)

alter table Transactions
add constraint FK_prod_cat_info
foreign key (prod_cat_code,prod_subcat_code) references prod_cat_info(prod_cat_code,prod_sub_cat_code)

select * from transactions
select * from Customer
Select * from prod_cat_info 




---Q1.1.	What is the total number of rows in each of the 3 tables in the database?

select count(*)  as [ No.of rows in Customers] from Customer


select count(*) as [No.of rows in prod_cat_info] from  prod_cat_info

select count(*) as [No. of rows in transactions] from Transactions


----Q2. What is the total number of transactions that have a return?

select count(*) as [No.of transaction with a return] from transactions where
(Qty<0)

-----Q3  As you would have noticed, the dates provided across the datasets are not in a correct format.
 --------As first steps, pls convert the date variables into valid date formats before proceeding ahead.
   

alter table customer alter column DOB DATETIME NOT NULL

alter table transactions alter column tran_date DATETIME NOT NULL








--4.	What is the time range of the transaction data available for analysis? 
--Show the output in number of days, months and years simultaneously in different columns.

SELECT DATEDIFF(DAY,MIN(tran_date),MAX(tran_date))[No. of Days],DATEDIFF(Month,MIN(tran_date),MAX(tran_date))[No.of Months],DATEDIFF(year,MIN(tran_date),MAX(tran_date))[No. of years] FROM transactions

---5.5.	Which product category does the sub-category “DIY” belong to?
select prod_subcat[Product Sub category],prod_cat[Product category] from prod_cat_info
where prod_subcat in ('DIY')




----------------------------------------------------------------------------DATA ANALYSIS----------------------------------------------------------------------------


-------1.	Which channel is most frequently used for transactions?

select top 1 store_type [Most frequently used Channel],count(transaction_id)[No. of transactions] from Transactions
Group By Store_type
Order By count(transaction_id) desc

--------2.What is the count of Male and Female customers in the database?


select Distinct Gender,count(Gender)[Number of Customers] from Customer
Group By Gender



-----3.	From which city do we have the maximum number of customers and how many?

select top 1 city_code,count(customer_id)[No. of Customers] from customer 
Group By city_code
Order by [No. of Customers]  desc

--------4.	How many sub-categories are there under the Books category?

select prod_cat[Product category], Count(prod_subcat)[No. of Subcategories] from prod_cat_info
Group By prod_cat
Having prod_cat = 'Books'


------5.	What is the maximum quantity of products ever ordered?

----Answer 1. Maximum quantity of products ever ordered in a single transaction
select top 1 sum(Qty) [Maximum Quantity of products ever ordered] from transactions
Group By transaction_id
Order By sum(Qty) desc

----Answer 1. Maximum quantity of products ever ordered by a  single customer 
select top 1 sum(Qty) [Maximum Quantity of products ever ordered], cust_id from transactions
Group By cust_id
Order By sum(Qty) desc


------------6.	What is the net total revenue generated in categories Electronics and Books?

select p.prod_cat,Sum(t.total_amt)[Net Revenue] from transactions t inner join prod_cat_info p on p.prod_sub_cat_code = t.prod_subcat_code and p.prod_cat_code = t.prod_cat_code
Group By p.prod_cat
Having p.prod_cat in('Electronics','Books')


----------7.	How many customers have >10 transactions with us, excluding returns?
select count(Cust_id) [Number of  customers having >10 transactions excluding returns] from (select cust_id[Cust_id],count(Qty)[No.of sales transcations] from transactions where Qty>0
Group By cust_id having count(Qty)>10)temp







----------8.	What is the combined revenue earned from the “Electronics” & “Clothing” categories, from “Flagship stores”?

select p.prod_cat,t.store_type,Sum(t.total_amt)[Net Revenue] from transactions t inner join prod_cat_info p on p.prod_sub_cat_code = t.prod_subcat_code and p.prod_cat_code = t.prod_cat_code
Group By p.prod_cat,t.store_type
Having  p.prod_cat in ('Electronics','Books') and t.Store_type = 'Flagship store' 












-------------9.	What is the total revenue generated from “Male” customers in “Electronics” category? Output should display total revenue by prod sub-cat.


select c.Gender[Gender],p.prod_cat[Category],p.prod_subcat [Subcategory],Sum(t.total_amt)[Net Revenue] from transactions t inner join prod_cat_info p on p.prod_sub_cat_code = t.prod_subcat_code and p.prod_cat_code = t.prod_cat_code 
inner join Customer c on t.cust_id =c.customer_Id
Group By c.Gender,p.prod_cat,p.prod_subcat
Having  p.prod_cat  = 'Electronics' and c.Gender = 'M'




-------------10.What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?

with sales as (select sum(total_amt) as [GTotal_Sales] from transactions where Qty>0),

subsales as(select prod_subcat_code, sum(total_amt)[Total_Sales] from transactions where Qty>0
Group By prod_subcat_code),

S as (select su.prod_subcat_code,su.Total_Sales*100/s.[GTotal_Sales] as [Percentage of Sales] from subsales su,sales s),


[returns] as (select sum(total_amt)[GTotal_Returns] from transactions where Qty<0),

subreturns as(select prod_subcat_code, sum(total_amt)[Total_Returns] from transactions where Qty<0
Group By prod_subcat_code),

R as (select sr.prod_subcat_code,sr.Total_Returns*100/r.[GTotal_Returns] as [Percentage of Returns] from subreturns sr, [returns] r)

select p.prod_cat,prod_subcat,S.[Percentage of Sales],R.[Percentage of Returns]  from S inner join R on S.prod_subcat_code = R.prod_subcat_code 
inner join prod_cat_info p on R.prod_subcat_code = p.prod_sub_cat_code




-------------11.	For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers in last 30 days of transactions from max transaction date available in the data?

WITH custage AS
(select C.customer_Id, DATEDIFF(YEAR,C.DOB,MAX(T.TRAN_DATE))[AGE] FROM CUSTOMER C INNER JOIN TRANSACTIONS T ON C.customer_Id = T.cust_id
GROUP BY C.customer_Id,C.DOB
HAVING DATEDIFF(YEAR,C.DOB,MAX(T.TRAN_DATE)) BETWEEN 25 AND 35),

last30tran as(select tran_date from TRANSACTIONS
GROUP BY tran_date
Order by tran_date DESC
offset 0 rows fetch first 30 rows only)


SELECT ca.customer_id,sum(tr.total_amt)[Net Revenue]  from custage ca inner join transactions tr on ca.customer_Id = tr.cust_id inner join last30tran l on tr.tran_date = l.tran_date
Group By ca.Customer_Id
Order by [Net Revenue]












------------12.	Which product category has seen the max value of returns in the last 3 months of transactions?





with ymrank as
(select  *,dense_rank() over( order by year(tran_date) desc,month(tran_date)desc ) as [yearmonth rank]from transactions),

ym_rank as (select distinct * from ymrank where [yearmonth rank] <=3)

select top 1 prod_cat,sum(ym.total_amt)[Net Revenue] from prod_cat_info pc inner join ym_rank ym on pc.prod_cat_code = ym.prod_cat_code and pc.prod_sub_cat_code = ym.prod_subcat_code
Group By prod_cat
Order by [Net Revenue] asc 










---------13.	Which store-type sells the maximum products; by value of sales amount and by quantity sold?




with ranks as(select store_type,sum(total_amt)[Net sales],sum(qty)[Net Quantity],dense_rank() over (order by sum(total_amt) desc )[sales rank],dense_rank() over (order by sum(Qty) desc)[qtyrank] from transactions
Group By store_type)

select store_type,[sales rank],qtyrank from ranks
where [sales rank] = 1 or qtyrank =1











--------14.	What are the categories for which average revenue is above the overall average.


SELECT p.prod_cat, AVG(t.total_amt) AS average 
FROM (SELECT t.*, AVG(t.total_amt) OVER () as overall_average
      FROM Transactions T
     ) t JOIN
     prod_cat_info P 
     ON t.prod_cat_code = p.prod_cat_code
GROUP BY p.prod_cat, overall_average
HAVING AVG(t.total_amt) > overall_average









--------15.	Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.


with top5cat_qty as(select top 5 p.prod_cat,sum(t.qty)[Total Qty] from prod_cat_info p inner join transactions t on p.prod_cat_code = t.prod_cat_code and p.prod_sub_cat_code = t.prod_subcat_code
Group By p.prod_cat
Order By [Total Qty] desc
)

select t5.prod_cat,p.prod_subcat,sum(total_amt)[Total Revenue],avg(total_amt)[Average Revenue] from  prod_cat_info p inner join transactions t on p.prod_cat_code = t.prod_cat_code and p.prod_sub_cat_code = t.prod_subcat_code
 inner JOIN
top5cat_qty t5 on p.prod_cat = t5.prod_cat
Group By t5.prod_cat,p.prod_subcat
Order by avg(total_amt) desc





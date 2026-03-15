--1.
select 'Customer' as TABLE_NAME, COUNT(customer_id) as NO_OF_ROWS
from customer
UNION ALL
SELECT 'PROD_CAT_INFO' AS TABLE_NAME, COUNT(PROD_CAT_CODE) AS NO_OF_ROWS
FROM prod_cat_info
UNION ALL
SELECT 'TRANSACTION_ID' AS TABLE_NAME, COUNT(transaction_id) AS NO_OF_ROWS
FROM Transactions

--2.
select count(DISTINCT transaction_id) AS Total_return
from Transactions
where Qty < 0

--3.
select Customer_id, cast(DOB as date) as DOB, Gender, City_Code 
from customer
select transaction_id, cust_id, cast(tran_date as date) as trans_date, prod_subcat_code,
Prod_cat_code, Qty, Rate, Tax,
total_amt, Store_type 
from Transactions


--4.
select 
datediff(DAY, min(tran_date), max(tran_date)) as Diff_Days,
datediff(month, min(tran_date), max(tran_date)) as Diff_Months,
datediff(year, min(tran_date),max(tran_date)) as Diff_Years
from Transactions

--5. 
select Prod_cat, prod_subcat
from prod_cat_info
where prod_subcat = 'DIY'

--------------------------------------DATA ANALYSIS--------------------------------------------------------------------
--1. Which channel is most frequently used for transactions?
select top 1 store_type, count(*) as trans_count
from Transactions
group by store_type
order by trans_count desc
--2. What is the count of Male and Female customers in the database?
select Gender, count(*) as Gender_count
from customer
where gender is not null
group by Gender

--3.
select top 1 city_code, Count(customer_Id) as cust_count
from Customer
group by city_code
order by cust_count desc

--4. 
select prod_cat, count( distinct prod_subcat) as sub_categories
from prod_cat_info
where prod_cat = 'books'
group by prod_cat

--5.
select prod_cat_code,max(Qty)as max_qty
from Transactions
group by prod_cat_code

--6.
select T2.PROD_CAT, ROUND(SUM(T1.TOTAL_AMT),2) AS NET_REVENUE
from Transactions as T1
INNER JOIN PROD_CAT_INFO AS T2
ON T1.PROD_SUBCAT_CODE= T2.PROD_SUB_CAT_CODE
             AND T1.PROD_CAT_CODE= T2.PROD_CAT_CODE
WHERE T2.PROD_CAT IN ('ELECTRONICS', 'BOOKS')
GROUP BY T2.PROD_CAT

--7.
select cust_id,count(transaction_id)as trans_count
from Transactions as t
where total_amt > 0
group by cust_id
having count(transaction_id)> 10

--8.
select sum(total_amt)as revenue
from Transactions as t
inner join prod_cat_info as p
on t.prod_cat_code = p.prod_cat_code
 and 
 t.prod_subcat_code = t.prod_subcat_code
 where prod_cat in ('electronics','clothing')
               and
               Store_type like 'fla%'

 --9.
 select prod_subcat,round(sum(total_amt),2)as revenue
 from Customer as c
 inner join Transactions as t
 on c.customer_Id = t.cust_id
inner join prod_cat_info as p
on t.prod_cat_code = p.prod_cat_code
        and
    t.prod_subcat_code = p.prod_sub_cat_code
where Gender = 'M'
        and
    prod_cat = 'Electronics'
group by prod_subcat

--10.
select t1.*,t2.return_percentage
from(
     select top 5 prod_subcat,round(sum(total_amt),2)/(select round(sum(total_amt),2)as total_sales from 
             Transactions where total_amt> 0) as sales_percentage
     from prod_cat_info as p
     inner join Transactions as t
     on p.prod_cat_code = t.prod_cat_code
               and
        p.prod_sub_cat_code = t.prod_subcat_code
     where total_amt > 0
     group by prod_subcat
     order by sales_percentage desc)as t1
     inner join
     (select  prod_subcat,round(sum(total_amt),2)/(select round(sum(total_amt),2)as total_sales from 
             Transactions where total_amt< 0) as return_percentage
     from prod_cat_info as p
     inner join Transactions as t
     on p.prod_cat_code = t.prod_cat_code
               and
        p.prod_sub_cat_code = t.prod_subcat_code
     where total_amt < 0
     group by prod_subcat
) as t2
on t1.prod_subcat = t2.prod_subcat

---------------------------2nd method(using ctes)------------------------------------------------------
;with subcat_sales
as
  (select prod_subcat,sum(total_amt)as revenue,sum(case when t.total_amt > 0 then total_amt else 0
  end)as sales_amt,sum(case when total_amt < 0 then total_amt else 0 end) as return_amt
   from prod_cat_info as p
   inner join Transactions as t
   on p.prod_cat_code = t.prod_cat_code
                and
      p.prod_sub_cat_code = t.prod_subcat_code
      group by prod_subcat),
Top_5
as(
    select top 5 * from subcat_sales
    order by revenue desc),
Percentages
as(
   select prod_subcat,sales_amt/(select sum(sales_amt)from subcat_sales)*100 as sales_percentages,
                      return_amt/(select sum(return_amt) from subcat_sales)*100as return_percentages
   from Top_5
   group by prod_subcat,sales_amt,return_amt)

select prod_subcat,ROUND(sales_percentages,2)as Sales_percentages,ROUND(return_percentages,2)as
                                                                    Return_percentages
from Percentages

--11.
select customer_Id,Age,SUM(total_amt)as Revenue,tran_date
from(
      select customer_Id,total_amt,tran_date,DATEdiff(YEAR,DOB,max_tran_date)as Age
      from(
            select customer_id,DOB,tran_date,total_amt,max(tran_date)as max_tran_date
            from Transactions as t
            inner join Customer as c
            on t.cust_id = c.customer_Id
            where t.tran_date >=DATEADD(day,-30,(select max(tran_date)from transactions))
            group by customer_Id,DOB,total_amt,tran_date
            ) as x           
)as y
where Age between 25 and 35
group by customer_Id,Age,tran_date

------------------------2nd method(using ctes)-----------------------------------------------------------
;with max_tran_date
as(
select max(tran_date)as max_dte
from Transactions),
Cust_Info
as(
    select customer_Id,DATEdiff(YEAR,DOB,(select max_dte from max_tran_date)) as Age
    from Customer 
    where DATEdiff(YEAR,DOB,(select max_dte from max_tran_date)) between 25 and 35),
last_30_days_trans
as(
   select cust_id,total_amt
   from Transactions
   where tran_date >= DATEADD(DAY,-30,(select max_dte from max_tran_date))
                   and
        cust_id in (select customer_Id from Cust_Info)
   )
select cust_id,sum(total_amt)as revenue
from last_30_days_trans
group by cust_id

--12.
;With Max_tran_dte
As(
   select max(tran_date)as max_tran_date from Transactions
   ),
Last_3_months_returns
As(
   Select prod_cat,sum(Qty)as Returns from Transactions as t 
   inner join prod_cat_info as p
   on t.prod_cat_code = p.prod_cat_code
              and
      t.prod_subcat_code = p.prod_sub_cat_code
   where Qty < 0
            and 
        tran_date >= DATEADD(month,-3,(select max_tran_date from Max_tran_dte))
   group by prod_cat
    )
select top 1 * from Last_3_months_returns
order by Returns 

--13.
select top 1 Store_type,sum(total_amt)as Revenue,sum(Qty)as Qty_sold
from Transactions
where total_amt > 0 
        And
       Qty > 0
group by Store_type
Order by Revenue Desc,Qty_sold desc

--14.
select prod_cat,round(avg(total_amt),2)as avg_revenue
from prod_cat_info as p
inner join Transactions as t
on p.prod_cat_code = t.prod_cat_code
         And
    p.prod_sub_cat_code = t.prod_subcat_code
where total_amt > 0
Group by prod_cat
Having avg(total_amt) > (select avg(total_amt) from Transactions where total_amt > 0)

--15.
;With top_5_categories
as(
    select top 5 prod_cat,sum(Qty)As Qty_Sold
    from Transactions as t
    inner join prod_cat_info as p
    on p.prod_cat_code = t.prod_cat_code
             And
       p.prod_sub_cat_code = t.prod_subcat_code
    where Qty > 0
    Group by prod_cat
    order by Qty_Sold desc
    ),
Subcategories
as(
   select prod_subcat,avg(total_amt)as Avg,sum(Total_amt)as Revenue
   from prod_cat_info as p
   inner join Transactions as t
   on p.prod_cat_code = t.prod_cat_code
              And
    p.prod_sub_cat_code = t.prod_subcat_code
    where prod_cat in (select prod_cat from top_5_categories)
                  and
                total_amt > 0
    Group by prod_subcat
    )
select * from Subcategories

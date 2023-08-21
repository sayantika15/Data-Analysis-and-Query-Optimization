/*Tables Imported
1. User
2. Employee
3. Doctors
4.Login Details
5.Weather
6. Students
7.event_category, physician_speciality, patient_treatment
8. patient_logs
*/

-- 1. Write a SQL Query to fetch all the duplicate records in  user table.
-- Note: Record is considered duplicate if a user name is present more than once.

select * from users;

select *, row_number() over (partition by user_name) as repetition
from users
order by user_id;

with t1 as(
select *, row_number() over (partition by user_name) as repetition
from users
order by user_id)
select user_id, user_name, email 
from t1
where repetition > 1;

-- 2. Write a SQL query to fetch the second last record from employee table.
   /*Use window() approach. For fetching the 2nd last or last we always have to sort the data using "order by" clause
   the find the 2nd or last position. No need to use "partition by" in window()*/
   
select * from employee;
select *, row_number() over (order by emp_ID desc) as repetition
from employee;

select emp_ID, emp_NAME, DEPT_NAME, SALARY
from( select *, row_number() over (order by emp_ID desc) as repetition
from employee) x
where x.repetition = 2;

-- 3. Write a SQL query to display only the details of employees who either earn the highest salary or the lowest salary in each department from the employee table.

/* We're partitioning the rows by department using the PARTITION BY clause, so that the ROW_NUMBER() function restarts for each department.
We're ordering the rows by salary in ascending order for the min_rank column and in descending order for the max_rank column,
 so that the lowest salary and the highest salary for each department receive a rank of 1.*/
 
 SELECT emp_id, emp_name, dept_name, salary,
    ROW_NUMBER() OVER (PARTITION BY dept_name ORDER BY salary ASC) AS min_rank,
    ROW_NUMBER() OVER (PARTITION BY dept_name ORDER BY salary DESC) AS max_rank
  FROM employee;

SELECT emp_id, emp_name, dept_name, salary
FROM (
  SELECT emp_id, emp_name, dept_name, salary,
    ROW_NUMBER() OVER (PARTITION BY dept_name ORDER BY salary ASC) AS min_rank,
    ROW_NUMBER() OVER (PARTITION BY dept_name ORDER BY salary DESC) AS max_rank
  FROM employee
) AS emp
WHERE min_rank = 1 OR max_rank = 1;

select * from employee;

-- 4.From the doctors table, fetch the details of doctors who work in the same hospital but in different specialty.
--   Write SQL query to fetch the doctors who work in same hospital irrespective of their specialty.
-- d1.id<>d2.id will not fetch duplicate records.

select * from doctors;
/*Same hospital different speciality*/
select d1.*
from doctors d1 join doctors d2 on d1.id<>d2.id and d1.hospital=d2.hospital and d1.speciality<>d2.speciality;

/*Same hospital same speciality as well*/

select d1.id, d1.name, d1.speciality, d1.hospital, d1.city, d1.consultation_fee
from doctors d1 join doctors d2 on d1.id<>d2.id and d1.hospital=d2.hospital and d1.speciality=d2.speciality ; /*Nothing is mentioned about speciality
                                                                              hence, no condition need to be specified*/
                                                                              
select * from doctors;

-- 5. From the login_details table, fetch the users who logged in consecutively 3 or more times.
/*for calculating consecutive always use window finction "lead()" */

select * from login_details;
select *,
case when user_name= lead(user_name) over (order by login_id) and 
	      user_name =lead(user_name,2) over (order by login_id) then user_name
          else null end as Repeated_names
from login_details;
with t2 as
(select *,
case when user_name= lead(user_name) over (order by login_id) and 
	      user_name =lead(user_name,2) over (order by login_id) then user_name
          else null end as Repeated_names
from login_details)
select distinct Repeated_names
from t2
where Repeated_names is not null;


select * from login_details;

-- 6. From the students table, write a SQL query to interchange the adjacent student names.

SELECT s1.id, s1.student_name, s2.student_name AS new_student_name
FROM students s1
JOIN students s2 ON s1.id + 1 = s2.id
ORDER BY s1.id;

-- 7. From the weather table, fetch all the records when London had extremely cold temperature for 3 consecutive days or more.
-- Note: Weather is considered to be extremely cold when its temperature is less than zero.
select * from weather;

select *,
case when temperature < 0 
and  lead(temperature) over (order by id) <0
and  lead(temperature,2) over (order by id) <0
then "Yes" 
when temperature < 0 
and  lag(temperature) over (order by id) <0
and  lead(temperature) over (order by id) <0
then "Yes" 
when temperature < 0 
and  lag(temperature) over (order by id) <0
and  lag(temperature,2) over (order by id) <0
then "Yes" 
else null end as Flag
from weather;

select id, city, temperature, day
from(select *,
case when temperature < 0 
and  lead(temperature) over (order by id) <0
and  lead(temperature,2) over (order by id) <0
then "Yes" 
when temperature < 0 
and  lag(temperature) over (order by id) <0
and  lead(temperature) over (order by id) <0
then "Yes" 
when temperature < 0 
and  lag(temperature) over (order by id) <0
and  lag(temperature,2) over (order by id) <0
then "Yes" 
else null end as Flag
from weather) x
where x.flag is not null;



select * from students;



-- 8. From the following 3 tables (event_category, physician_speciality, patient_treatment),
-- write a SQL query to get the histogram of specialties of the unique physicians who have done the procedures but never did prescribe anything.
select * from event_category; 
 select * from physician_speciality;
 select * from patient_treatment;

select ps.speciality, count(*) as speciality_count
from patient_treatment pt
join event_category ec on ec.event_name = pt.event_name
join physician_speciality ps on ps.physician_id = pt.physician_id
where ec.category = 'Procedure'
and pt.physician_id not in (select pt2.physician_id
							from patient_treatment pt2
							join event_category ec on ec.event_name = pt2.event_name
							where ec.category in ('Prescription'))
                             group by ps.speciality;


select * from patient_treatment;
select * from event_category;
select * from physician_speciality;

/* 9. Find the top 2 accounts with the maximum number of unique patients on a monthly basis.
( Note: Prefer the account if with the least value in case of same number of unique patients)
    month    account_id   no. of unique records(Patient_id)
     Jan         1               2 (100,200)
	 Jan         2               3 (300,400,500)
     Jan         3               2 (400,450)
	 March       1               1  (500)
*/

select * from patient_logs;

select  monthname(dates) as Month, account_id,patient_id
from patient_logs; /*Extraction of month*/

select  distinct monthname(dates) as Month, account_id,patient_id
      from patient_logs;
select Month, account_id,count(patient_id) as No_of_patient
from (select  distinct monthname(dates) as Month, account_id,patient_id
      from patient_logs) x
      group by Month, account_id; /*Counting the patient name Of each month. Also removing the duplicate month */
      
      
      
      
      with cte as
      (select *, rank() over (partition by Month order by No_of_patient desc, account_id) as rnk/*As we have sorted the data as per no.of patients
                                                                                        thats why two 2 are showing. To remove it, sort the accnt id 
                                                                                        also in asc order.*/
      from(select Month, account_id,count(patient_id) as No_of_patient
          from (select  distinct monthname(dates) as Month, account_id,patient_id
      from patient_logs) x
      group by Month, account_id) y)
       
       select Month, account_id, No_of_patient from cte where rnk <=2;
      
      







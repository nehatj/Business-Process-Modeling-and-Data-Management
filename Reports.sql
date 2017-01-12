--queries

-- 1) Creating a view for an employee who belongs to department D2 
CREATE VIEW T7_EmployeeView
AS SELECT  employee_id AS "Employee ID", ee_last_name AS "Last Name", date_of_hire AS "Hire Date"
    FROM    t7_employee
    WHERE   department_id = 'D2'
    WITH CHECK OPTION CONSTRAINT depidD2_ck;
    
--2
DESCRIBE T7_EmployeeView;

--3 No of tickets created for each terminal
select bank_id AS "Bank Id", terminal_id AS "Terminal ID", count(service_order_id) AS "No. of Tickets"
from t7_service_order
group by bank_id, terminal_id
order by count(service_order_id) desc;

--4 number of tickets created for each bank
select bank_id AS "Bank Id", count(service_order_id) AS "No. of Tickets"
from t7_service_order
group by bank_id
order by count(service_order_id) desc;

--5 No of open and close tickets for each terminal
select distinct terminal_id as "Terminal ID",
count(service_order_id) As "No.of Tickets",
sum(case when service_order_status = 'Open' then 1 else 0 end) as "No. of open Tickets",
sum(case when service_order_status = 'Closed' then 1 else 0 end) as "No. of closed Tickets"
from t7_service_order 
group by terminal_id
order by sum(case when service_order_status = 'Open' then 1 else 0 end) desc;

--6 No of open and close tickets for each bank
select  b.BANK_NAME,
count(so.service_order_id) As "No.of Tickets",
sum(case when so.service_order_status = 'Open' then 1 else 0 end) as "No. of open Tickets",
sum(case when so.service_order_status = 'Closed' then 1 else 0 end) as "No. of closed Tickets"
from t7_service_order so
join t7_bank b
using (bank_id)
group by b.bank_name;



--7 SLA Times for each bank
select bank_name as "Bank Name", sla_time AS "SLA Time"
from t7_bank
group by bank_name, sla_time
order by sla_time;

--8 bank with least SLA
select bank_name as "Bank with least SLA", sla_time AS "SLA time in hours"
from t7_bank
group by bank_name, sla_time
HAVING min(sla_time) = (select distinct min(sla_time) from t7_bank)
order by sla_time;

--9 Use NVL to give proper meaning for null values in a column for user perception
select service_order_id as "Service Order ID", NVL(engineer_comments,'Comment not updated by Engineer') AS "Engineer Comments", SERVICE_ORDER_STATUS AS "Service Order Status"
from t7_service_order;

--10 call resolution history before implementing solution
select bank_id as "Bank ID", 'Service Order '||service_order_id||'was created for this bank on '||service_order_creation_time||' and was resolved on '||service_order_resolution_time||' in a duration of '||round(((extract(day from service_order_resolution_time)*24+extract(hour FROM service_order_resolution_time)+
extract(minute FROM service_order_resolution_time)/60+extract(second FROM service_order_resolution_time)/3600)
-(extract(day from service_order_creation_time)*24+extract(hour FROM service_order_creation_time)+
extract(minute FROM service_order_creation_time)/60+extract(second FROM service_order_creation_time)/3600)),2)||' hours' AS "Order Summary Before 16th"
from t7_service_order
where service_order_resolution_time < to_timestamp('16-NOV-16 12.00.00', 'DD-MON-YY HH12.MI.SS');

--11 improvement in call resolution after implementing solution
select bank_id as "Bank ID", 'Service Order '||service_order_id||'was created for this bank on '||service_order_creation_time||' and was resolved on '||service_order_resolution_time||' in a duration of '||round(((extract(day from service_order_resolution_time)*24+extract(hour FROM service_order_resolution_time)+
extract(minute FROM service_order_resolution_time)/60+extract(second FROM service_order_resolution_time)/3600)
-(extract(day from service_order_creation_time)*24+extract(hour FROM service_order_creation_time)+
extract(minute FROM service_order_creation_time)/60+extract(second FROM service_order_creation_time)/3600)),2)||' hours' AS "Order Summary On/After 16th"
from t7_service_order
where service_order_resolution_time >= to_timestamp('16-NOV-16 12.00.00', 'DD-MON-YY HH12.MI.SS');

--12 creating a synonym for table t7_service_order_assignment
CREATE synonym t7_soa for t7_service_order_assignment;

--13 SO assignment
select t7_soa.service_order_id, rtrim(emp.ee_first_name)||' '||rtrim(emp.ee_last_name) as "Engineer Assigned", emp.department_id, dep.department_name
from t7_soa
JOIN t7_employee emp
USING (employee_id)
JOIN t7_department dep
on emp.department_id = dep.department_id;

--14 renaming column in an existing
alter table t7_staging_dep
RENAME COLUMN mini_stock to min_stock;

--15 using join on warehouse and staging
select sd.warehouse_id as "Warehouse ID", sd.terminal_part_no as "Terminal Part No.", sd.quantity_in_hand as "Total In Stock", sd.min_stock as "Minimum Required", sd.max_stock as "Maximum Required",
(case when sd.quantity_in_hand < sd.min_stock then (sd.max_stock - sd.quantity_in_hand) else 0 end) AS "Reorder Quantity", w.quantity as "Quantity in Main Warehouse",
(case when (case when sd.quantity_in_hand < sd.min_stock then (sd.max_stock - sd.quantity_in_hand) else 0 end)> w.quantity then w.quantity else (case when sd.quantity_in_hand < sd.min_stock then (sd.max_stock - sd.quantity_in_hand) else 0 end) end) as "Order quantity"
from t7_staging_dep sd
join t7_warehouse w
on sd.terminal_part_no = w.terminal_part_no;

--16 Engineer SLA before and after solution
select so.service_order_id as "Service Order", sa.employee_id as "employee_id",round(((extract(day from so.service_order_resolution_time)*24+extract(hour FROM so.service_order_resolution_time)+
extract(minute FROM so.service_order_resolution_time)/60+extract(second FROM so.service_order_resolution_time)/3600)
-(extract(day from so.service_order_creation_time)*24+extract(hour FROM so.service_order_creation_time)+
extract(minute FROM so.service_order_creation_time)/60+extract(second FROM so.service_order_creation_time)/3600)),2) AS "Resolution time in hours",b.sla_time as "Agreed SLA",
(case when round(((extract(day from so.service_order_resolution_time)*24+extract(hour FROM so.service_order_resolution_time)+
extract(minute FROM so.service_order_resolution_time)/60+extract(second FROM so.service_order_resolution_time)/3600)
-(extract(day from so.service_order_creation_time)*24+extract(hour FROM so.service_order_creation_time)+
extract(minute FROM so.service_order_creation_time)/60+extract(second FROM so.service_order_creation_time)/3600)),2) <= b.sla_time then 'Yes' else 'No' end) as "Is_within_SLA",
(case when so.service_order_resolution_time < to_timestamp('16-NOV-16 12.00.00', 'DD-MON-YY HH12.MI.SS') then 'Before Solution' else 'After Solution' end) as "Before/After Implementation"
from t7_service_order_assignment sa
JOIN t7_service_order so
on sa.SERVICE_ORDER_ID = so.SERVICE_ORDER_ID
join t7_bank b
on b.bank_id = so.BANK_ID
where so.service_order_status = 'Closed'
order by 6 desc;


--17 exceeding sla time before 16
select so.bank_id, so.service_order_id, round(((extract(day from so.service_order_resolution_time)*24+extract(hour FROM so.service_order_resolution_time)+
extract(minute FROM so.service_order_resolution_time)/60+extract(second FROM so.service_order_resolution_time)/3600)
-(extract(day from so.service_order_creation_time)*24+extract(hour FROM so.service_order_creation_time)+
extract(minute FROM so.service_order_creation_time)/60+extract(second FROM so.service_order_creation_time)/3600)),2) AS "Resolution Time in Hours", b.sla_time AS "Bank's SLA", so.engineer_comments AS "Engineer Comments"
FROM t7_service_order so
JOIN t7_bank b
on b.bank_id = so.bank_id
where so.service_order_resolution_time < to_timestamp('16-NOV-16 12.00.00', 'DD-MON-YY HH12.MI.SS')
AND round(((extract(day from so.service_order_resolution_time)*24+extract(hour FROM so.service_order_resolution_time)+extract(minute FROM so.service_order_resolution_time)/60+extract(second FROM so.service_order_resolution_time)/3600)-(extract(day from so.service_order_resolution_time)*24+extract(hour FROM so.service_order_creation_time)+extract(minute FROM so.service_order_creation_time)/60+extract(second FROM so.service_order_creation_time)/3600)),2) > b.sla_time
AND so.service_order_status = 'Closed';

--18 No of calls fixed by engineers before 16th and their root cause
select count(engineer_comments) AS "No. of calls ", engineer_comments AS "Engineer Comments"
from t7_service_order
where service_order_resolution_time < to_timestamp('16-NOV-16 12.00.00', 'DD-MON-YY HH12.MI.SS')
and service_order_status = 'Closed'
and ENGINEER_COMMENTS IS NOT NULL
group by engineer_comments
order by 1 desc;


--19 No. Of calls fixed by first line maintenance on/after 16th
select count(flm_comments) AS "No. of calls fixed by phone", flm_comments AS "FLM Comments"
from t7_service_order
where flm_comments = UPPER('Fixed through Phone')
group by flm_comments;


--20 resolution history
select so.service_order_id, so.BANK_ID,
round(((extract(day from so.service_order_resolution_time)*24+extract(hour FROM so.service_order_resolution_time)+
extract(minute FROM so.service_order_resolution_time)/60+extract(second FROM so.service_order_resolution_time)/3600)
-(extract(day from so.service_order_creation_time)*24+extract(hour FROM so.service_order_creation_time)+
extract(minute FROM so.service_order_creation_time)/60+extract(second FROM so.service_order_creation_time)/3600)),2) AS "Issue resolution time", 
b.SLA_TIME, 
(case when round(((extract(day from so.service_order_resolution_time)*24+extract(hour FROM so.service_order_resolution_time)+
extract(minute FROM so.service_order_resolution_time)/60+extract(second FROM so.service_order_resolution_time)/3600)
-(extract(day from so.service_order_creation_time)*24+extract(hour FROM so.service_order_creation_time)+
extract(minute FROM so.service_order_creation_time)/60+extract(second FROM so.service_order_creation_time)/3600)),2) <= b.sla_time then 'Yes' else 'No' end) as "Is_within_SLA",
(case when so.service_order_resolution_time < to_timestamp('16-NOV-16 12.00.00', 'DD-MON-YY HH12.MI.SS') then 'Before Solution' else 'After Solution' end) as "Before/After Implementation"
FROM t7_service_order so join t7_bank b on so.BANK_ID = b.BANK_ID
where so.SERVICE_ORDER_STATUS = 'Closed'
order by so.bank_id;

-- 21
--% sla compliance of each bank before process reengineering i.e. before 16th NOV
select t7_bank.BANK_NAME,
sum(case when round(((extract(day from service_order_resolution_time)*24+extract(hour FROM service_order_resolution_time)+
extract(minute FROM service_order_resolution_time)/60+extract(second FROM service_order_resolution_time)/3600)
-(extract(day from service_order_creation_time)*24+extract(hour FROM service_order_creation_time)+
extract(minute FROM service_order_creation_time)/60+extract(second FROM service_order_creation_time)/3600)),2) <= t7_bank.sla_time then 1 else 1 end) as "Total no. of calls",
sum(case when round(((extract(day from service_order_resolution_time)*24+extract(hour FROM service_order_resolution_time)+
extract(minute FROM service_order_resolution_time)/60+extract(second FROM service_order_resolution_time)/3600)
-(extract(day from service_order_creation_time)*24+extract(hour FROM service_order_creation_time)+
extract(minute FROM service_order_creation_time)/60+extract(second FROM service_order_creation_time)/3600)),2) <= t7_bank.sla_time then 1 else 0 end) as "Calls fixed within SLA",
round(((
sum(case when round(((extract(day from service_order_resolution_time)*24+extract(hour FROM service_order_resolution_time)+
extract(minute FROM service_order_resolution_time)/60+extract(second FROM service_order_resolution_time)/3600)
-(extract(day from service_order_creation_time)*24+extract(hour FROM service_order_creation_time)+
extract(minute FROM service_order_creation_time)/60+extract(second FROM service_order_creation_time)/3600)),2) <= t7_bank.sla_time then 1 else 0 end)
)/(
sum(case when round(((extract(day from service_order_resolution_time)*24+extract(hour FROM service_order_resolution_time)+
extract(minute FROM service_order_resolution_time)/60+extract(second FROM service_order_resolution_time)/3600)
-(extract(day from service_order_creation_time)*24+extract(hour FROM service_order_creation_time)+
extract(minute FROM service_order_creation_time)/60+extract(second FROM service_order_creation_time)/3600)),2) <= t7_bank.sla_time then 1 else 1 end)
))*100,2) as "%SLA Compliance before sol"
FROM t7_service_order join t7_bank on t7_service_order.BANK_ID = t7_bank.BANK_ID
where t7_service_order.SERVICE_ORDER_STATUS = 'Closed' and service_order_resolution_time < to_timestamp('16-NOV-16 12.00.00', 'DD-MON-YY HH12.MI.SS')
group by t7_bank.BANK_name
order by t7_bank.BANK_name;

-- 22
--% sla compliance of each bank after process reengineering i.e. on and after 16th NOV
select t7_bank.BANK_NAME,
sum(case when round(((extract(day from service_order_resolution_time)*24+extract(hour FROM service_order_resolution_time)+
extract(minute FROM service_order_resolution_time)/60+extract(second FROM service_order_resolution_time)/3600)
-(extract(day from service_order_creation_time)*24+extract(hour FROM service_order_creation_time)+
extract(minute FROM service_order_creation_time)/60+extract(second FROM service_order_creation_time)/3600)),2) <= t7_bank.sla_time then 1 else 1 end) as "Total no. of calls",
sum(case when round(((extract(day from service_order_resolution_time)*24+extract(hour FROM service_order_resolution_time)+
extract(minute FROM service_order_resolution_time)/60+extract(second FROM service_order_resolution_time)/3600)
-(extract(day from service_order_creation_time)*24+extract(hour FROM service_order_creation_time)+
extract(minute FROM service_order_creation_time)/60+extract(second FROM service_order_creation_time)/3600)),2) <= t7_bank.sla_time then 1 else 0 end) as "Calls fixed within SLA",
round(((
sum(case when round(((extract(day from service_order_resolution_time)*24+extract(hour FROM service_order_resolution_time)+
extract(minute FROM service_order_resolution_time)/60+extract(second FROM service_order_resolution_time)/3600)
-(extract(day from service_order_creation_time)*24+extract(hour FROM service_order_creation_time)+
extract(minute FROM service_order_creation_time)/60+extract(second FROM service_order_creation_time)/3600)),2) <= t7_bank.sla_time then 1 else 0 end)
)/(
sum(case when round(((extract(day from service_order_resolution_time)*24+extract(hour FROM service_order_resolution_time)+
extract(minute FROM service_order_resolution_time)/60+extract(second FROM service_order_resolution_time)/3600)
-(extract(day from service_order_creation_time)*24+extract(hour FROM service_order_creation_time)+
extract(minute FROM service_order_creation_time)/60+extract(second FROM service_order_creation_time)/3600)),2) <= t7_bank.sla_time then 1 else 1 end)
))*100,2) as "%SLA Compliance after sol"
FROM t7_service_order join t7_bank on t7_service_order.BANK_ID = t7_bank.BANK_ID
where t7_service_order.SERVICE_ORDER_STATUS = 'Closed' and service_order_resolution_time >= to_timestamp('16-NOV-16 12.00.00', 'DD-MON-YY HH12.MI.SS')
group by t7_bank.BANK_name
order by t7_bank.BANK_name;

--23
--% calls fixed by flm after process reengineering
select count(service_order_id) as "Total calls fixed after sol",
sum(case when flm_comments = Upper('fixed through phone') then 1 else 0 end) as "Calls fixed by phone",
round(((sum(case when flm_comments = Upper('fixed through phone') then 1 else 0 end)) / count(service_order_id))*100,2) as "%Calls fixed by FLM"
from t7_service_order
where service_order_status = 'Closed' and service_order_resolution_time >= to_timestamp('16-NOV-16 12.00.00', 'DD-MON-YY HH12.MI.SS');
 
--24
--% calls fixed by terminal reset (before process reengineering) which could actually be fixed on call
select count(service_order_id) as "Total calls fixed before sol",
sum(case when engineer_comments = Upper('reset terminal and tested ok') then 1 else 0 end) as "Calls fixed by terminal RESET",
round(((sum(case when engineer_comments = Upper('reset terminal and tested ok') then 1 else 0 end)) / count(service_order_id))*100,2) as "%Calls fixed by RESET"
from t7_service_order
where service_order_status = 'Closed' and service_order_resolution_time < to_timestamp('16-NOV-16 12.00.00', 'DD-MON-YY HH12.MI.SS');





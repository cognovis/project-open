-- /packages/intranet-expenses/sql/common/intranet-expenses-create.sql
--
-- ]project-open[ Expenses
-- 060419 avila@digiteix.com
--
-- Copyright (C) 2004 - 2009 ]project-open[
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

-- set escape \

-------------------------------------------------------------
-- Setup the status and type im_categories

-- 4000-4099	Intranet Expense Type
-- 4100-4199	Intranet Expense Payment Type
-- 4200-4599    (reserved)

-- prompt *** intranet-expenses: Creating URLs for viewing/editing expenses
delete from im_biz_object_urls where object_type='im_expense';
insert into im_biz_object_urls (
	object_type, 
	url_type, 
	url
) values (
	'im_expense',
	'view',
	'/intranet-expenses/new?form_mode=display\&expense_id='
);

insert into im_biz_object_urls (
	object_type, 
	url_type, 
	url
) values (
	'im_expense',
	'edit',
	'/intranet-expenses/new?form_mode=edit\&expense_id='
);


-- delete from im_categories where category_id in (3720, 3722);
--
-- INSERT INTO im_categories (category_id, category, category_type)
-- VALUES (3720,'Expense Item','Intranet Cost Type');
--
-- INSERT INTO im_categories (category_id, category, category_type)
-- VALUES (3722,'Expense Report','Intranet Cost Type');



-- Intranet Expense Type
-- delete from im_categories where category_id >= 4000 and category_id < 4100;

SELECT im_category_new(4000,'Meals','Intranet Expense Type');
SELECT im_category_new(4001,'Fuel','Intranet Expense Type');
SELECT im_category_new(4002,'Tolls','Intranet Expense Type');
SELECT im_category_new(4003,'Km own car','Intranet Expense Type');
SELECT im_category_new(4004,'Parking','Intranet Expense Type');
SELECT im_category_new(4005,'Taxi','Intranet Expense Type');
SELECT im_category_new(4006,'Hotel','Intranet Expense Type');
SELECT im_category_new(4007,'Airfare','Intranet Expense Type');
SELECT im_category_new(4008,'Train','Intranet Expense Type');
SELECT im_category_new(4009,'Copies','Intranet Expense Type');
SELECT im_category_new(4010,'Office Material','Intranet Expense Type');
SELECT im_category_new(4011,'Telephone','Intranet Expense Type');
SELECT im_category_new(4012,'Other','Intranet Expense Type');

-- reserved until 4099


-- Intranet Expense Payment Type
-- delete from im_categories where category_id >= 4100 and category_id < 4200;

SELECT im_category_new(4100, 'Cash','Intranet Expense Payment Type');
SELECT im_category_new(4105, 'Company Visa 1','Intranet Expense Payment Type');
SELECT im_category_new(4110, 'Company Visa 2','Intranet Expense Payment Type');
SELECT im_category_new(4115, 'PayPal tigerpond@tigerpond.com','Intranet Expense Payment Type');


create or replace view im_expense_type as
select
	category_id as expense_type_id,
	category as expense_type
from 	im_categories
where	category_type = 'Intranet Expense Type';

create or replace view im_expense_payment_type as
select	category_id as expense_payment_type_id, 
	category as expense_payment_type
from 	im_categories
where 	category_type = 'Intranet Expense Payment Type';




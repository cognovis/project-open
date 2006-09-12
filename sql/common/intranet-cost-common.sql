-- /packages/intranet-cost/sql/common/intranet-cost-create.sql
--
-- Project/Open Cost Core
-- 040207 frank.bergmann@project-open.com
--
-- Copyright (C) 2004 Project/Open
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

-- set escape \

-------------------------------------------------------------
-- Setup the status and type im_categories

-- 3000-3099    Intranet Cost Center Type
-- 3100-3199    Intranet Cost Center Status
-- 3200-3299    Intranet CRM Tracking
-- 3300-3399    reserved for cost centers
-- 3400-3499    Intranet Investment Type
-- 3500-3599    Intranet Investment Status
-- 3600-3699	Intranet Investment Amortization Interval (reserved)
-- 3700-3799    Intranet Cost Type
-- 3800-3899    Intranet Cost Status
-- 3900-3999    Intranet Cost Planning Type
-- 4000-4599    (reserved)



-- prompt *** intranet-costs: Creating URLs for viewing/editing cost centers
delete from im_biz_object_urls where object_type='im_cost_center';
insert into im_biz_object_urls (
	object_type, 
	url_type, 
	url
) values (
	'im_cost_center',
	'view',
	'/intranet-cost/cost-centers/new?form_mode=display\&cost_center_id='
);

insert into im_biz_object_urls (
	object_type, 
	url_type, 
	url
) values (
	'im_cost_center',
	'edit',
	'/intranet-cost/cost-centers/new?form_mode=edit\&cost_center_id='
);


-- prompt *** intranet-costs: Creating Cost Center categories
-- Intranet Cost Center Type
delete from im_categories where category_id >= 3000 and category_id < 3100;
INSERT INTO im_categories VALUES (3001,'Cost Center','','Intranet Cost Center Type',1,'f','f');
INSERT INTO im_categories VALUES (3002,'Profit Center','','Intranet Cost Center Type',1,'f','f');
INSERT INTO im_categories VALUES (3003,'Investment Center','','Intranet Cost Center Type',1,'f','f');
INSERT INTO im_categories VALUES (3004,'Subdepartment','Department without budget responsabilities',
'Intranet Cost Center Type',1,'f','f');
-- commit;
-- reserved until 3099


-- Intranet Cost Center Type
delete from im_categories where category_id >= 3100 and category_id < 3200;
INSERT INTO im_categories VALUES (3101,'Active','','Intranet Cost Center Status',1,'f','f');
INSERT INTO im_categories VALUES (3102,'Inactive','','Intranet Cost Center Status',1,'f','f');
-- commit;
-- reserved until 3099




-- Create URLs for viewing/editing costs
delete from im_biz_object_urls where object_type='im_cost';
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_cost','view','/intranet-cost/costs/new?form_mode=display\&cost_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_cost','edit','/intranet-cost/costs/new?form_mode=edit\&cost_id=');


-- prompt *** intranet-costs: Creating URLs for viewing/editing investments
delete from im_biz_object_urls where object_type='im_investment';
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_investment','view','/intranet-cost/investments/new?form_mode=display\&investment_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_investment','edit','/intranet-cost/investments/new?form_mode=edit\&investment_id=');


-- prompt *** intranet-costs: Creating Investment categories
-- Intranet Investment Type
delete from im_categories where category_id >= 3400 and category_id < 3500;
INSERT INTO im_categories (category_id, category, category_type) 
VALUES (3401,'Other','Intranet Investment Type');
INSERT INTO im_categories (category_id, category, category_type) 
VALUES (3403,'Computer Hardware','Intranet Investment Type');
INSERT INTO im_categories (category_id, category, category_type) 
VALUES (3405,'Computer Software','Intranet Investment Type');
INSERT INTO im_categories (category_id, category, category_type) 
VALUES (3407,'Office Furniture','Intranet Investment Type');
-- commit;
-- reserved until 3499

-- Intranet Investment Status
delete from im_categories where category_id >= 3500 and category_id < 3599;
INSERT INTO im_categories (category_id, category, category_type, category_description) 
VALUES (3501,'Active','Intranet Investment Status','Currently being amortized');
INSERT INTO im_categories (category_id, category, category_type, category_description) 
VALUES (3503,'Deleted','Intranet Investment Status','Deleted - was an error');
INSERT INTO im_categories (category_id, category, category_type, category_description) 
VALUES (3505,'Amortized','Intranet Investment Status','No remaining book value');
-- commit;
-- reserved until 3599


-- Cost Templates
delete from im_categories where category_id >= 900 and category_id < 1000;
INSERT INTO im_categories VALUES (900,'invoice.en.adp','','Intranet Cost Template','category','t','f');
INSERT INTO im_categories VALUES (902,'invoice.es.adp','','Intranet Cost Template','category','t','f');
INSERT INTO im_categories VALUES (904,'quote.en.adp','','Intranet Cost Template','category','t','f');
INSERT INTO im_categories VALUES (906,'quote.es.adp','','Intranet Cost Template','category','t','f');
INSERT INTO im_categories VALUES (908,'po.en.adp','','Intranet Cost Template','category','t','f');
INSERT INTO im_categories VALUES (910,'po.es.adp','','Intranet Cost Template','category','t','f');


-- reserved until 999



-- prompt *** intranet-costs: Creating category Cost Type
-- Cost Type
delete from im_categories where category_id >= 3700 and category_id < 3799;
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3700,'Customer Invoice','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3702,'Quote','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3704,'Provider Bill','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3706,'Purchase Order','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3708,'Customer Documents','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3710,'Provider Documents','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
-- VALUES (3712,'Travel Cost','Intranet Cost Type');
-- INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3714,'Employee Salary','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3716,'Repeating Cost','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3718,'Timesheet Cost','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3720,'Expense Item','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3722,'Expense Report','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3724,'Delivery Note','Intranet Cost Type');


-- commit;
-- reserved until 3799

-- Establish the super-categories "Provider Documents" and "Customer Documents"
insert into im_category_hierarchy values (3710,3704);
insert into im_category_hierarchy values (3710,3706);
insert into im_category_hierarchy values (3708,3700);
insert into im_category_hierarchy values (3708,3702);
insert into im_category_hierarchy values (3708,3724);


-- prompt *** intranet-costs: Creating category Cost Status
-- Intranet Cost Status
delete from im_categories where category_id >= 3800 and category_id < 3899;
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3802,'Created','Intranet Cost Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3804,'Outstanding','Intranet Cost Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3806,'Past Due','Intranet Cost Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3808,'Partially Paid','Intranet Cost Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3810,'Paid','Intranet Cost Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3812,'Deleted','Intranet Cost Status');
INSERT INTO im_categories (category_id, category, category_type)
VALUES (3814,'Filed','Intranet Cost Status');
-- commit;
-- reserved until 3899


-- prompt *** intranet-costs: Creating status and type views
create or replace view im_cost_status as
select
	category_id as cost_status_id,
	category as cost_status
from 	im_categories
where	category_type = 'Intranet Cost Status' and
	category_id not in (3812);


create or replace view im_cost_types as
select	category_id as cost_type_id, 
	category as cost_type,
	CASE 
	    WHEN category_id = 3700 THEN 'fi_read_invoices'
	    WHEN category_id = 3702 THEN 'fi_read_quotes'
	    WHEN category_id = 3704 THEN 'fi_read_bills'
	    WHEN category_id = 3706 THEN 'fi_read_pos'
	    WHEN category_id = 3716 THEN 'fi_read_repeatings'
	    WHEN category_id = 3718 THEN 'fi_read_timesheets'
	    WHEN category_id = 3720 THEN 'fi_read_expense_items'
	    WHEN category_id = 3722 THEN 'fi_read_expense_reports'
	    WHEN category_id = 3724 THEN 'fi_read_delivery_notes'
	    ELSE 'fi_read_all'
	END as read_privilege,
	CASE 
	    WHEN category_id = 3700 THEN 'fi_write_invoices'
	    WHEN category_id = 3702 THEN 'fi_write_quotes'
	    WHEN category_id = 3704 THEN 'fi_write_bills'
	    WHEN category_id = 3706 THEN 'fi_write_pos'
	    WHEN category_id = 3716 THEN 'fi_write_repeatings'
	    WHEN category_id = 3718 THEN 'fi_write_timesheets'
	    WHEN category_id = 3720 THEN 'fi_write_expense_items'
	    WHEN category_id = 3722 THEN 'fi_write_expense_reports'
	    WHEN category_id = 3724 THEN 'fi_write_delivery_notes'
	    ELSE 'fi_write_all'
	END as write_privilege
from 	im_categories
where 	category_type = 'Intranet Cost Type';


-------------------------------------------------------------
-- Cost Views
--

-- Cost List
--
insert into im_views (view_id, view_name, visible_for)
values (220, 'cost_list', 'view_finance');
insert into im_views (view_id, view_name, visible_for)
values (221, 'cost_new', 'view_finance');

-- Cost List Page
--
delete from im_view_columns where column_id > 22000 and column_id < 22099;
--
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22001,220,'Name',
'"<A HREF=${cost_url}$cost_id>[string range $cost_name 0 30]</A>"',1);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22003,220,'Type','$cost_type',3);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22005,220,'Project',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"',5);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22007,220,'Provider',
'"<A HREF=/intranet/companies/view?company_id=$provider_id>$provider_name</A>"',7);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22011,220,'Client',
'"<A HREF=/intranet/companies/view?company_id=$customer_id>$customer_name</A>"',11);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22013,220,'Start Block',
'$start_block_formatted',13);
-- insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
-- sort_order) values (22013,220,'Start Block',
-- '$start_block',13);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22015,220,'Due Date',
'[if {$overdue > 0} {
	set t "<font color=red>$due_date_calculated</font>"
} else {
	set t "$due_date_calculated"
}]',15);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22021,220,'Amount','"$amount_formatted $currency"',21);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22023,220,'Paid', '"$paid_amount $paid_currency"',23);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22025,220,'Status',
'[im_cost_status_select "cost_status.$cost_id" $cost_status_id]',25);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (22098,220,'Del',
'"<input type=hidden name=object_type.$cost_id value=$object_type>
<input type=checkbox name=del_cost value=$cost_id>"',99);
-- commit;


---------------------------------------------------------
-- Project Profit & Loss List
-- The "view_id = 21" entry has already been added in intranet_views.sql
--
delete from im_view_columns where column_id > 2100 and column_id < 2199;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2101,21,NULL,'Project Nr',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"',
'','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2102,21,NULL,'Name',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_name</A>"',
'','',2,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2103,21,NULL,'Client',
'"<A HREF=/intranet/companies/view?company_id=$company_id>$company_name</A>"',
'','',3,'im_permission $user_id view_companies');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2105,21,NULL,'Type',
'$project_type','','',5,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2107,21,NULL,'Status',
'$project_status','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2111,21,NULL,'Budget',
'"$project_budget $project_budget_currency"','','',11,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2113,21,NULL,'Budget Hours',
'$project_budget_hours','','',13,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2115,21,NULL,'Perc Compl',
'$percent_completed','','',15,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2131,21,NULL,'Invoices',
'$cost_invoices_cache','','',31,'im_permission $user_id view_finance');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2133,21,NULL,'Bills',
'$cost_bills_cache','','',33,'im_permission $user_id view_finance');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2135,21,NULL,'Time sheet',
'$cost_timesheet_logged_cache','','',35,'im_permission $user_id view_finance');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2137,21,NULL,'Profit',
'[expr [n20 $cost_invoices_cache] - [n20 $cost_bills_cache] - [n20 $cost_timesheet_logged_cache]]',
'','',37,'im_permission $user_id view_finance');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2141,21,NULL,'Quotes',
'$cost_quotes_cache','','',41,'im_permission $user_id view_finance');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2143,21,NULL,'POs',
'$cost_purchase_orders_cache','','',43,'im_permission $user_id view_finance');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2145,21,NULL,'Time plan',
'$cost_timesheet_planned_cache','','',45,'im_permission $user_id view_finance');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2147,21,NULL,'Prelim Profit',
'[expr [n20 $cost_quotes_cache] - [n20 $cost_purchase_orders_cache] - [n20 $cost_timesheet_planned_cache]]',
'','',47,'im_permission $user_id view_finance');




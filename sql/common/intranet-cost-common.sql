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



-- Intranet Cost Center Type
SELECT im_category_new (3001,'Cost Center','Intranet Cost Center Type');
SELECT im_category_new (3002,'Profit Center','Intranet Cost Center Type');
SELECT im_category_new (3003,'Investment Center','Intranet Cost Center Type');
SELECT im_category_new (3004,'Subdepartment','Intranet Cost Center Type');
-- reserved until 3099


-- Intranet Cost Center Type
SELECT im_category_new (3101,'Active','Intranet Cost Center Status');
SELECT im_category_new (3102,'Inactive','Intranet Cost Center Status');
-- reserved until 3099



-- Creating Investment categories
SELECT im_category_new(3401,'Other','Intranet Investment Type');
SELECT im_category_new(3403,'Computer Hardware','Intranet Investment Type');
SELECT im_category_new(3405,'Computer Software','Intranet Investment Type');
SELECT im_category_new(3407,'Office Furniture','Intranet Investment Type');
-- reserved until 3499

-- Intranet Investment Status
SELECT im_category_new(3501,'Active','Intranet Investment Status');
SELECT im_category_new(3503,'Deleted','Intranet Investment Status');
SELECT im_category_new(3505,'Amortized','Intranet Investment Status');
-- reserved until 3599


-- Cost Templates
SELECT im_category_new (900,'invoice.en.adp','Intranet Cost Template');
SELECT im_category_new (902,'invoice.es.adp','Intranet Cost Template');
SELECT im_category_new (904,'quote.en.adp','Intranet Cost Template');
SELECT im_category_new (906,'quote.es.adp','Intranet Cost Template');
SELECT im_category_new (908,'po.en.adp','Intranet Cost Template');
SELECT im_category_new (910,'po.es.adp','Intranet Cost Template');
-- reserved until 999


-- Creating category Cost Type
SELECT im_category_new (3700,'Customer Invoice','Intranet Cost Type');
SELECT im_category_new (3702,'Quote','Intranet Cost Type');
SELECT im_category_new (3704,'Provider Bill','Intranet Cost Type');
SELECT im_category_new (3706,'Purchase Order','Intranet Cost Type');
SELECT im_category_new (3708,'Customer Documents','Intranet Cost Type');
SELECT im_category_new (3710,'Provider Documents','Intranet Cost Type');
SELECT im_category_new (3714,'Employee Salary','Intranet Cost Type');
SELECT im_category_new (3716,'Repeating Cost','Intranet Cost Type');
SELECT im_category_new (3718,'Timesheet Cost','Intranet Cost Type');
SELECT im_category_new (3720,'Expense Item','Intranet Cost Type');
SELECT im_category_new (3722,'Expense Bundle','Intranet Cost Type');
SELECT im_category_new (3724,'Delivery Note','Intranet Cost Type');
-- reserved until 3799

-- Establish the super-categories "Provider Documents" and "Customer Documents"
SELECT im_category_hierarchy_new(3704,3710);
SELECT im_category_hierarchy_new(3706,3710);
SELECT im_category_hierarchy_new(3700,3708);
SELECT im_category_hierarchy_new(3702,3708);
SELECT im_category_hierarchy_new(3724,3708);


-- Creating category Cost Status
delete from im_categories where category_id >= 3800 and category_id < 3899;
SELECT im_category_new (3802,'Created','Intranet Cost Status');
SELECT im_category_new (3804,'Outstanding','Intranet Cost Status');
SELECT im_category_new (3806,'Past Due','Intranet Cost Status');
SELECT im_category_new (3808,'Partially Paid','Intranet Cost Status');
SELECT im_category_new (3810,'Paid','Intranet Cost Status');
SELECT im_category_new (3812,'Deleted','Intranet Cost Status');
SELECT im_category_new (3814,'Filed','Intranet Cost Status');
SELECT im_category_new (3816,'Requested','Intranet Cost Status');
SELECT im_category_new (3818,'Rejected','Intranet Cost Status');
-- reserved until 3899


-------------------------------------------------------------
-- Cost Views
--


delete from im_views where view_id = 221;
delete from im_view_columns where view_id = 221;
insert into im_views (view_id, view_name, visible_for)
values (221, 'cost_new', 'view_finance');

-- Cost List
--
delete from im_views where view_id = 220;
delete from im_view_columns where view_id = 220;

insert into im_views (view_id, view_name, visible_for)
values (220, 'cost_list', 'view_finance');

-- Cost List Page
--
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
extra_select, extra_where, sort_order, visible_for) values (2109,21,NULL,'Project Manager',
'"<A HREF=/intranet/users/view?user_id=$project_lead_id>$lead_name</A>"',
'','',9,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2110,21,NULL,'Invalid Since',
'"[string range $cost_cache_dirty 0 9]"','','',10,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2111,21,NULL,'Budget',
'"$project_budget $project_budget_currency"','','',11,'im_permission $user_id view_budget');


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2113,21,NULL,'Budget Hours',
'$project_budget_hours','','',13,'im_permission $user_id view_budget_hours');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2114,21,NULL,'Reported Hours',
'$reported_hours_cache','','',14,'im_permission $user_id view_budget_hours');


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2115,21,NULL,'Perc Compl',
'$percent_completed','','',15,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2131,21,NULL,'Invoices',
'$cost_invoices_cache','','',31,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2133,21,NULL,'Bills',
'$cost_bills_cache','','',33,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2134,21,NULL,'Expenses',
'$cost_expense_logged_cache','','',34,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2135,21,NULL,'Time sheet',
'$cost_timesheet_logged_cache','','',35,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2137,21,NULL,'Profit',
'[expr [n20 $cost_invoices_cache] - [n20 $cost_bills_cache] - [n20 $cost_expense_logged_cache] - [n20 $cost_timesheet_logged_cache]]',
'','',37,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2141,21,NULL,'Quotes',
'$cost_quotes_cache','','',41,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2143,21,NULL,'POs',
'$cost_purchase_orders_cache','','',43,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2145,21,NULL,'Time plan',
'$cost_timesheet_planned_cache','','',45,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2147,21,NULL,'Prelim Profit',
'[expr [n20 $cost_quotes_cache] - [n20 $cost_purchase_orders_cache] - [n20 $cost_timesheet_planned_cache]]',
'','',47,'expr [im_permission $user_id view_finance] && [im_cc_read_p]');


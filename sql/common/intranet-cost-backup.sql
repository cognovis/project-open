-- /packages/intranet-cost/sql/oracle/intranet-cost-backup.sql
--
-- Copyright (C) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- 100	im_projects
-- 101	im_project_roles
-- 102	im_customers
-- 103	im_customer_roles
-- 104	im_offices
-- 105	im_office_roles
-- 106	im_categories
--
-- 110	users
-- 111	im_profiles
--
-- 120	im_freelancers
--
-- 130	im_forums
--
-- 140	im_filestorage
--
-- 150	im_translation
--
-- 160	im_quality
--
-- 170	im_marketplace
--
-- 180	im_hours
--
-- 190	im_costs
-- 191	im_payments
-- 192	im_invoices
-- 193	im_invoice_items
-- 194	im_project_invoice_map
-- 195	im_trans_prices
-- 196	im_cost_centers
-- 197	im_investments
-- 198	im_repeating_costs
--
-- 200	already occupied



---------------------------------------------------------
-- Backup Costs
--

delete from im_view_columns where view_id = 190;
delete from im_views where view_id = 190;
insert into im_views (view_id, view_name, view_sql
) values (190, 'im_costs', '
SELECT
	c.*,
	o.*,
	cust.customer_name as customer_name,
	prov.customer_name as provider_name,
	p.project_name,
	i.name as investment_name,
	cc.cost_center_label,
	cp.cost_nr as parent_cost_nr,
	im_category_from_id(c.template_id) as template,
	im_category_from_id(c.cost_status_id) as cost_status,
	im_category_from_id(c.cost_type_id) as cost_type,
	im_category_from_id(c.planning_type_id) as planning_type,
	im_email_from_user_id(o.modifying_user) as last_modifying_email,
	im_email_from_user_id(o.creation_user) as creator_email
FROM
	im_costs c,
	acs_objects o,
	im_projects p,
	im_investments i,
	im_customers cust,
	im_customers prov,
	im_cost_centers cc,
	im_costs cp
WHERE
	c.cost_id = o.object_id
	and c.customer_id = cust.customer_id
	and c.provider_id = prov.customer_id
	and c.project_id = p.project_id(+)
	and c.cost_center_id = cc.cost_center_id(+)
	and c.parent_id = cp.cost_id(+)
	and c.investment_id = i.investment_id(+)
');

delete from im_view_columns where column_id > 19000 and column_id < 19099;
--
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19001,190,NULL,'cost_name','$cost_name','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19002,190,NULL,'cost_nr','$cost_nr','','',2,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19003,190,NULL,'customer_name','$customer_name','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19004,190,NULL,'provider_name','$provider_name','','',4,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19005,190,NULL,'creator_email','$creator_email','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19006,190,NULL,'project_name','$project_name','','',6,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19007,190,NULL,'start_block','$start_block','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19009,190,NULL,'effective_date','$effective_date','','',9,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19010,190,NULL,'investment_name','$investment_name','','',10,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19011,190,NULL,'cost_center_label','$cost_center_label','','',11,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19013,190,NULL,'currency','$currency','','',13,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19014,190,NULL,'template','$template','','',14,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19015,190,NULL,'cost_status','$cost_status','','',15,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19017,190,NULL,'cost_type','$cost_type','','',17,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19021,190,NULL,'payment_days','$payment_days','','',21,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19023,190,NULL,'vat','$vat','','',23,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19025,190,NULL,'tax','$tax','','',25,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19029,190,NULL,'last_modified','$last_modified','','',29,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19031,190,NULL,'last_modifying_email','$last_modifying_email',
'','',31,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19033,190,NULL,'modifying_ip','$modifying_ip','','',33,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19035,190,NULL,'amount','$amount','','',35,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19037,190,NULL,'variable_cost_p','$variable_cost_p','','',37,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19039,190,NULL,'needs_redistribution_p','$needs_redistribution_p',
'','',39,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19041,190,NULL,'parent_cost_nr','$parent_cost_nr','','',41,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19043,190,NULL,'redistributed_p','$redistributed_p','','',43,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19045,190,NULL,'planning_p','$planning_p','','',45,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19047,190,NULL,'planning_type_id','$planning_type_id','','',47,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19049,190,NULL,'note','[ns_urlencode $note]','','',49,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19051,190,NULL,'description','[ns_urlencode $description]','','',51,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19053,190,NULL,'paid_amount','$paid_amount','','',53,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19055,190,NULL,'paid_currency','$paid_currency','','',55,'');

--
commit;


---------------------------------------------------------
-- Backup Payments
--

delete from im_view_columns where view_id = 191;
delete from im_views where view_id = 191;
insert into im_views (view_id, view_name, view_sql
) values (191, 'im_payments', '
SELECT
	p.*,
	i.cost_nr,
	im_category_from_id(p.payment_status_id) as payment_status,
	im_category_from_id(p.payment_type_id) as payment_type
FROM
	im_payments p,
	im_costs i
WHERE
	p.cost_id = i.cost_id
');


delete from im_view_columns where column_id > 19100 and column_id < 19199;
--
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19101,191,NULL,'cost_nr','$cost_nr','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19103,191,NULL,'received_date','$received_date','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19105,191,NULL,'start_block','$start_block','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19107,191,NULL,'payment_type','$payment_type','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19109,191,NULL,'payment_status','$payment_status','','',9,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19111,191,NULL,'amount','$amount','','',11,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19113,191,NULL,'currency','$currency','','',13,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19114,191,NULL,'note','[ns_urlencode $note]','','',14,'');
--
commit;





---------------------------------------------------------
-- Backup Cost Centers
--

delete from im_view_columns where view_id = 196;
delete from im_views where view_id = 196;
insert into im_views (view_id, view_name, view_sql
) values (196, 'im_cost_centers', '
SELECT
	cc.*,
	ccp.cost_center_label as parent_label,
	im_email_from_user_id(cc.manager_id) as manager_email,
	im_category_from_id(cc.cost_center_status_id) as cost_center_status,
	im_category_from_id(cc.cost_center_type_id) as cost_center_type
FROM
	im_cost_centers cc,
	im_cost_centers ccp
WHERE
	cc.parent_id = ccp.cost_center_id(+)
');
delete from im_view_columns where column_id > 19600 and column_id < 19699;
--
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19601,196,NULL,'cost_center_name','$cost_center_name','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19603,196,NULL,'cost_center_label','$cost_center_label','','',3,'');
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19605,196,NULL,'cost_center_type','$cost_center_type','','',5,'');
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19609,196,NULL,'cost_center_status','$cost_center_status','','',9,'');
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19611,196,NULL,'department_p','$department_p','','',11,'');
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19613,196,NULL,'parent_label','$parent_label','','',13,'');
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19615,196,NULL,'manager_email','$manager_email','','',15,'');
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19617,196,NULL,'description','[ns_urlencode $description]','','',17,'');
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19634,196,NULL,'note','[ns_urlencode $note]','','',34,'');
--
commit;





---------------------------------------------------------
-- Backup Investments
--

delete from im_view_columns where view_id = 197;
delete from im_views where view_id = 197;
insert into im_views (view_id, view_name, view_sql
) values (197, 'im_investments', '
SELECT
	i.*,
	im_category_from_id(i.investment_status_id) as investment_status,
	im_category_from_id(i.investment_type_id) as investment_type
FROM
	im_investments i
');

delete from im_view_columns where column_id > 19700 and column_id < 19799;
--
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19701,197,NULL,'investment_name','$investment_name','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19705,197,NULL,'investment_type','$investment_type','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19709,197,NULL,'investment_status','$investment_status','','',9,'');

-- insert into im_view_columns (column_id, view_id, group_id, column_name,
-- column_render_tcl, extra_select, extra_where, sort_order, visible_for)
-- values (19734,197,NULL,'note','[ns_urlencode $note]','','',34,'');
--
commit;



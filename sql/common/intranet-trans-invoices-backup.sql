-- /packages/intranet-trans-invoices/sql/oracle/intranet-trans-invoices-backup.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- 100	im_projects
-- 101	im_project_roles
-- 102	im_companies
-- 103	im_company_roles
-- 104	im_offices
-- 105	im_office_roles
-- 106	im_categories
--
-- 120  im_freelancers
-- 121  im_freelance_skills
--
-- 130  im_forums
--
-- 140  im_filestorage
--
-- 150  im_translation
--
-- 160  im_quality
--
-- 170  im_marketplace
--
-- 180  im_hours
-- 181  im_absences
--
-- 190  im_costs
-- 191  im_payments
-- 192  im_invoices
-- 193  im_invoice_items
-- 194  im_project_invoice_map
-- 195  im_trans_prices
--


---------------------------------------------------------
-- Backup Prices
--

delete from im_view_columns where view_id = 195;
delete from im_views where view_id = 195;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (
	195, 'im_trans_prices', 1410, 270, '
SELECT
	p.*,
	im_category_from_id(p.uom_id) as uom,
	c.company_name,
	im_category_from_id(p.target_language_id) as target_language,
	im_category_from_id(p.source_language_id) as source_language,
	im_category_from_id(p.task_type_id) as task_type,
	im_category_from_id(p.subject_area_id) as subject_area
FROM
	im_trans_prices p,
	im_companies c
WHERE
	p.company_id = c.company_id
');


delete from im_view_columns where column_id > 19500 and column_id < 19599;
--
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19501,195,NULL,'uom','$uom','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19503,195,NULL,'company_name','$company_name','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19505,195,NULL,'target_language','$target_language','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19507,195,NULL,'source_language','$source_language','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19509,195,NULL,'subject_area','$subject_area','','',9,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19510,195,NULL,'task_type','$task_type','','',10,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19511,195,NULL,'valid_from','$valid_from','','',11,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19513,195,NULL,'valid_through','$valid_through','','',13,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19514,195,NULL,'currency','$currency','','',14,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19515,195,NULL,'price','$price','','',15,'');


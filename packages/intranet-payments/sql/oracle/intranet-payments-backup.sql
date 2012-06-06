-- /packages/intranet-payments/sql/oracle/intranet-payments-backup.sql
--
-- Copyright (C) 2004 Project/Open
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
--
-- @author	frank.bergmann@project-open.com

-- 100	im_projects
-- 101	im_project_roles
-- 102	im_companies
-- 103	im_company_roles
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
-- 190	im_invoices
--
-- 200

---------------------------------------------------------
-- Backup Payments
--

delete from im_view_columns where view_id = 194;
delete from im_views where view_id = 194;
insert into im_views (view_id, view_name, view_type_id, view_sql
) values (194, 'im_payments', 1410, '
SELECT
	p.*,
	i.invoice_nr,
	im_category_from_id(p.payment_status_id) as payment_status,
	im_category_from_id(p.payment_type_id) as payment_type
FROM
	im_payments p,
	im_invoices i
WHERE
	p.invoice_id = i.invoice_id
');


delete from im_view_columns where column_id > 19404 and column_id < 19499;
--
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19401,194,NULL,'invoice_nr','$invoice_nr','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19403,194,NULL,'received_date','$received_date','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19405,194,NULL,'start_block','$start_block','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19407,194,NULL,'payment_type','$payment_type','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19409,194,NULL,'payment_status','$payment_status','','',9,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19411,194,NULL,'amount','$amount','','',11,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19413,194,NULL,'currency','$currency','','',13,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (19414,194,NULL,'note','$note','','',14,'');
--
commit;


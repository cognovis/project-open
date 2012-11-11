-- /packages/intranet-freelance/sql/oracle/intranet-views.sql
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
-- 190



---------------------------------------------------------
-- Backup Freelancers
--

delete from im_view_columns where view_id = 120;
delete from im_views where view_id = 120;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (
	120, 'im_freelancers', 1410, 100, '
select
	f.*,
	im_email_from_user_id(f.user_id) as user_email,
	im_category_from_id(f.payment_method_id) as payment_method
from
	im_freelancers f
');

delete from im_view_columns where column_id > 12004 and column_id < 12099;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl,extra_select, extra_where, sort_order, visible_for) values (
12001,120, NULL,'user_email','$user_email','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl,extra_select, extra_where, sort_order, visible_for) values (
12003,120,NULL,'translation_rate','$translation_rate','','',3,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl,extra_select, extra_where, sort_order, visible_for) values (
12005,120,NULL,'editing_rate','$editing_rate','','',5,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl,extra_select, extra_where, sort_order, visible_for) values (
12007,120,NULL,'hourly_rate','$hourly_rate','','',7,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl,extra_select, extra_where, sort_order, visible_for) values (
12009,120,NULL,'bank_account','$bank_account','','',9,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl,extra_select, extra_where, sort_order, visible_for) values (
12011,120,NULL,'bank','$bank','','',11,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl,extra_select, extra_where, sort_order, visible_for) values (
12013,120,NULL,'payment_method','$payment_method','','',11,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl,extra_select, extra_where, sort_order, visible_for) values (
12015,120,NULL,'note','[ns_urlencode $note]','','',11,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl,extra_select, extra_where, sort_order, visible_for) values (
12017,120,NULL,'private_note','[ns_urlencode $private_note]','','',11,'');



---------------------------------------------------------
-- Backup Freelance Skills
--

delete from im_view_columns where view_id = 121;
delete from im_views where view_id = 121;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (
	121, 'im_freelance_skills', 1410, 110, '
select
	s.*,
	im_email_from_user_id(s.user_id) as user_email,
	im_category_from_id(s.skill_id) as skill,
	im_category_from_id(s.skill_type_id) as skill_type,
	im_category_from_id(s.claimed_experience_id) as claimed_experience,
	im_category_from_id(s.confirmed_experience_id) as confirmed_experience,
	im_email_from_user_id(s.confirmation_user_id) as confirmation_user_email
from
	im_freelance_skills s
');

delete from im_view_columns where column_id > 12104 and column_id < 12199;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (12101,121,NULL,'user_email','$user_email','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (12103,121,NULL,'skill','$skill','','',3,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (12105,121,NULL,'skill_type','$skill_type','','',5,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (12107,121,NULL,'claimed_experience','$claimed_experience','','',7,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (12109,121,NULL,'confirmed_experience','$confirmed_experience','','',9,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (12111,121,NULL,'confirmation_user_email','$confirmation_user_email','','',11,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (12113,121,NULL,'confirmation_date','$confirmation_date','','',11,'');



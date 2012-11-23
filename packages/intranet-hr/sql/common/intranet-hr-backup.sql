-- /packages/intranet-hr/sql/oracle/intranet-hr-backup.sql
--
-- Copyright (C) 2004 - 2009 ]project-open[
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


---------------------------------------------------------
-- Backup Employees
--

delete from im_view_columns where view_id = 107;
delete from im_views where view_id = 107;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (107, 'im_employees', 1410, 120, '
SELECT
	e.*,
	cc.cost_center_label as department_label,
	im_email_from_user_id(e.employee_id) as employee_email,
	im_email_from_user_id(e.supervisor_id) as supervisor_email,
	im_category_from_id(e.employee_status_id) as employee_status,
	im_email_from_user_id(e.referred_by) as referred_by_email,
	im_category_from_id(e.experience_id) as experience,
	im_category_from_id(e.source_id) as source,
	im_category_from_id(e.original_job_id) as original_job,
	im_category_from_id(e.current_job_id) as current_job,
	im_category_from_id(e.qualification_id) as qualification
FROM
	im_employees e,
	im_cost_centers cc
WHERE
	e.department_id = cc.cost_center_id
');

delete from im_view_columns where column_id > 10700 and column_id < 10799;
--
insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10701,107,NULL,'employee_email','$employee_email','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10703,107,NULL,'department_label','$department_label','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10705,107,NULL,'job_title','[ns_urlencode $job_title]','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10707,107,NULL,'job_description','[ns_urlencode $job_description]','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10709,107,NULL,'availability','$availability','','',9,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10711,107,NULL,'supervisor_email','$supervisor_email','','',11,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10713,107,NULL,'ss_number','$ss_number','','',13,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10714,107,NULL,'salary','$salary','','',14,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10717,107,NULL,'social_security','$social_security','','',17,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10719,107,NULL,'insurance','$insurance','','',19,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10721,107,NULL,'other_costs','$other_costs','','',21,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10723,107,NULL,'currency','$currency','','',23,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10725,107,NULL,'salary_period','$salary_period','','',25,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10727,107,NULL,'salary_payments_per_year','$salary_payments_per_year',
'','',27,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10729,107,NULL,'dependant_p','$dependant_p','','',29,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10731,107,NULL,'only_job_p','$only_job_p','','',31,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10733,107,NULL,'married_p','$married_p','','',33,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10735,107,NULL,'dependants','$dependants','','',35,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10737,107,NULL,'head_of_household_p','$head_of_household_p',
'','',37,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10739,107,NULL,'birthdate','$birthdate','','',39,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10741,107,NULL,'skills','[ns_urlencode $skills]','','',41,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10743,107,NULL,'first_experience',
'$first_experience','','',43,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10745,107,NULL,'years_experience',
'$years_experience','','',45,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10747,107,NULL,'educational_history',
'[ns_urlencode $educational_history]','','',47,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10749,107,NULL,'last_degree_completed','$last_degree_completed',
'','',49,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10751,107,NULL,'employee_status','$employee_status','','',51,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10753,107,NULL,'termination_reason',
'[ns_urlencode $termination_reason]','','',53,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10755,107,NULL,'voluntary_termination_p',
'$voluntary_termination_p','','',55,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10757,107,NULL,'signed_nda_p','$signed_nda_p','','',57,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10759,107,NULL,'referred_by_email',
'$referred_by_email','','',59,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10761,107,NULL,'experience','$experience','','',61,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10763,107,NULL,'source','$source','','',63,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10765,107,NULL,'original_job','$original_job','','',65,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10767,107,NULL,'current_job','$current_job','','',67,'');

insert into im_view_columns (column_id, view_id, group_id, column_name,
column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (10769,107,NULL,'qualification','$qualification','','',69,'');
--
commit;


-- /packages/intranet-ganttproject/sql/postgresql/add_gp_debug_task_columns.sql
--
-- Copyright (c) 2010 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- Add a number of columns with into the TaskListPage 
-- for debugging MS-Project imports


-- -------------------------------------------------------------------
-- Timesheet TaskList
-- -------------------------------------------------------------------

--
-- Wide View in "Tasks" page, including Description
--
-- delete from im_view_columns where view_id = 910;
-- delete from im_views where view_id = 910;
--
-- insert into im_views (view_id, view_name, visible_for) values (910, 'im_timesheet_task_list', 'view_projects');
--
-- 91002	Task Name
-- 91004	Material
-- ...
-- 91022	<Checkbox>
-- 91030	XML start




delete from im_view_columns where column_id >= 91030 and column_id <= 91099;

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order, visible_for) 
values (91029, 910, 'XML<br>UID', '$xml_uid', 129, '');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order, visible_for) 
values (91030, 910, 'XML<br>Duration', '$xml_duration', 130, '');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order, visible_for) 
values (91031, 910, 'XML<br>Remaining<br>Duration', '$xml_remainingduration', 131, '');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order, visible_for) 
values (91032, 910, 'XML<br>IsNull', '$xml_isnull', 132, '');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order, visible_for) 
values (91033, 910, 'XML<br>WBS', '$xml_wbs', 133, '');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order, visible_for) 
values (91034, 910, 'XML<br>OutlineNumber', '$xml_outlinenumber', 134, '');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order, visible_for) 
values (91035, 910, 'XML<br>Work', '$xml_work', 135, '');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order, visible_for) 
values (91036, 910, 'XML<br>Complete', '$xml_percentcomplete', 136, '');

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order, visible_for) 
values (91050, 910, 'XML<br>Critical', '$xml_critical', 150, '');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order, visible_for) 
values (91051, 910, 'XML<br>Priority', '$xml_priority', 151, '');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order, visible_for) 
values (91052, 910, 'XML<br>Effort<br>driven', '$xml_effortdriven', 152, '');


insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order, visible_for) 
values (91070, 910, 'Sort<br>Order', '$sort_order', 170, '');


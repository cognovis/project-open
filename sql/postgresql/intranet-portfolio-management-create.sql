-- /packages/intranet-portfolio-management/sql/postgresql/intranet-portfolio-management-create.sql
--
-- Copyright (c) 2003-2010 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com



-- -------------------------------------------------------------------
-- Dynamic View
-- -------------------------------------------------------------------

--
-- Wide View in "Tasks" page, including Description
--
delete from im_view_columns where view_id = 920;
delete from im_views where view_id = 920;
--
insert into im_views (view_id, view_name, visible_for) values (920, 'portfolio_department_planner_list', 'view_projects');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (92010,920,NULL,'Project',
'"<nobr>$indent_html$gif_html<a href=[export_vars -base $project_base_url]>$project_name</a></nobr>"','','',10,'');


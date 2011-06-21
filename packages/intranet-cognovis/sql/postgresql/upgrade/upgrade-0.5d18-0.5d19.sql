-- 
-- packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d18-0.5d19.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2011-06-17
-- @cvs-id $Id$
--

drop view acs_log_id_seq;
create view acs_log_id_seq as
select nextval('t_acs_log_id_seq') as nextval from dual;

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d18-0.5d19.sql','') from dual;

-- Update the view to correctly display the project and task
update im_view_columns set column_render_tcl = '"<nobr>$indent_html$gif_html<a href=/intranet-cognovis/tasks/view?[export_url_vars project_id task_id return_url]>$task_name</a></nobr>"' where column_id = 1007;

-- Update to correctly view the tasks with the new status
update im_component_plugins set component_tcl = 'im_timesheet_task_list_component -restrict_to_project_id $project_id -view_name im_timesheet_task_list_short -restrict_to_status_id 9600 -restrict_to_project_status_ids [list 71 76]' where plugin_name = 'Project Timesheet Tasks';


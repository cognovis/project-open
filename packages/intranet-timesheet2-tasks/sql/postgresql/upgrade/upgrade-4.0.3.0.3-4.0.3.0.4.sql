-- 
-- packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-4.0.3.0.3-4.0.3.0.4.sql
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
-- @creation-date 2012-03-02
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-4.0.3.0.3-4.0.3.0.4.sql','');

-- translate task types

update im_timesheet_tasks set task_type_id = 9500 where task_type_id = 100 or task_type_id is null;

update im_dynfield_widgets set widget = 'im_category_tree' where widget_name = 'task_status' or widget_name = 'task_type';

-- Update Notes for tasks
alter table im_projects alter column note type text;

-- Make sure we can upgrade existing notes for tasks to use richtext
update im_projects set note = '{' || note || '} text/html' where project_id in (select task_id from im_timesheet_tasks) and note not like '%text/html';

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'task_assignees', 'Task Assignees', 'Task Assignees',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {		select	object_id_two as user_id,
			im_name_from_id(object_id_two) as user_name
		from	acs_rels r,
			im_biz_object_members bom
		where	r.rel_id = bom.rel_id and
			object_id_one = $super_project_id
	} global_var super_project_id}}'
);

SELECT im_dynfield_attribute_new ('im_timesheet_task', 'task_assignee_id', 'Assignee', 'task_assignees', 'integer', 'f');

update im_dynfield_type_attribute_map set default_value = 'tcl {ad_conn user_id}' where attribute_id = (select da.attribute_id from im_dynfield_attributes da, acs_attributes aa where da.acs_attribute_id = aa.attribute_id and aa.attribute_name = 'task_assignee_id');
>>>>>>> c836a4039891ee297ad706ec6da37bf3137574d8

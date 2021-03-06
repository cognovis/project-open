-- 
-- packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-4.0.1.0.1-4.0.1.0.2.sql
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
-- @creation-date 2011-08-18
--

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-4.0.1.0.1-4.0.1.0.2.sql','');

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

alter table im_timesheet_tasks add column task_assignee_id integer references users(user_id);
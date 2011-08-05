-- 
-- packages/intranet-cognovis/sql/postgresql/notifications-create.sql
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
-- @creation-date 2011-08-04
--

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/notifications-create.sql','');

create function inline_0() 
returns integer as '
declare
	impl_id integer;
	v_notif_type_id  integer;
begin
	-- the notification type impl
	impl_id := acs_sc_impl__new (
		      ''NotificationType'',
		      ''project_notif_type'',
		      ''jobs''
	);

	PERFORM acs_sc_impl_alias__new (
		    ''NotificationType'',
		    ''project_notif_type'',
		    ''GetURL'',
		    ''intranet_cognovis::notification::project_get_url'',
		    ''TCL''
	);

	PERFORM acs_sc_impl_alias__new (
		    ''NotificationType'',
		    ''project_notif_type'',
		    ''ProcessReply'',
		    ''intranet-cognovis::notification::project_process_reply'',
		    ''TCL''
	);

	PERFORM acs_sc_binding__new (
		    ''NotificationType'',
		    ''project_notif_type''
	);

	v_notif_type_id:= notification_type__new (
	    NULL,
		impl_id,
		''project_notif'',
		''Task Created'',
		''Notifications for a new task'',
		now(),
		NULL,
		NULL,
	NULL
	);

	-- enable the various intervals and delivery methods
	insert into notification_types_intervals (type_id, interval_id)
	select v_notif_type_id, interval_id
	from notification_intervals where name in (''instant'',''hourly'',''daily'');

	insert into notification_types_del_methods (type_id, delivery_method_id)
	select v_notif_type_id, delivery_method_id
	from notification_delivery_methods where short_name in (''email'');

	return (0);
end;' language 'plpgsql';
select inline_0();
drop function inline_0();

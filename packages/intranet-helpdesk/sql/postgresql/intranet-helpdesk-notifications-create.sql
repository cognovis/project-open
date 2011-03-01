-- /packages/intranet-helpdesk/sql/postgresql/intranet-helpdesk-notifications-create.sql
--
-- Copyright (c) 2003-2008 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


create function inline_0() 
returns integer as '
declare
	impl_id integer;
	v_notif_type_id  integer;
begin
	-- the notification type impl
	impl_id := acs_sc_impl__new (
		      ''NotificationType'',
		      ''ticket_notif_type'',
		      ''jobs''
	);

	PERFORM acs_sc_impl_alias__new (
		    ''NotificationType'',
		    ''ticket_notif_type'',
		    ''GetURL'',
		    ''im_ticket::notification::get_url'',
		    ''TCL''
	);

	PERFORM acs_sc_impl_alias__new (
		    ''NotificationType'',
		    ''ticket_notif_type'',
		    ''ProcessReply'',
		    ''im_ticket::notification::process_reply'',
		    ''TCL''
	);

	PERFORM acs_sc_binding__new (
		    ''NotificationType'',
		    ''ticket_notif_type''
	);

	v_notif_type_id:= notification_type__new (
	    NULL,
		impl_id,
		''ticket_notif'',
		''Ticket Changes'',
		''Notifications of any change to a given ticket'',
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

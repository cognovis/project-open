-- Calendar integration with Notifications

create function inline_0() returns integer as '
declare
        impl_id integer;
        v_notification_id   integer;
begin
        -- the notification type impl
        impl_id := acs_sc_impl__new (
                      ''NotificationType'',
                      ''calendar_notif_type'',
                      ''calendars''
        );

        v_notification_id := acs_sc_impl_alias__new (
                    ''NotificationType'',
                    ''calendar_notif_type'',
                    ''GetURL'',
                    ''calendar::notification::get_url'',
                    ''TCL''
        );

        v_notification_id := acs_sc_impl_alias__new (
                    ''NotificationType'',
                    ''calendar_notif_type'',
                    ''ProcessReply'',
                    ''calendar::notification::process_reply'',
                    ''TCL''
        );

        PERFORM acs_sc_binding__new (
                    ''NotificationType'',
                    ''calendar_notif_type''
        );

        v_notification_id:= notification_type__new (
	        NULL,
                impl_id,
                ''calendar_notif'',
                ''Calendar Notification'',
                ''Notifications for Entire Calendar Package'',
		now(),
                NULL,
                NULL,
		NULL
        );

        -- enable the various intervals and delivery methods
        insert into notification_types_intervals
        (type_id, interval_id)
        select v_notification_id, interval_id
        from notification_intervals where name in (''instant'',''hourly'',''daily'');

        insert into notification_types_del_methods
        (type_id, delivery_method_id)
        select v_notification_id, delivery_method_id
        from notification_delivery_methods where short_name in (''email'');

	return (0);
end;
' language 'plpgsql';

select inline_0();
drop function inline_0();
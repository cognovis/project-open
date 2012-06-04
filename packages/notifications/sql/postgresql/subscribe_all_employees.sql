-- subscribe_all_employees.sql 

create or replace function inline_0()
returns varchar as '
DECLARE
        row          RECORD;
BEGIN
        FOR row IN
                select  u.user_id
                from    acs_rels r,
                        users_active u
                where   r.object_id_two = u.user_id
                        and object_id_one = 463
                        and u.user_id not in (
                                select  user_id
                                from    notification_requests
                                where   object_id = 18518
                                        and type_id = 576034
                        )
        LOOP
                RAISE NOTICE ''new notif for %'', row.user_id;

                PERFORM notification_request__new (
                        null,
                        ''notification_request'',
                        576034,
                        row.user_id,
                        18518,
                        78033,
                        78049,
                        ''text'',
                        ''f'',
                        now(),
                        624,
                        ''0.0.0.0'',
                        null
                );

        END LOOP;
        return 0;
END;' language 'plpgsql';
select inline_0();
drop function inline_0();


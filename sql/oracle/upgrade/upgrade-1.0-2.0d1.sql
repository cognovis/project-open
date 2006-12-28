-- Create the cal_item object
--
-- @author Gary Jin (gjin@arsdigita.com)
-- @creation-date Nov 17, 2000
-- @cvs-id $Id$
--

create or replace package cal_item
as
        function new (
                cal_item_id             in cal_items.cal_item_id%TYPE           default null,
                on_which_calendar       in calendars.calendar_id%TYPE           ,
                name                    in acs_activities.name%TYPE             default null,
                description             in acs_activities.description%TYPE      default null,
                html_p                  in acs_activities.html_p%TYPE           default 'f',
                status_summary          in acs_activities.status_summary%TYPE   default null,
                timespan_id             in acs_events.timespan_id%TYPE          default null,
                activity_id             in acs_events.activity_id%TYPE          default null,  
                recurrence_id           in acs_events.recurrence_id%TYPE        default null,
                item_type_id            in cal_items.item_type_id%TYPE default null,
                object_type             in acs_objects.object_type%TYPE         default 'cal_item',
                context_id              in acs_objects.context_id%TYPE          default null,
                creation_date           in acs_objects.creation_date%TYPE       default sysdate,
                creation_user           in acs_objects.creation_user%TYPE       default null,
                creation_ip             in acs_objects.creation_ip%TYPE         default null                                 
        ) return cal_items.cal_item_id%TYPE;
 
          -- delete cal_item
        procedure del (
                cal_item_id             in cal_items.cal_item_id%TYPE
        );

        procedure delete_all (
                recurrence_id           in acs_events.recurrence_id%TYPE
        );
        
          -- functions to return the name of the cal_item
        function name (
                cal_item_id             in cal_items.cal_item_id%TYPE   
        ) return acs_activities.name%TYPE;

          -- functions to return the calendar that owns the cal_item
        function on_which_calendar (
                cal_item_id             in cal_items.cal_item_id%TYPE   
        ) return calendars.calendar_id%TYPE;

end cal_item;
/
show errors;


                                                        
create or replace package body cal_item
as
        function new (
                cal_item_id             in cal_items.cal_item_id%TYPE           default null,
                on_which_calendar       in calendars.calendar_id%TYPE           ,
                name                    in acs_activities.name%TYPE             default null,
                description             in acs_activities.description%TYPE      default null,
                html_p                  in acs_activities.html_p%TYPE           default 'f',
                status_summary          in acs_activities.status_summary%TYPE   default null,
                timespan_id             in acs_events.timespan_id%TYPE          default null,
                activity_id             in acs_events.activity_id%TYPE          default null,  
                recurrence_id           in acs_events.recurrence_id%TYPE        default null,
                item_type_id            in cal_items.item_type_id%TYPE default null,
                object_type             in acs_objects.object_type%TYPE         default 'cal_item',
                context_id              in acs_objects.context_id%TYPE          default null,
                creation_date           in acs_objects.creation_date%TYPE       default sysdate,
                creation_user           in acs_objects.creation_user%TYPE       default null,
                creation_ip             in acs_objects.creation_ip%TYPE         default null                                 
        ) return cal_items.cal_item_id%TYPE

        is
                v_cal_item_id           cal_items.cal_item_id%TYPE;
                v_grantee_id            acs_permissions.grantee_id%TYPE;
                v_privilege             acs_permissions.privilege%TYPE;

        begin
                v_cal_item_id := acs_event.new (
                        event_id        =>      cal_item_id,
                        name            =>      name,
                        description     =>      description,
                        html_p          =>      html_p,
                        status_summary  =>      status_summary,
                        timespan_id     =>      timespan_id,
                        activity_id     =>      activity_id,
                        recurrence_id   =>      recurrence_id,
                        object_type     =>      object_type,
                        creation_date   =>      creation_date,
                        creation_user   =>      creation_user,
                        creation_ip     =>      creation_ip,
                        context_id      =>      context_id
                );

                insert into     cal_items
                                (cal_item_id, on_which_calendar, item_type_id)
                values          (v_cal_item_id, on_which_calendar, item_type_id);

                  -- assign the default permission to the cal_item
                  -- by default, cal_item are going to inherit the 
                  -- calendar permission that it belongs too. 
                
                  -- first find out the permissions. 
                --select          grantee_id into v_grantee_id
                --from            acs_permissions
                --where           object_id = cal_item.new.on_which_calendar;                     

                --select          privilege into v_privilege
                --from            acs_permissions
                --where           object_id = cal_item.new.on_which_calendar;                     

                  -- now we grant the permissions       
                --acs_permission.grant_permission (       
                 --       object_id       =>      v_cal_item_id,
                  --      grantee_id      =>      v_grantee_id,
                   --     privilege       =>      v_privilege

                --);

                return v_cal_item_id;
        
        end new;
 
        procedure del (
                cal_item_id             in cal_items.cal_item_id%TYPE
        )
        is

        begin
                  -- Erase the cal_item assoicated with the id
                delete from     cal_items
                where           cal_item_id = cal_item.del.cal_item_id;
                
                  -- Erase all the privileges
                delete from     acs_permissions
                where           object_id = cal_item.del.cal_item_id;

                acs_event.del(cal_item_id);
        end del;
                  
        procedure delete_all (
                recurrence_id           in acs_events.recurrence_id%TYPE
        ) is
          v_event_id            acs_events%ROWTYPE;
        begin
                FOR v_event_id in 
                    (select * from acs_events 
                    where recurrence_id = delete_all.recurrence_id)
                LOOP
                        cal_item.del(v_event_id.event_id);
                end LOOP;

                recurrence.del(recurrence_id);
        end delete_all;
                
          -- functions to return the name of the cal_item
        function name (
                cal_item_id             in cal_items.cal_item_id%TYPE   
        ) 
        return acs_activities.name%TYPE

        is
                v_name                  acs_activities.name%TYPE;
        begin
                select  name 
                into    v_name
                from    acs_activities
                where   activity_id = 
                        (
                        select  activity_id
                        from    acs_events
                        where   event_id = cal_item.name.cal_item_id
                        );
                
                return v_name;
        end name;
                 

          -- functions to return the calendar that owns the cal_item
        function on_which_calendar (
                cal_item_id             in cal_items.cal_item_id%TYPE   
        ) 
        return calendars.calendar_id%TYPE

        is
                v_calendar_id           calendars.calendar_id%TYPE;
        begin
                select  on_which_calendar
                into    v_calendar_id
                from    cal_items
                where   cal_item_id = cal_item.on_which_calendar.cal_item_id;
        
                return  v_calendar_id;
        end on_which_calendar;

end cal_item;
/
show errors;


-------------------------------------------------------------
-- create package calendar
-------------------------------------------------------------
 
create or replace package calendar
as
        function new (
                calendar_id             in acs_objects.object_id%TYPE           default null,
                calendar_name           in calendars.calendar_name%TYPE         default null,
                object_type             in acs_objects.object_type%TYPE         default 'calendar',
                owner_id                in calendars.owner_id%TYPE              ,
                private_p               in calendars.private_p%TYPE             default 'f',
                package_id              in calendars.package_id%TYPE            default null,           
                context_id              in acs_objects.context_id%TYPE          default null,
                creation_date           in acs_objects.creation_date%TYPE       default sysdate,
                creation_user           in acs_objects.creation_user%TYPE       default null,
                creation_ip             in acs_objects.creation_ip%TYPE         default null

        ) return calendars.calendar_id%TYPE;
 
        procedure del (
                calendar_id             in calendars.calendar_id%TYPE
        );

          -- figures out the name of the calendar       
        function name (
                calendar_id             in calendars.calendar_id%TYPE
        ) return calendars.calendar_name%TYPE;

          -- returns 't' if calendar is private and 'f' if its not
        function private_p (
                calendar_id             in calendars.calendar_id%TYPE
        ) return char;


          -- returns 't' if calendar is viewable by the given party
          -- this implies that the party has calendar_read permission
          -- on this calendar
        function readable_p (
                calendar_id             in calendars.calendar_id%TYPE,
                party_id                in parties.party_id%TYPE
        ) return char;

          -- returns 't' if party wants to be able to select 
          -- this calendar, and return 'f' otherwise. 
        function show_p (
                calendar_id             in calendars.calendar_id%TYPE,
                party_id                in parties.party_id%TYPE
        ) return char;
                

          ----------------------------------------------------------------
          -- Helper functions for calendar generations:
          --
          -- These functions are used for assist in calendar 
          -- generation. Putting them in the PL/SQL level ensures that
          -- the date date will be the same, and allowing adoptation 
          -- to a different language much easier and faster.
          --             
          -- current month name
        function month_name (
                current_date    date
        ) return char;
          
          -- next month
        function next_month (
                current_date    date
        ) return date;
          
          -- prev month
        function prev_month (
                current_date    date
        ) return date;

          -- number of days in the month
        function num_day_in_month (
                current_date    date
        ) return integer;

          -- first day to be displayed in a month. 
        function first_displayed_date (
                current_date    date
        ) return date;

          -- last day to be displayed in a month. 
        function last_displayed_date (
                current_date    date
        ) return date;          
          
end calendar;
/
show errors;
 
 
create or replace package body calendar
as 

        function new (
                calendar_id             in acs_objects.object_id%TYPE           default null,
                calendar_name           in calendars.calendar_name%TYPE         default null,
                object_type             in acs_objects.object_type%TYPE         default 'calendar',
                owner_id                in calendars.owner_id%TYPE              , 
                private_p               in calendars.private_p%TYPE             default 'f',
                package_id              in calendars.package_id%TYPE            default null,
                context_id              in acs_objects.context_id%TYPE          default null,
                creation_date           in acs_objects.creation_date%TYPE       default sysdate,
                creation_user           in acs_objects.creation_user%TYPE       default null,
                creation_ip             in acs_objects.creation_ip%TYPE         default null

        ) 
        return calendars.calendar_id%TYPE
   
        is
                v_calendar_id           calendars.calendar_id%TYPE;

        begin
                v_calendar_id := acs_object.new (
                        object_id       =>      calendar_id,
                        object_type     =>      object_type,
                        creation_date   =>      creation_date,
                        creation_user   =>      creation_user,
                        creation_ip     =>      creation_ip,
                        context_id      =>      context_id
                );
        
                insert into     calendars
                                (calendar_id, calendar_name, owner_id, package_id, private_p)
                values          (v_calendar_id, calendar_name, owner_id, package_id, private_p);


                  -- each calendar has three default conditions
                  -- 1. all items are public
                  -- 2. all items are private
                  -- 3. no default conditions
                  -- 
                  -- calendar being public implies granting permission
                  -- calendar_read to the group 'the_public' and 'registered users'
                  --         
                  -- calendar being private implies granting permission 
                  -- calendar_read to the owner party/group of the party
                  --
                  -- by default, we grant "calendar_admin" to
                  -- the owner of the calendar
                acs_permission.grant_permission (
                        object_id       =>      v_calendar_id,
                        grantee_id      =>      owner_id,
                        privilege       =>      'calendar_admin'
                );
                
 
                return v_calendar_id;
        end new;
 


          -- body for procedure delete
        procedure del (
                calendar_id             in calendars.calendar_id%TYPE
        )
        is
  
        begin
                  -- First erase all the item relate to this calendar.
                delete from     calendars 
                where           calendar_id = calendar.del.calendar_id;
 
                  -- Delete all privileges associate with this calendar
                delete from     acs_permissions 
                where           object_id = calendar.del.calendar_id;

                  -- Delete all privilges of the cal_items that's associated 
                  -- with this calendar
                delete from     acs_permissions
                where           object_id in (
                                        select  cal_item_id
                                        from    cal_items
                                        where   on_which_calendar = calendar.del.calendar_id                                                                                                                                                         
                                );
                        
 
                acs_object.del(calendar_id);
        end del;
 


          -- figures out the name of the calendar       
        function name (
                calendar_id             in calendars.calendar_id%TYPE
        ) 
        return calendars.calendar_name%TYPE

        is
                v_calendar_name         calendars.calendar_name%TYPE;
        begin
                select  calendar_name
                into    v_calendar_name
                from    calendars
                where   calendar_id = calendar.name.calendar_id;

                return v_calendar_name;
        end name;



          -- returns 't' if calendar is private and 'f' if its not
        function private_p (
                calendar_id             in calendars.calendar_id%TYPE
        ) 
        return char

        is
                v_private_p             char(1) := 't';
        begin
                select  private_p 
                into    v_private_p
                from    calendars
                where   calendar_id = calendar.private_p.calendar_id;

                return v_private_p;
        end private_p;



          -- returns 't' if calendar is viewable by the given party
          -- this implies that the party has calendar_read permission
          -- on this calendar
        function readable_p (
                calendar_id             in calendars.calendar_id%TYPE,
                party_id                in parties.party_id%TYPE
        ) 
        return char

        is      
                v_readable_p            char(1) := 't';
        begin
                select  decode(count(*), 1, 't', 'f') 
                into    v_readable_p
                from    acs_object_party_privilege_map 
                where   party_id = calendar.readable_p.party_id
                and     object_id = calendar.readable_p.calendar_id 
                and     privilege = 'calendar_read';

                return  v_readable_p;

        end readable_p;

          -- returns 't' if party wants to be able to select (calendar_show granted)
          -- this calendar, and .return 'f' otherwise. 
          --
          -- this seems to be a problem with the problem that when
          -- revoking the permissions using acs_permissions.revoke
          -- data is not removed from table acs_object_party_privilege_map.
        function show_p (
                calendar_id             in calendars.calendar_id%TYPE,
                party_id                in parties.party_id%TYPE
        ) 
        return char

        is
                v_show_p                char(1) := 't';
        begin
                select  decode(count(*), 1, 't', 'f') 
                into    v_show_p
                from    acs_permissions
                where   grantee_id = calendar.show_p.party_id
                and     object_id = calendar.show_p.calendar_id 
                and     privilege = 'calendar_show';

                return  v_show_p;

        end show_p;


          -- Helper functions for calendar generations:
          --
          -- These functions are used for assist in calendar 
          -- generation. Putting them in the PL/SQL level ensures that
          -- the date date will be the same, and allowing adoptation 
          -- to a different language much easier and faster.
          --             
          -- current month name
        function month_name (
                current_date            date
        ) return char
          
        is
                name    char;
        begin
                select  to_char(to_date(calendar.month_name.current_date), 'fmMonth') 
                        into name
                from    dual;
                        
                return name;
        end month_name;

        
          -- next month
        function next_month (
                current_date            date
        ) return date

        is
                v_date                  date;
        begin
                select  trunc(add_months(to_date(sysdate), -1))
                        into v_date
                from    dual;

                return v_date;          
        end next_month;
          

          -- prev month
        function prev_month (
                current_date            date
        ) return date
        
        is
                v_date                  date;
        begin
                select  trunc(add_months(to_date(sysdate), -1))
                        into v_date
                from    dual;

                return v_date;
        end prev_month;

          -- number of days in the month
        function num_day_in_month (
                current_date    date
        ) return integer

        is
                v_num   integer;
        begin
                select  to_char(last_day(to_date(sysdate)), 'DD')
                        into v_num
                from    dual;

                return v_num;
        end num_day_in_month;

          -- first day to be displayed in a month. 
        function first_displayed_date (
                current_date    date
        ) return date

        is
                v_date          date;
        begin
                select  next_day(trunc(to_date(sysdate), 'Month') - 7, 'SUNDAY')
                        into v_date
                from    dual;

                return  v_date;
        end first_displayed_date;

          -- last day to be displayed in a month. 
        function last_displayed_date (
                current_date    date
        ) return date

        is
                v_date          date;
        begin
                select  next_day(last_day(to_date(sysdate)), 'SATURDAY')
                        into v_date
                from    dual;

                return v_date;
        end last_displayed_date;
         
end calendar;
/
show errors
 











update acs_objects
set title = (select name
             from acs_events
             where event_id = object_id)
where object_type = 'acs_event';

update acs_objects
set title = (select name
             from acs_activities
             where activity_id = object_id)
where object_type = 'acs_activity';

create or replace package body acs_event
as 
    function new ( 
        event_id        in acs_events.event_id%TYPE default null, 
        name            in acs_events.name%TYPE default null,
        description     in acs_events.description%TYPE default null,
        html_p          in acs_events.html_p%TYPE default null,
        status_summary  in acs_events.status_summary%TYPE default null,
        timespan_id     in acs_events.timespan_id%TYPE default null, 
        activity_id     in acs_events.activity_id%TYPE default null, 
        recurrence_id   in acs_events.recurrence_id%TYPE default null, 
        object_type     in acs_object_types.object_type%TYPE default 'acs_event', 
        creation_date   in acs_objects.creation_date%TYPE default sysdate, 
        creation_user   in acs_objects.creation_user%TYPE default null, 
        creation_ip     in acs_objects.creation_ip%TYPE default null, 
        context_id      in acs_objects.context_id%TYPE default null 
    ) return acs_events.event_id%TYPE
    is
        new_event_id acs_events.event_id%TYPE;
    begin
        new_event_id := acs_object.new(
            object_id => event_id,
            object_type => object_type,
            title => name,
            creation_date => creation_date,
            creation_user => creation_user,
            creation_ip => creation_ip,
            context_id => context_id
        );
                
        insert into acs_events
            (event_id, name, description, html_p, status_summary, activity_id, timespan_id, recurrence_id)
        values
            (new_event_id, name, description, html_p, status_summary, activity_id, timespan_id, recurrence_id);

        return new_event_id;
    end new; 

    procedure del ( 
        event_id in acs_events.event_id%TYPE 
    )
    is
        recurrence_id acs_events.recurrence_id%TYPE;
    begin
        select recurrence_id into recurrence_id
        from   acs_events
        where  event_id = acs_event.del.event_id;

        -- acs_events and acs_event_party_map deleted via on delete cascade
        acs_object.del(event_id); 

        -- Check for no more instances and delete recurrence if exists
        if instances_exist_p(recurrence_id) = 'f' then
            recurrence.del(recurrence_id);
        end if;
    end del;

    procedure delete_all (
        event_id in acs_events.event_id%TYPE
    )
    is
        recurrence_id acs_events.recurrence_id%TYPE;
    begin

        select recurrence_id into recurrence_id
        from   acs_events
        where  event_id = delete_all.event_id;

        delete_all_recurrences(recurrence_id);
    end delete_all;

    procedure delete_all_recurrences (
        recurrence_id   in recurrences.recurrence_id%TYPE default null
    )
    is
        cursor event_id_cursor is
            select event_id
            from   acs_events
            where  recurrence_id = delete_all_recurrences.recurrence_id;
        event_id event_id_cursor%ROWTYPE;
    begin
        if recurrence_id is not null then
            for event_id in event_id_cursor loop
                acs_event.del(event_id.event_id);
            end loop;
        end if;
    end delete_all_recurrences;

    -- Equivalent functionality to get_name and get_description provided by
    -- acs_event_activity view

    function get_name (
        event_id in acs_events.event_id%TYPE 
    ) return acs_events.name%TYPE
    is
        name acs_events.name%TYPE; 
    begin
        select nvl(e.name, a.name) into name
        from   acs_events e, 
               acs_activities a
        where  event_id = get_name.event_id
        and    e.activity_id = a.activity_id(+);

        return name;
    end get_name;

    function get_description (
        event_id    in acs_events.event_id%TYPE 
    ) return acs_events.description%TYPE
    is
        description acs_events.description%TYPE; 
    begin
        select nvl(e.description, a.description) into description
        from   acs_events e, acs_activities a
        where  event_id      = get_description.event_id
        and    e.activity_id = a.activity_id(+);

        return description;
    end get_description;

    function get_html_p (
        event_id    in acs_events.event_id%TYPE 
    ) return acs_events.html_p%TYPE
    is
        html_p acs_events.html_p%TYPE; 
    begin
        select nvl(e.html_p, a.html_p) into html_p
        from  acs_events e, acs_activities a
        where event_id      = get_html_p.event_id
        and   e.activity_id = a.activity_id(+);

        return html_p;
    end get_html_p;

    function get_status_summary (
        event_id    in acs_events.event_id%TYPE 
    ) return acs_events.status_summary%TYPE
    is
        status_summary acs_events.status_summary%TYPE; 
    begin
        select nvl(e.status_summary, a.status_summary) into status_summary
        from  acs_events e, acs_activities a
        where event_id      = get_status_summary.event_id
        and   e.activity_id = a.activity_id(+);

        return status_summary;
    end get_status_summary;

    procedure timespan_set (
        event_id        in acs_events.event_id%TYPE,
        timespan_id     in timespans.timespan_id%TYPE
    )
    is
    begin
        update acs_events
        set    timespan_id = timespan_set.timespan_id
        where  event_id    = timespan_set.event_id;
    end timespan_set;

    procedure recurrence_timespan_edit (
        event_id               in acs_events.event_id%TYPE,
        start_date             in time_intervals.start_date%TYPE,
        end_date               in time_intervals.end_date%TYPE
    )
    is
        v_timespan           timespans%ROWTYPE;
        v_one_start_date     time_intervals.start_date%TYPE;
        v_one_end_date       time_intervals.end_date%TYPE;
    begin
        -- get the initial offsets
        select start_date, end_date into v_one_start_date, v_one_end_date
        from time_intervals, timespans, acs_events
        where time_intervals.interval_id = timespans.interval_id and
        timespans.timespan_id = acs_events.timespan_id and
        event_id= recurrence_timespan_edit.event_id;

        for v_timespan in 
        (select * from time_intervals where interval_id in (select interval_id from timespans where timespan_id in (select timespan_id from acs_events where recurrence_id = (select recurrence_id from acs_events where event_id = recurrence_timespan_edit.event_id))))
        LOOP
                time_interval.edit(v_timespan.interval_id, v_timespan.start_date + (start_date - v_one_start_date), v_timespan.end_date + (end_date - v_one_end_date));
        END LOOP;
    end recurrence_timespan_edit;

    procedure activity_set (
        event_id        in acs_events.event_id%TYPE,
        activity_id     in acs_activities.activity_id%TYPE
    )
    as
    begin
        update acs_events
        set    activity_id = activity_set.activity_id
        where  event_id    = activity_set.event_id;
    end activity_set;

    procedure party_map (
        event_id        in acs_events.event_id%TYPE,
        party_id        in parties.party_id%TYPE
    )
    is
    begin
        insert into acs_event_party_map
            (event_id, party_id)
        values
            (event_id, party_id);
    end party_map;

    procedure party_unmap (
        event_id        in acs_events.event_id%TYPE,
        party_id        in parties.party_id%TYPE
    )
    is
    begin
        delete from acs_event_party_map
        where  event_id = party_unmap.event_id
        and    party_id = party_unmap.party_id;
    end party_unmap;

    function recurs_p (
        event_id        in acs_events.event_id%TYPE
    ) return char
    is
        result char;
    begin
        select decode(recurrence_id, null, 'f', 't') into result
        from   acs_events
        where  event_id = recurs_p.event_id;

        return result;
    end recurs_p;

    function instances_exist_p (
        recurrence_id   in acs_events.recurrence_id%TYPE
    ) return char
    is
        result char;
    begin
        -- Only need to check if any rows exist.
        select count(*) into result
        from   dual 
        where exists (select recurrence_id
                      from   acs_events
                      where  recurrence_id = instances_exist_p.recurrence_id);

        if result = 0 then
            return 'f';
        else
            return 't';
        end if;
    end instances_exist_p;

    -- This function is used internally by insert_instances
    function get_value (
        parameter_name in apm_parameters.parameter_name%TYPE
    ) return apm_parameter_values.attr_value%TYPE
    is
        package_id apm_packages.package_id%TYPE;
    begin
        select package_id into package_id
        from   apm_packages
        where  package_key = 'acs-events';

        return apm.get_value(package_id, parameter_name);
    end get_value;

    -- This function is used internally by insert_instances
    function new_instance (
        event_id    in acs_events.event_id%TYPE,
        date_offset     in integer
    ) return acs_events.event_id%TYPE
    is
        event acs_events%ROWTYPE;
        object acs_objects%ROWTYPE;
        new_event_id acs_events.event_id%TYPE;
        new_timespan_id acs_events.timespan_id%TYPE;
    begin
         select * into event
         from   acs_events
         where  event_id = new_instance.event_id;
                
         select * into object
         from   acs_objects
         where  object_id = event_id;

         new_timespan_id := timespan.copy(event.timespan_id, date_offset);

         new_event_id := new(
            name          => event.name,
            description   => event.description,
            html_p        => event.html_p,
            status_summary => event.status_summary,
            timespan_id   => new_timespan_id,
            activity_id   => event.activity_id,
            recurrence_id => event.recurrence_id,
            creation_user => object.creation_user,
            creation_ip   => object.creation_ip,
            context_id    => object.context_id
        );

        return new_event_id;
    end new_instance;

    procedure insert_instances (
        event_id        in acs_events.event_id%TYPE, 
        cutoff_date             in date default null
    )
    is
        event            acs_events%ROWTYPE;
        recurrence       recurrences%ROWTYPE;
        new_event_id     acs_events.event_id%TYPE;
        interval_name    recurrence_interval_types.interval_name%TYPE;
        n_intervals      recurrence.every_nth_interval%TYPE;
        days_of_week     recurrence.days_of_week%TYPE;
        last_date_done   date;
        stop_date        date;
        start_date       date;
        event_date       date;
        diff             integer;
        current_date     date;
        v_last_day       date;
        week_date        date;
        instance_count   integer;
        days_length      integer;
        days_index       integer;
        day_num          integer;
    begin
        select * into event
        from   acs_events
        where  event_id = insert_instances.event_id;
        
        select * into recurrence
        from   recurrences
        where  recurrence_id = event.recurrence_id;
        
        -- Set cutoff date
        -- EventFutureLimit is in years.
        if cutoff_date is null then
           stop_date := add_months(sysdate, 12 * get_value('EventFutureLimit'));
        else
           stop_date := cutoff_date;
        end if;
        
        -- Events only populated until max(cutoff_date, recur_until)
        -- If recur_until null, then defaults to cutoff_date
        if recurrence.recur_until < stop_date then
           stop_date := recurrence.recur_until;
        end if;
        
        -- Figure out the date to start from
        select trunc(min(start_date))
        into   event_date
        from   acs_events_dates
        where  event_id = insert_instances.event_id;
        
        if recurrence.db_populated_until is null then
           start_date := event_date;
        else
           start_date := recurrence.db_populated_until;
        end if;
        
        current_date   := start_date;
        last_date_done := start_date;
        n_intervals    := recurrence.every_nth_interval;
        
        -- Case off of the interval_name to make code easier to read
        select interval_name into interval_name
        from   recurrences r, 
               recurrence_interval_types t
        where  recurrence_id   = recurrence.recurrence_id
        and    r.interval_type = t.interval_type;
        
        -- Week has to be handled specially.
        -- Start with the beginning of the week containing the start date.

        if interval_name = 'week' then
            current_date := NEXT_DAY(current_date - 7, 'SUNDAY');
            days_of_week := recurrence.days_of_week;
            days_length  := LENGTH(days_of_week);
        end if;
        
        -- Check count to prevent runaway in case of error
        instance_count := 0;
        while instance_count < 10000 and (trunc(last_date_done) <= trunc(stop_date))
        loop
            instance_count := instance_count + 1;
        
            -- Calculate next date based on interval type
            if interval_name = 'day' then
                current_date := current_date + n_intervals;
            elsif interval_name = 'month_by_date' then
                current_date := ADD_MONTHS(current_date, n_intervals);
            elsif interval_name = 'month_by_day' then
             -- Find last day of month before correct month
                v_last_day := ADD_MONTHS(LAST_DAY(current_date), n_intervals - 1);
                -- Find correct week and go to correct day of week
                current_date := NEXT_DAY(v_last_day + (7 * (to_char(current_date, 'W') - 1)), 
                                         to_char(current_date, 'DAY'));
            elsif interval_name = 'last_of_month' then
                -- Find last day of correct month
                v_last_day := LAST_DAY(ADD_MONTHS(current_date, n_intervals));
                -- Back up one week and find correct day of week
                current_date := NEXT_DAY(v_last_day - 7, to_char(current_date, 'DAY'));
            elsif interval_name = 'year' then
                current_date := ADD_MONTHS(current_date, 12 * n_intervals);
                -- Deal with custom function
            elsif interval_name = 'custom' then
                execute immediate 'current_date := ' || 
                              recurrence.custom_func || '(' || current_date || ', ' || n_intervals || ');';
            end if;
        
            -- Check to make sure we're not going past Trunc because dates aren't integral
            exit when trunc(current_date) > trunc(stop_date);
        
            -- Have to handle week specially
            if interval_name = 'week' then
                -- loop over days_of_week extracting each day number
                -- add day number and insert
                days_index := 1;
                week_date  := current_date;
                while days_index <= days_length loop
                    day_num   := SUBSTR(days_of_week, days_index, 1);
                    week_date := current_date + day_num;
                    if trunc(week_date) > trunc(start_date) and trunc(week_date) <= trunc(stop_date) then
                         -- This is where we add the event
                         new_event_id := new_instance(
                              event_id, 
                              trunc(week_date) - trunc(event_date)
                         );
                         last_date_done := week_date;
                     elsif trunc(week_date) > trunc(stop_date) then
                         -- Gone too far
                         exit;
                     end if;
                     days_index := days_index + 2;
                 end loop;

                 -- Now move to next week with repeats.
                current_date := current_date + 7 * n_intervals;
            else
                -- All other interval types
                -- This is where we add the event
                new_event_id := new_instance(
                    event_id, 
                    trunc(current_date) - trunc(event_date)
                );
                last_date_done := current_date;
            end if;
        end loop;
        
        update recurrences
        set    db_populated_until = last_date_done
        where  recurrence_id      = recurrence.recurrence_id;

    end insert_instances;


    procedure shift (
        event_id        in acs_events.event_id%TYPE default null,
        start_offset    in number default 0,
        end_offset      in number default 0
    )
    is
    begin
        update acs_events_dates
        set    start_date = start_date + start_offset,
               end_date   = end_date + end_offset
        where  event_id   = shift.event_id;
    end shift;

    procedure shift_all (
        event_id        in acs_events.event_id%TYPE default null,
        start_offset    in number default 0,
        end_offset      in number default 0
    )
    is
    begin
        update acs_events_dates
        set    start_date    = start_date + start_offset,
               end_date      = end_date + end_offset
        where recurrence_id  = (select recurrence_id
                                from   acs_events
                                where  event_id = shift_all.event_id);
    end shift_all;

    procedure shift_all (
        recurrence_id   in recurrences.recurrence_id%TYPE default null,
        start_offset    in number default 0,
        end_offset      in number default 0
    )
    is
    begin
        update acs_events_dates
        set    start_date   = start_date + start_offset,
               end_date     = end_date + end_offset
        where recurrence_id = shift_all.recurrence_id;
    end shift_all;

end acs_event; 
/ 
show errors


create or replace package body acs_activity
as
    function new ( 
         activity_id         in acs_activities.activity_id%TYPE   default null, 
         name                in acs_activities.name%TYPE,
         description         in acs_activities.description%TYPE   default null,
         html_p              in acs_activities.html_p%TYPE        default 'f',
         status_summary      in acs_activities.status_summary%TYPE  default null,
         object_type         in acs_object_types.object_type%TYPE default 'acs_activity', 
         creation_date       in acs_objects.creation_date%TYPE    default sysdate, 
         creation_user       in acs_objects.creation_user%TYPE    default null, 
         creation_ip         in acs_objects.creation_ip%TYPE      default null, 
         context_id          in acs_objects.context_id%TYPE       default null 
    ) return acs_activities.activity_id%TYPE
    is
        new_activity_id acs_activities.activity_id%TYPE;
    begin
        new_activity_id := acs_object.new(
            object_id     => activity_id,
            object_type   => object_type,
            title         => name,
            creation_date => creation_date,
            creation_user => creation_user,
            creation_ip   => creation_ip,
            context_id    => context_id
        );

        insert into acs_activities
            (activity_id, name, description, html_p, status_summary)
        values
            (new_activity_id, name, description, html_p, status_summary);

        return new_activity_id;
    end new;


    function name (
        -- name method
        -- @author gjin@arsdigita.com
        -- @param activity_id
        --
        activity_id          in acs_activities.activity_id%TYPE
        
    ) return acs_activities.name%TYPE
        
    is
        new_activity_name    acs_activities.name%TYPE;

    begin
        select  name
        into    new_activity_name
        from    acs_activities
        where   activity_id = name.activity_id;

        return  new_activity_name;
    end;

         
    procedure del ( 
         activity_id in acs_activities.activity_id%TYPE 
    )
    is
    begin
         -- Cascade will cause delete from acs_activities 
         -- and acs_activity_object_map

         acs_object.del(activity_id); 
    end del;

    -- NOTE: can't use update

    procedure edit (
         activity_id     in acs_activities.activity_id%TYPE, 
         name            in acs_activities.name%TYPE default null,
         description     in acs_activities.description%TYPE default null,
         html_p          in acs_activities.html_p%TYPE default null,
         status_summary  in acs_activities.status_summary%TYPE default null
    )
    is
    begin
        update acs_activities
        set    name        = nvl(edit.name, name),
               description = nvl(edit.description, description),
               html_p      = nvl(edit.html_p, html_p),
               status_summary = nvl(edit.status_summary, status_summary)
        where activity_id  = edit.activity_id;

        update acs_objects
        set    title = nvl(edit.name, title)
        where object_id = edit.activity_id;
    end edit;

    procedure object_map (
        activity_id in acs_activities.activity_id%TYPE, 
        object_id   in acs_objects.object_id%TYPE
    )
    is
    begin
        insert into acs_activity_object_map
            (activity_id, object_id)
        values
            (activity_id, object_id);
    end object_map;

    procedure object_unmap (
        activity_id in acs_activities.activity_id%TYPE, 
         object_id  in acs_objects.object_id%TYPE
    )
    is
    begin
        delete from acs_activity_object_map
        where  activity_id = object_unmap.activity_id
        and    object_id   = object_unmap.object_id;
    end object_unmap;

end acs_activity;
/
show errors

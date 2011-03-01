-- Upgrade to allow editing only future recurrences
-- 2007-03-30 Dave Bauer (dave@solutiongrove.com)
-- 
-- packages/acs-events/sql/postgresql/upgrade/upgrade-0.6d1-0.6d2.sql
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2007-03-30
-- @cvs-id $Id: upgrade-0.6d1-0.6d2.sql,v 1.2 2007/05/15 20:14:15 donb Exp $
--

create or replace package acs_event
as 
    function new ( 
        -- Creates a new event (20.10.10)
        -- @author W. Scott Meeks
        -- @param event_id          optional id to use for new event
        -- @param name                  optional Name of the new event
        -- @param description   optional Description of the new event
        -- @param html_p        optional Description is html
        -- @param status_summary    optional status information to add to name
        -- @param timespan_id       optional initial time interval set
        -- @param activity_id       optional initial activity
        -- @param recurrence_id     optional id of recurrence information
        -- @param object_type       'acs_event'
        -- @param creation_date     default sysdate
        -- @param creation_user     acs_object param
        -- @param creation_ip       acs_object param
        -- @param context_id        acs_object param
        -- @return The id of the new event.
        --
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
        context_id      in acs_objects.context_id%TYPE default null,
        package_id      in acs_objects.package_id%TYPE default null 
    ) return acs_events.event_id%TYPE; 

    procedure del ( 
        -- Deletes an event (20.10.40)
        -- Also deletes party mappings (via on delete cascade).
        -- If this is the last instance of a recurring event, the recurrence
        -- info is deleted as well
        -- @author W. Scott Meeks
        -- @param event_id id of event to delete
        --
        event_id        in acs_events.event_id%TYPE 
    ); 

    procedure delete_all (
        -- Deletes all instances of an event.  
        -- @author W. Scott Meeks
        -- @param event_id  All events with the same recurrence_id as this one will be deleted.
        --
        event_id in acs_events.event_id%TYPE
    );

    procedure delete_all_recurrences (
        -- Deletes all instances of an event.  
        -- @author W. Scott Meeks
        -- @param recurrence_id All events with this recurrence_id will be deleted.
        --
        recurrence_id in recurrences.recurrence_id%TYPE default null
    );

    function get_name (
        -- Returns the name or the name of the activity associated with the event if 
        -- name is null.
        -- @author W. Scott Meeks
        -- @param event_id                      id of event to get name for
        --
        event_id            in acs_events.event_id%TYPE 
    ) return acs_events.name%TYPE; 

    function get_description (
        -- Returns the description or the description of the activity associated 
        -- with the event if description is null.
        -- @author W. Scott Meeks
        -- @param event_id                      id of event to get description for
        --
        event_id            in acs_events.event_id%TYPE 
    ) return acs_events.description%TYPE; 

    function get_html_p (
        -- Returns html_p or html_p of the activity associated with the event if 
        -- html_p is null.
        -- @author W. Scott Meeks
        -- @param event_id                      id of event to get html_p for
        --
        event_id            in acs_events.event_id%TYPE 
    ) return acs_events.html_p%TYPE; 

    function get_status_summary (
        -- Returns status_summary or status_summary of the activity associated with the event if 
        -- status_summary is null.
        -- @author W. Scott Meeks
        -- @param event_id                      id of event to get status_summary for
        --
        event_id            in acs_events.event_id%TYPE 
    ) return acs_events.status_summary%TYPE; 

    procedure timespan_set (
        -- Sets the time span for an event (20.10.15)
        -- @author W. Scott Meeks
        -- @param event_id                      id of event to update
        -- @param timespan_id   new time interval set
        --
        event_id        in acs_events.event_id%TYPE,
        timespan_id     in timespans.timespan_id%TYPE
    );

    procedure recurrence_timespan_edit (
        event_id               in acs_events.event_id%TYPE,
        start_date             in time_intervals.start_date%TYPE,
        end_date               in time_intervals.end_date%TYPE,
        edit_past_events       in char default 't'
    );

    procedure activity_set (
        -- Sets the activity for an event (20.10.20)
        -- @author W. Scott Meeks
        -- @param event_id                      id of event to update
        -- @param activity_id           new activity
        --
        event_id        in acs_events.event_id%TYPE,
        activity_id     in acs_activities.activity_id%TYPE
    );

    procedure party_map (
        -- Adds a party mapping to an event (20.10.30)
        -- @author W. Scott Meeks
        -- @param event_id event to add mapping to
        -- @param party_id party to add mapping for
        --
        event_id        in acs_events.event_id%TYPE,
        party_id        in parties.party_id%TYPE
    );

    procedure party_unmap (
        -- Deletes a party mapping from an event (20.10.30)
        -- @author W. Scott Meeks
        -- @param event_id                      id of event to delete mapping from
        -- @param party_id                      id of party to delete mapping for
        --
        event_id    in acs_events.event_id%TYPE,
        party_id    in parties.party_id%TYPE
    );

    function recurs_p (
        -- Returns 't' if event recurs, 'f' otherwise (20.50.40)
        -- @author W. Scott Meeks
        -- @param event_id                      id of event to check
        -- @return 't' or 'f'
        --
        event_id    in acs_events.event_id%TYPE
    ) return char;

    function instances_exist_p (
        -- Returns 't' if events with the given recurrence_id exist, 'f' otherwise
        -- @author W. Scott Meeks
        -- @param recurrence_id                 id of recurrence to check
        -- @return 't' or 'f'
        --
        recurrence_id   in acs_events.recurrence_id%TYPE
    ) return char;

    procedure insert_instances (
        -- This is the key procedure creating recurring events.  This procedure
        -- uses the interval set and recurrence information referenced by the event
        -- to insert additional information to represent the recurrences.   
        -- Events will be added up until the earlier of recur_until and
        -- cutoff_date.  The procedure enforces a hard internal 
        -- limit of adding no more than 10,000 recurrences at once to reduce the 
        -- risk of demolishing the DB because of application bugs.  The date of the
        -- last recurrence added is marked as the db_populated_until date.
        --
        -- The application is responsible for calling this function again if 
        -- necessary to populate to a later date.  
        --
        -- @author W. Scott Meeks
        -- @param event_id              The id of the event to recur.  If the 
        --                              event's recurrence_id is null, nothing happens.
        -- @param cutoff_date           optional If provided, determines how far out to
        --                              prepopulate the DB.  If not provided, then 
        --                              defaults to sysdate plus the value of the
        --                              EventFutureLimit site parameter.
        event_id        in acs_events.event_id%TYPE, 
        cutoff_date     in date default null
  );

  procedure shift (
        -- Shifts the timespan of an event by the given offsets.
        -- @author W. Scott Meeks
        -- @param event_id              Event to shift.
        -- @param start_offset  optional If provided, adds this number to the
        --                                              start_dates of the timespan of the event.
        --                                              No effect on any null start_date.
        -- @param end_offset    optional If provided, adds this number to the
        --                                              end_dates of the timespan of the event.
        --                                              No effect on any null end_date.
        --
        event_id        in acs_events.event_id%TYPE default null,
        start_offset    in number default 0,
        end_offset      in number default 0
  );

  procedure shift_all (
        -- Shifts the timespan of all instances of a recurring event
        -- by the given offsets.
        -- @author W. Scott Meeks
        -- @param event_id      All events with the same
        --                          recurrence_id as this one will be shifted.
        -- @param start_offset  optional If provided, adds this number to the
        --                          start_dates of the timespan of the event
        --                          instances.  No effect on any null start_date.
        -- @param end_offset    optional If provided, adds this number to the
        --                          end_dates of the timespan of the event
        --                          instances.  No effect on any null end_date.
        --
        event_id        in acs_events.event_id%TYPE default null,
        start_offset    in number default 0,
        end_offset      in number default 0
  );

  procedure shift_all (
        -- Same as above but invoked using recurrence Id
        recurrence_id   in recurrences.recurrence_id%TYPE default null,
        start_offset    in number default 0,
        end_offset      in number default 0
  );

end acs_event; 
/ 
show errors

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
        context_id      in acs_objects.context_id%TYPE default null,
        package_id      in acs_objects.package_id%TYPE default null 
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
            context_id => context_id,
            package_id => package_id
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
        end_date               in time_intervals.end_date%TYPE,
        edit_past_events       in char default 't'
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
        (select * from time_intervals where interval_id in (select interval_id from timespans where timespan_id in (select timespan_id from acs_events where recurrence_id = (select recurrence_id from acs_events where event_id = recurrence_timespan_edit.event_id)))
        and (edit_past_events = 't' or start_date >= to_date(v_one_start_date,'YYYY-MM-DD HH24:MI:SS') ))
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
            context_id    => object.context_id,
            package_id    => object.package_id
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


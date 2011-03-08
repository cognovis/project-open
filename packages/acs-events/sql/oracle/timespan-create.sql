-- packages/acs-events/sql/timespan-create.sql
--
-- This script defines the data models for both time_interval and timespan.
--
-- API:
--
--       new        (start_date, end_date)
--       del     ()
--
--       edit       (start_date, end_date)
--
--       shift      (start_offset, end_offset)
--
--       overlaps_p (interval_id) 
--       overlaps_p (start_date, end_date)
--
-- $Id: timespan-create.sql,v 1.3 2003/09/30 12:10:02 mohanp Exp $

-- Table for storing time intervals.  Note that time intervals can be open on 
-- either end.  This is represented by a null value for start_date or end_date.
-- Applications can determine how to interpret null values.  However, this is 
-- the default interpretation used by the overlaps_p functions. A null value
-- for start_date is treated as extending to the beginning of time.  A null
-- value for end_date is treated as extending to the end of time.  The net effect
-- is that an interval with an open start overlaps any interval whose start
-- is before the end of the interval with the open start.  Likewise, an interval
-- with an open end overlaps any interval whose end is after the start of the
-- interval with the open end.

-- Sequence for timespan tables 
create sequence timespan_seq start with 1;

create table time_intervals (
    interval_id         integer
                        constraint time_intervals_pk
                        primary key,
    start_date          date,
    end_date            date,
    constraint time_interval_date_order_ck
    check(start_date <= end_date)
);

create index time_intervals_start_idx on time_intervals(start_date);

comment on table time_intervals is '
    A time interval is represented by two points in time.
';      

create or replace package time_interval
as
    function new (
         -- Creates a new time interval
         -- @author W. Scott Meeks
         -- @param start_date   optional Sets this as start_date of new interval
         -- @param end_date             optional Sets this as end_date of new interval
         -- @return id of new time interval
         --
         start_date     in time_intervals.start_date%TYPE default null,
         end_date       in time_intervals.end_date%TYPE default null
    ) return time_intervals.interval_id%TYPE;

    procedure del (
         -- Deletes the given time interval
         -- @author W. Scott Meeks
         -- @param interval_id  id of the interval to delete
         --
         interval_id in time_intervals.interval_id%TYPE
    );

    -- NOTE: update is reserved and cannot be used for PL/SQL procedure names

    procedure edit (
         -- Updates the start_date or end_date of an interval
         -- @author W. Scott Meeks
         -- @param interval_id  id of the interval to update
         -- @param start_date   optional If provided, sets this as the new 
         --                         start_date of the interval.
         -- @param end_date     optional If provided, sets this as the new 
         --                         start_date of the interval.
         --
         interval_id    in time_intervals.interval_id%TYPE,
         start_date     in time_intervals.start_date%TYPE default null,
         end_date       in time_intervals.end_date%TYPE default null
    );

    procedure shift (
         -- Updates the start_date or end_date of an interval based on offsets of
         -- fractional days.
         -- @author W. Scott Meeks
         -- @param interval_id  The interval to update.
         -- @param start_offset optional If provided, adds this number to the
         --                              start_date of the interval.  No effect if 
         --                              start_date is null.
         -- @param end_offset   optional If provided, adds this number to the
         --                              end_date of the interval.  No effect if 
         --                              end_date is null.
         --
         interval_id    in time_intervals.interval_id%TYPE,
         start_offset   in number default 0,
         end_offset     in number default 0
    );
        
    function overlaps_p (
        -- Returns 't' if the two intervals overlap, 'f' otherwise.
        -- @author W. Scott Meeks
        -- @param interval_1_id
        -- @param interval_2_id
        -- @return 't' or 'f'
        --
        interval_1_id   in time_intervals.interval_id%TYPE,
        interval_2_id   in time_intervals.interval_id%TYPE
    ) return char;

    function overlaps_p (
        -- Returns 't if the interval bounded by the given start_date or
        -- end_date overlaps the given interval, 'f' otherwise.
        -- @author W. Scott Meeks
        -- @param start_date    optional If provided, see if it overlaps 
        --                                              the interval.
        -- @param end_date              optional If provided, see if it overlaps 
        --                                              the interval.
        -- @return 't' or 'f'
        --
        interval_id     in time_intervals.interval_id%TYPE,
        start_date      in time_intervals.start_date%TYPE default null,
        end_date        in time_intervals.end_date%TYPE default null
    ) return char;

    function overlaps_p (
        start_1 in time_intervals.start_date%TYPE,
        end_1   in time_intervals.end_date%TYPE,
        start_2 in time_intervals.start_date%TYPE,
        end_2   in time_intervals.end_date%TYPE
    ) return char;

    function eq (
        -- Checks if two intervals are equivalent
        -- @author W. Scott Meeks
        -- @param interval_1_id First interval
        -- @param interval_2_id Second interval
        -- @return boolean
        --
        interval_1_id   in time_intervals.interval_id%TYPE,
        interval_2_id   in time_intervals.interval_id%TYPE
    ) return boolean;

    function copy (
        -- Creates a new copy of a time interval, offset by optional offset
        -- @author W. Scott Meeks
        -- @param interval_id   Interval to copy
        -- @param offset        optional If provided, interval is
        --                      offset by this number of days.
        -- @return interval_id
        --
        interval_id     in time_intervals.interval_id%TYPE,
        offset          in integer default 0
    ) return time_intervals.interval_id%TYPE;

end time_interval;
/
show errors

create or replace package body time_interval
as
    function new (
        start_date  in time_intervals.start_date%TYPE default null,
        end_date    in time_intervals.end_date%TYPE default null
    ) return time_intervals.interval_id%TYPE
    is
        interval_id time_intervals.interval_id%TYPE;
    begin
        select timespan_seq.nextval into interval_id from dual;

        insert into time_intervals 
            (interval_id, start_date, end_date)
        values
            (interval_id, start_date, end_date);
                
        return interval_id;
    end new;

    procedure del (
        interval_id in time_intervals.interval_id%TYPE
    )
    is
    begin
        delete time_intervals
        where  interval_id = time_interval.del.interval_id;
    end del;

    procedure edit (
        interval_id     in time_intervals.interval_id%TYPE,
        start_date      in time_intervals.start_date%TYPE default null,
        end_date        in time_intervals.end_date%TYPE default null
    )
    is
    begin
        -- Null for start_date or end_date means don't change.
        if start_date is not null and end_date is not null then
            update time_intervals
            set    start_date  = edit.start_date,
                   end_date    = edit.end_date
            where  interval_id = edit.interval_id;
        elsif start_date is not null then
            update time_intervals
            set    start_date  = edit.start_date
            where  interval_id = edit.interval_id;
        elsif end_date is not null then
            update time_intervals
            set end_date       = edit.end_date
            where interval_id  = edit.interval_id;
        end if;
    end edit;

    procedure shift (
        interval_id      in time_intervals.interval_id%TYPE,
        start_offset     in number default 0,
        end_offset       in number default 0
    )
    is
    begin
        update time_intervals
        set    start_date = start_date + start_offset,
               end_date   = end_date + end_offset
        where  interval_id = shift.interval_id;
    end shift;

    function overlaps_p (
        interval_1_id   in time_intervals.interval_id%TYPE,
        interval_2_id   in time_intervals.interval_id%TYPE
    ) return char
    is
        start_1 date;
        start_2 date;
        end_1 date;
        end_2 date;
    begin
        -- Pull out the start and end dates and call the main overlaps_p.
        select start_date, 
               end_date
        into   start_1, 
               end_1
        from   time_intervals
        where  interval_id = interval_1_id;

        select start_date, 
               end_date
        into   start_2, 
               end_2
        from   time_intervals
        where  interval_id = interval_2_id;

        return overlaps_p(start_1, end_1, start_2, end_2);
    end overlaps_p;

    function overlaps_p (
        interval_id     in time_intervals.interval_id%TYPE,
        start_date      in time_intervals.start_date%TYPE default null,
        end_date        in time_intervals.end_date%TYPE default null
    ) return char
    is
        interval_start time_intervals.start_date%TYPE;
        interval_end   time_intervals.end_date%TYPE;
    begin
        -- Pull out the start and end date and call the main overlaps_p.
        select start_date, 
               end_date
        into   interval_start, 
               interval_end
        from   time_intervals
        where  interval_id = overlaps_p.interval_id;

        return overlaps_p(interval_start, interval_end, start_date, end_date);
    end overlaps_p;

    function overlaps_p (
        start_1 in time_intervals.start_date%TYPE,
        end_1   in time_intervals.end_date%TYPE,
        start_2 in time_intervals.start_date%TYPE,
        end_2   in time_intervals.end_date%TYPE
    ) return char
    is
    begin
        if start_1 is null then
            -- No overlap if 2nd interval starts after 1st ends
            if end_1 < start_2 then
                return 'f';
            else
                return 't';
            end if;
        elsif start_2 is null then
            -- No overlap if 2nd interval ends before 1st starts
            if end_2 < start_1 then
                return 'f';
            else
                return 't';
            end if;
        -- Okay, both start dates are not null
            elsif start_1 <= start_2 then
            -- 1st starts before 2nd
                if end_1 < start_2 then
                    -- No overlap if 1st ends before 2nd starts
                    return 'f';
                else
                    -- No overlap or at least one null
                    return 't';
                end if;
            else
                -- 1st starts after 2nd
                if end_2 < start_1 then
                    -- No overlap if 2nd ends before 1st starts
                    return 'f';
                else
                    -- No overlap or at least one null
                    return 't';
                end if;
            end if;
    end overlaps_p;

    function eq (
        -- Checks if two intervals are equivalent
        interval_1_id   in time_intervals.interval_id%TYPE,
        interval_2_id   in time_intervals.interval_id%TYPE
    ) return boolean
    is
        interval_1 time_intervals%ROWTYPE;
        interval_2 time_intervals%ROWTYPE;
    begin
        select * into interval_1
        from   time_intervals
        where  interval_id = interval_1_id;

        select * into interval_2
        from   time_intervals
        where  interval_id = interval_2_id;

        if interval_1.start_date = interval_2.start_date and 
           interval_1.end_date = interval_2.end_date then
            return true;
        else
            return false;
        end if;
    end eq;

    function copy (
        interval_id     in time_intervals.interval_id%TYPE,
        offset          in integer default 0
    ) return time_intervals.interval_id%TYPE
    is
        interval time_intervals%ROWTYPE;
    begin
        select * into interval
        from   time_intervals
        where  interval_id = copy.interval_id;

        return new(interval.start_date + offset, interval.end_date + offset);
    end copy;

end time_interval;
/
show errors

-- Create the timespans table.

create table timespans (           
    -- Can't be primary key because of the one to many relationship with
    -- interval_id, but we can declare it not null and index it.
    timespan_id     integer not null,
    interval_id     integer
                    constraint tm_ntrvl_sts_interval_id_fk
                         references time_intervals on delete cascade
);

create index timespans_idx on timespans(timespan_id);

-- This is important to prevent locking on update of master table.
-- See  http://www.arsdigita.com/bboard/q-and-a-fetch-msg.tcl?msg_id=000KOh
create index timespans_interval_id_idx on timespans(interval_id);

comment on table timespans is '
    Establishes a relationship between timespan_id and multiple time
    intervals.  Represents a range of moments at which an event can occur.
';

-- TimeSpan API
--
-- Quick reference for the API supported for timespans.  All procedures take timespan_id
-- as the first argument (not shown explicitly):
-- 
--     new          (interval_id)
--     new          (start_date, end_date)
--     del       ()
--
-- Methods to join additional time intervals with an existing timespan:
--
--     join          (timespan_id)
--     join_interval (interval_id)
--     join          (start_date, end_date)
--
--     interval_delete (interval_id)
--     interval_list   ()
--
-- Tests for overlap:
-- 
--     overlaps_p   (timespan_id)
--     overlaps_p   (interval_id)
--     overlaps_p   (start_date, end_date)
--
-- Info:
--
--         exists_p                     ()
--     multi_interval_p ()

create or replace package timespan
as
    function new (
        -- Creates a new timespan (20.20.10)
        -- given a time_interval
        -- Copies the interval so the caller is responsible for deleting it
        interval_id in time_intervals.interval_id%TYPE default null
    ) return timespans.timespan_id%TYPE;

    function new (
        -- Creates a new timespan (20.20.10)
        -- given a start_date and end_date
        start_date      in time_intervals.start_date%TYPE default null,
        end_date        in time_intervals.end_date%TYPE default null
    ) return timespans.timespan_id%TYPE;

    procedure del (
        -- Deletes the timespan and any contained intervals 
        -- @author W. Scott Meeks
        -- @param timespan_id   id of timespan to delete
        timespan_id in timespans.timespan_id%TYPE
    );

    -- Join a new timespan or time interval to an existing timespan

    procedure join (
        -- timespan_1_id is modified, timespan_2_id is not
        timespan_1_id   in timespans.timespan_id%TYPE,
        timespan_2_id   in timespans.timespan_id%TYPE
    );

        -- Unfortunately, Oracle can't distinguish the signature of this function
        -- with the previous because the args have the same underlying types
        -- 
    procedure join_interval (
        -- interval is copied to the timespan
        timespan_id       in timespans.timespan_id%TYPE,
        interval_id       in time_intervals.interval_id%TYPE,
        copy_p                    in boolean default true
    );

    procedure join (
        timespan_id       in timespans.timespan_id%TYPE,
        start_date        in time_intervals.start_date%TYPE default null,
        end_date          in time_intervals.end_date%TYPE default null
    );


    procedure interval_delete (
        -- Deletes an interval from the given timespan
        -- @author W. Scott Meeks
        -- @param timespan_id   timespan to delete from
        -- @param interval_id           delete this interval from the set
        --
        timespan_id     in timespans.timespan_id%TYPE,
        interval_id     in time_intervals.interval_id%TYPE
    );

    -- Information

    function exists_p (
        -- If its contained intervals are all deleted, then a timespan will
        -- automatically be deleted.  This checks a timespan_id to make sure it's 
        -- still valid.
        -- @author W. Scott Meeks
        -- @param timespan_id   id of timespan to check
        -- @return 't' or 'f'
        timespan_id in timespans.timespan_id%TYPE
    ) return char;

    function multi_interval_p (
        -- Returns 't' if timespan contains more than one interval, 
        -- 'f' otherwise (
        -- @author W. Scott Meeks
        -- @param timespan_id   id of set to check
        -- @return 't' or 'f'
        timespan_id in timespans.timespan_id%TYPE
    ) return char;


    function overlaps_p (
        -- Checks to see if a given interval overlaps any of the intervals
        -- in the given timespan.
        timespan_1_id   in timespans.timespan_id%TYPE,
        timespan_2_id   in timespans.timespan_id%TYPE
    ) return char;

    -- Unfortunately, Oracle can't distinguish the signature of this function
    -- with the previous because the args have the same underlying types
    -- 
    function overlaps_interval_p (
        timespan_id     in timespans.timespan_id%TYPE,
        interval_id     in time_intervals.interval_id%TYPE default null
    ) return char;

    function overlaps_p (
        timespan_id     in timespans.timespan_id%TYPE,
        start_date      in time_intervals.start_date%TYPE default null,
        end_date        in time_intervals.end_date%TYPE default null
    ) return char;

    function copy (
        -- Creates a new copy of a timespan, offset by optional offset
        -- @author W. Scott Meeks
        -- @param timespan_id   Timespan to copy
        -- @param offset        optional If provided, all dates in timespan
        --                      are offset by this number of days.
        -- @return timespan_id
        --
        timespan_id     in timespans.timespan_id%TYPE,
        offset          in integer default 0
    ) return timespans.timespan_id%TYPE;

end timespan;
/
show errors

create or replace package body timespan
as
    function new (
        interval_id in time_intervals.interval_id%TYPE
    ) return timespans.timespan_id%TYPE
    is
        timespan_id      timespans.timespan_id%TYPE;
        new_interval_id  time_intervals.interval_id%TYPE;
    begin
        select timespan_seq.nextval into timespan_id from dual;
        
        new_interval_id := time_interval.copy(interval_id);
        
        insert into timespans
            (timespan_id, interval_id)
        values
            (timespan_id, new_interval_id);
        
        return timespan_id;
    end new;

    function new (
        start_date      in time_intervals.start_date%TYPE default null,
        end_date        in time_intervals.end_date%TYPE default null
    ) return timespans.timespan_id%TYPE
    is
    begin
        return new(time_interval.new(start_date, end_date));
    end new;

    procedure del (
        timespan_id in timespans.timespan_id%TYPE
    )
    is
    begin
        -- Delete intervals, corresponding timespan entries deleted by
        -- cascading constraints
        delete from time_intervals
        where  interval_id in (select interval_id
                               from   timespans
                               where  timespan_id = timespan.del.timespan_id);
    end del;

    --
    -- Join a new timespan or time interval to an existing timespan
    --
    procedure join (
        timespan_1_id   in timespans.timespan_id%TYPE,
        timespan_2_id   in timespans.timespan_id%TYPE
    )
    is
        cursor timespan_cursor is
            select * 
            from   timespans
            where  timespan_id = timespan_2_id;
        timespan_val timespan_cursor%ROWTYPE;
    begin
        -- Loop over intervals in 2nd timespan, join with 1st.
        for timespan_val in timespan_cursor
        loop
            join_interval(timespan_1_id, timespan_val.interval_id);
        end loop;
    end join;

    -- Optional argument to copy interval
    procedure join_interval (
         timespan_id     in timespans.timespan_id%TYPE,
         interval_id     in time_intervals.interval_id%TYPE,
         copy_p          in boolean default true
    )
    is
        new_interval_id time_intervals.interval_id%TYPE;
    begin
        if copy_p then
           new_interval_id := time_interval.copy(interval_id);
        else
           new_interval_id := interval_id;
        end if;
        
        insert into timespans
            (timespan_id, interval_id)
        values
            (timespan_id, new_interval_id);
    end join_interval;

    procedure join (
        timespan_id in timespans.timespan_id%TYPE,
        start_date  in time_intervals.start_date%TYPE default null,
        end_date    in time_intervals.end_date%TYPE default null
    )
    is
    begin
        join_interval(
            timespan_id => timespan_id, 
            interval_id => time_interval.new(start_date, end_date),
            copy_p      => false
        );
    end join;

    procedure interval_delete (
        timespan_id in timespans.timespan_id%TYPE,
        interval_id in time_intervals.interval_id%TYPE
    )
    is
    begin
        delete from timespans
        where timespan_id = interval_delete.timespan_id
        and   interval_id = interval_delete.interval_id;
    end interval_delete;

    -- Information

    function exists_p (
        timespan_id in timespans.timespan_id%TYPE
    ) return char
    is
        result integer;
    begin
        -- Only need to check if any rows exist.
        select count(*)
        into   result
        from   dual 
        where  exists (select timespan_id
                       from   timespans
                       where  timespan_id = exists_p.timespan_id);
        if result = 0 then
           return 'f';
        else
           return 't';
        end if;
    end exists_p;

    function multi_interval_p (
        timespan_id in timespans.timespan_id%TYPE
    ) return char
    is
        result char;
    begin
        -- 'f' if 0 or 1 intervals, 't' otherwise
        select decode(count(timespan_id), 0, 'f', 1, 'f', 't')
        into result
        from timespans
        where timespan_id = multi_interval_p.timespan_id;
        
        return result;
    end multi_interval_p;


    function overlaps_p (
        -- Checks to see if any intervals in a timespan overlap any of the intervals
        -- in the second timespan.
        timespan_1_id   in timespans.timespan_id%TYPE,
        timespan_2_id   in timespans.timespan_id%TYPE
    ) return char
    is
        result char;
        cursor timespan_cursor is
            select * 
            from timespans
            where timespan_id = timespan_2_id;
        timespan_val timespan_cursor%ROWTYPE;
    begin
        -- Loop over 2nd timespan, checking each interval against 1st
        for timespan_val in timespan_cursor
        loop
            result := overlaps_interval_p
                (timespan_1_id,
                 timespan_val.interval_id
            );
            if result = 't' then
                return 't';
            end if;
        end loop;
        return 'f';
    end overlaps_p;

    function overlaps_interval_p (
        timespan_id in timespans.timespan_id%TYPE,
        interval_id in time_intervals.interval_id%TYPE default null
    ) return char
    is
        start_date date;
        end_date date;
    begin
        select start_date, end_date
        into   start_date, end_date
        from   time_intervals
        where  interval_id = overlaps_interval_p.interval_id;
        
        return overlaps_p(timespan_id, start_date, end_date);
    end overlaps_interval_p;

    function overlaps_p (
        timespan_id     in timespans.timespan_id%TYPE,
        start_date      in time_intervals.start_date%TYPE default null,
        end_date        in time_intervals.end_date%TYPE default null
    ) return char
    is
        result char;
        cursor timespan_cursor is
            select * 
            from timespans
            where timespan_id = overlaps_p.timespan_id;
        timespan_val timespan_cursor%ROWTYPE;
    begin
        -- Loop over each interval in timespan, checking against dates.
        for timespan_val in timespan_cursor
        loop
            result := time_interval.overlaps_p(
                timespan_val.interval_id, 
                start_date,
                end_date
            );

            if result = 't' then
                return 't';
            end if;
        end loop;
        return 'f';
    end overlaps_p;

    function copy (
        timespan_id in timespans.timespan_id%TYPE,
        offset      in integer default 0
    ) return timespans.timespan_id%TYPE
    is
        cursor timespan_cursor is
            select * 
            from timespans
            where timespan_id = copy.timespan_id;
        timespan_val     timespan_cursor%ROWTYPE;
        new_interval_id  timespans.interval_id%TYPE;
        new_timespan_id  timespans.timespan_id%TYPE;
     begin
        new_timespan_id := null;

        -- Loop over each interval in timespan, creating a new copy
        for timespan_val in timespan_cursor
        loop
            new_interval_id := time_interval.copy(timespan_val.interval_id, offset);

            if new_timespan_id is null then
                new_timespan_id := new(new_interval_id);
            else
                join_interval(new_timespan_id, new_interval_id);
            end if;
        end loop;
        return new_timespan_id;
    end copy;

end timespan;
/
show errors


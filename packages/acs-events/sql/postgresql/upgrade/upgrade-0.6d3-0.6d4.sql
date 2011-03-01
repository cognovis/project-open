-- 
-- 
-- 
-- @author Victor Guerra (vguerra@gmail.com)
-- @creation-date 2010-11-05
-- @cvs-id $Id: upgrade-0.6d3-0.6d4.sql,v 1.1 2010/11/08 13:10:35 victorg Exp $
--

-- PG 9.x support - changes regarding usage of sequences

drop view acs_events_seq;
drop sequence acs_events_sequence;
drop view timespan_seq;
drop view recurrence_seq;

create or replace function time_interval__new (
       -- 
       -- Creates a new time interval
       --
       -- @author W. Scott Meeks
       --
       -- @param start_date   Sets this as start_date of new interval
       -- @param end_date     Sets this as end_date of new interval
       --
       -- @return id of new time interval
       --
       timestamptz,     -- time_intervals.start_date%TYPE default null,
       timestamptz      -- time_intervals.end_date%TYPE default null
) 
returns integer as '    -- time_intervals.interval_id%TYPE
declare
       new__start_date  alias for $1; -- default null,
       new__end_date    alias for $2; -- default null
       v_interval_id     time_intervals.interval_id%TYPE;
begin
       select nextval(''timespan_sequence'') into v_interval_id from dual;

       insert into time_intervals 
            (interval_id, start_date, end_date)
       values
            (v_interval_id, new__start_date, new__end_date);
                
       return v_interval_id;

end;' language 'plpgsql'; 

create or replace function timespan__new (
       --
       -- Creates a new timespan (20.20.10)
       -- given a time_interval
       --
       -- JS: Allow user to specify whether the itme interval is to be copied or not
       -- JS: This gives more flexibility of not making a copy instead of requiring 
       -- JS: the caller responsible for deleting the copy.
       --
       -- @author W. Scott Meeks
       --
       -- @param interval_id    Id of interval to be included/copied in timespan, 
       -- @param copy_p         If true, make another copy of the interval, 
       --                       else simply include the interval in the timespan
       --
       -- @return Id of new timespan       
       --
       integer,         -- time_intervals.interval_id%TYPE
       boolean          
)
returns integer as '    -- timespans.timespan_id%TYPE
declare
        new__interval_id        alias for $1;
        new__copy_p             alias for $2;
        v_timespan_id           timespans.timespan_id%TYPE;
        v_interval_id           time_intervals.interval_id%TYPE;
begin
        -- get a new id;
        select nextval(''timespan_sequence'') into v_timespan_id from dual;

        if new__copy_p
        then      
             -- JS: Note use of overloaded function (zero offset)
             v_interval_id := time_interval__copy(new__interval_id);
        else
             v_interval_id := new__interval_id;
        end if;
        
        insert into timespans
            (timespan_id, interval_id)
        values
            (v_timespan_id, v_interval_id);
        
        return v_timespan_id;

end;' language 'plpgsql'; 

create or replace function recurrence__new (
       --
       -- Creates a new recurrence
       --
       -- @author W. Scott Meeks
       --
       -- @param interval_type        Sets interval_type of new recurrence
       -- @param every_nth_interval   Sets every_nth_interval of new recurrence
       -- @param days_of_week         Sets days_of_week of new recurrence
       -- @param recur_until          Sets recur_until of new recurrence
       -- @param custom_func          Sets name of custom recurrence function
       --                                  
       -- @return id of new recurrence
       --
       varchar,		-- recurrence_interval_types.interval_name%TYPE,
       integer,		-- recurrences.every_nth_interval%TYPE,
       varchar,		-- recurrences.days_of_week%TYPE default null,
       timestamptz,	-- recurrences.recur_until%TYPE default null,
       varchar		-- recurrences.custom_func%TYPE default null
) 
returns integer as '	-- recurrences.recurrence_id%TYPE
declare
       new__interval_name	  alias for $1; 
       new__every_nth_interval   alias for $2;
       new__days_of_week         alias for $3; -- default null,
       new__recur_until          alias for $4; -- default null,
       new__custom_func          alias for $5; -- default null
       v_recurrence_id		  recurrences.recurrence_id%TYPE;
       v_interval_type_id	  recurrence_interval_types.interval_type%TYPE;
begin

       select nextval(''recurrence_sequence'') into v_recurrence_id from dual;
        
       select interval_type
       into   v_interval_type_id 
       from   recurrence_interval_types
       where  interval_name = new__interval_name;
        
       insert into recurrences
            (recurrence_id, 
             interval_type, 
             every_nth_interval, 
             days_of_week,
             recur_until, 
             custom_func)
       values
            (v_recurrence_id, 
             v_interval_type_id, 
             new__every_nth_interval, 
             new__days_of_week,
             new__recur_until, 
             new__custom_func);
         
       return v_recurrence_id;

end;' language 'plpgsql'; 

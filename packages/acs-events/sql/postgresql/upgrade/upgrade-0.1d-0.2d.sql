-- created by arjun@openforce.net 
-- from a bug fix by  Deds Castillo

create or replace function acs_event__recurrence_timespan_edit (
       integer,
       timestamp,
       timestamp
) returns integer as '
DECLARE
        p_event_id                      alias for $1;
        p_start_date                    alias for $2;
        p_end_date                      alias for $3;
        v_timespan                   RECORD;
        v_one_start_date             timestamp;
        v_one_end_date               timestamp;
BEGIN
        -- get the initial offsets
        select start_date,
               end_date into v_one_start_date,
               v_one_end_date
        from time_intervals, 
             timespans, 
             acs_events 
        where time_intervals.interval_id = timespans.interval_id
          and timespans.timespan_id = acs_events.timespan_id
          and event_id=p_event_id;

        -- RBM: Converted inneficient query to INNER JOINs (2002-10-06)
	--
        -- FOR v_timespan in
        --    select *
        --    from time_intervals
        --    where interval_id in (select interval_id
        --                          from timespans 
        --                          where timespan_id in (select timespan_id
        --                                                from acs_events 
        --                                                where recurrence_id = (select recurrence_id 
        --                                                                       from acs_events where event_id = p_event_id)))

        FOR v_timespan in
            SELECT ti.*
              FROM time_intervals ti, timespans t, acs_events ae
	     WHERE ti.interval_id = t.interval_id
	       AND t.timespan_id = ae.timespan_id
	       AND ae.event_id = p_event_id
        LOOP
                PERFORM time_interval__edit(v_timespan.interval_id, 
                                            v_timespan.start_date + (p_start_date - v_one_start_date), 
                                            v_timespan.end_date + (p_end_date - v_one_end_date));
        END LOOP;

        return p_event_id;
END;
' language 'plpgsql';


-- to_interval() now returns 'timespan' not 'interval'

create or replace function to_interval (
       --
       -- Convert an integer to the specified interval
       --
       -- Utility function so we do not have to remember how to escape
       -- double quotes when we typecast an integer to an interval
       --
       -- @author jowell@jsabino.com
       --
       -- @param interval_number	Integer to convert to interval
       -- @param interval_units		Interval units
       --
       -- @return interval equivalent of interval_number, in interval_units units
       --       
       integer,
       varchar
)
returns interval as '	
declare    
       interval__number	     alias for $1;
       interval__units	     alias for $2;
begin

	-- We should probably do unit checking at some point
	return ('''''''' || interval__number || '' '' || interval__units || '''''''')::interval;

end;' language 'plpgsql';

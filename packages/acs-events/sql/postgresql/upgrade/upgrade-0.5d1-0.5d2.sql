create or replace function acs_event__get_html_p (
       --
       -- Returns html_p or html_p of the activity associated with the event if 
       -- html_p is null.
       --
       -- @author W. Scott Meeks
       --
       -- @param event_id id of event to get html_p for
       --
       -- @return The html_p or html_p of the activity associated with the event if html_p is null.
       --
       integer		-- acs_events.event_id%TYPE 
)
returns boolean as '	-- acs_events.html_p%TYPE
declare
       get_html_p__event_id    alias for $1; -- in acs_events.event_id%TYPE 
       v_html_p		acs_events.html_p%TYPE; 
begin
       select coalesce(e.html_p, a.html_p) into v_html_p
       from  acs_events e
       left join acs_activities a
       on (e.activity_id = a.activity_id)
       where e.event_id = get_html_p__event_id;

       return v_html_p;

end;' language 'plpgsql';


create or replace function acs_event__get_status_summary (
       --
       -- Returns status_summary or status_summary of the activity associated with the event if 
       -- status_summary is null.
       --
       -- @author W. Scott Meeks
       --
       -- @param event_id id of event to get status_summary for
       --
       -- @return The status_summary or status_summary of the activity associated with the event if status_summary is null.
       --
       integer		-- acs_events.event_id%TYPE 
)
returns boolean as '
declare
       get_status_summary__event_id    alias for $1; -- acs_events.event_id%TYPE 
       v_status_summary		acs_events.status_summary%TYPE; 
begin
       select coalesce(e.status_summary, a.status_summary) into v_status_summary
       from  acs_events e
       left join acs_activities a
       on (e.activity_id = a.activity_id)
       where e.event_id = get_status_summary__event_id;

       return v_status_summary;

end;' language 'plpgsql';


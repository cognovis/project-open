-- backwards compatible 13 param version
create or replace function acs_event__new ( 
       integer,
       varchar,
       text,
       boolean,
       text,
       integer,
       integer,
       integer,
       varchar,
       timestamptz,
       integer,
       varchar,
       integer
)
returns integer as '
begin
       return acs_event__new($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,null);
end;' language 'plpgsql';

create or replace function acs_event__new (
       --
       -- Creates a new event (20.10.10)
       --
       -- @author W. Scott Meeks
       --
       -- @param event_id          id to use for new event
       -- @param name              Name of the new event
       -- @param description       Description of the new event
       -- @param html_p            Is the description HTML?
       -- @param status_summary    Optional additional status line to display
       -- @param timespan_id       initial time interval set
       -- @param activity_id       initial activity
       -- @param recurrence_id     id of recurrence information
       -- @param object_type       'acs_event'
       -- @param creation_date     default now()
       -- @param creation_user     acs_object param
       -- @param creation_ip       acs_object param
       -- @param context_id        acs_object param
       --
       -- @return The id of the new event.
       --
       integer,		-- acs_events.event_id%TYPE,	     
       varchar,		-- acs_events.name%TYPE,		     
       text,		-- acs_events.description%TYPE,	     
       boolean,		-- acs_events.html_p%TYPE,	     
       text,		-- acs_events.status_summary%TYPE,	     
       integer,		-- acs_events.timespan_id%TYPE,	     
       integer,		-- acs_events.activity_id%TYPE,	     
       integer,		-- acs_events.recurrence_id%TYPE,     
       varchar,		-- acs_object_types.object_type%TYPE, 
       timestamptz,	-- acs_objects.creation_date%TYPE,    
       integer,		-- acs_objects.creation_user%TYPE,    
       varchar,		-- acs_objects.creation_ip%TYPE,	     
       integer,		-- acs_objects.context_id%TYPE,	     
       integer		-- acs_objects.package_id%TYPE,	     
)
returns integer as '	-- acs_events.event_id%TYPE
declare
       new__event_id        alias for $1;  -- default null, 
       new__name            alias for $2;  -- default null,
       new__description     alias for $3;  -- default null,
       new__html_p          alias for $4; -- default null 
       new__status_summary  alias for $5; -- default null 
       new__timespan_id     alias for $6;  -- default null, 
       new__activity_id     alias for $7;  -- default null, 
       new__recurrence_id   alias for $8;  -- default null, 
       new__object_type     alias for $9;  -- default ''acs_event'', 
       new__creation_date   alias for $10;  -- default now(),
       new__creation_user   alias for $11;  -- default null, 
       new__creation_ip     alias for $12; -- default null, 
       new__context_id      alias for $13; -- default null 
       new__package_id      alias for $14; -- default null 
       v_event_id	    acs_events.event_id%TYPE;
begin
       v_event_id := acs_object__new(
            new__event_id,	-- object_id
            new__object_type,	-- object_type
            new__creation_date, -- creation_date
            new__creation_user,	-- creation_user
            new__creation_ip,	-- creation_ip
            new__context_id,	-- context_id
            ''t'',		-- security_inherit_p
            new__name,		-- title
            new__package_id	-- package_id
	    );

       insert into acs_events
            (event_id, name, description, html_p, status_summary, activity_id, timespan_id, recurrence_id)
       values
            (v_event_id, new__name, new__description, new__html_p, new__status_summary, new__activity_id, new__timespan_id,
             new__recurrence_id);

       return v_event_id;

end;' language 'plpgsql';

create or replace function acs_event__new_instance (
       --
       -- Create a new instance of an event, with dateoffset from the start_date
       -- and end_date of event identified by event_id. Note that dateoffset
       -- is an interval, not an integer.  This function is used internally by 
       -- insert_instances. Since this function is internal, there is no need 
       -- to overload a function that has an integer for the dateoffset.
       --
       -- @author W. Scott Meeks
       --
       -- @param event_id	Id of event to reference 
       -- @param date_offset    Offset from reference event, in date interval
       --
       -- @return  event_id of new event created.
       -- 
       integer,               -- acs_events.event_id%TYPE,
       interval               
)
returns integer as '	      -- acs_events.event_id%TYPE
declare
       new_instance__event_id    alias for $1;
       new_instance__date_offset alias for $2;
       event_row		  acs_events%ROWTYPE;
       object_row		  acs_objects%ROWTYPE;
       v_event_id		  acs_events.event_id%TYPE;
       v_timespan_id		  acs_events.timespan_id%TYPE;
begin

       -- Get event parameters
       select * into event_row
       from   acs_events
       where  event_id = new_instance__event_id;

       -- Get object parameters                
       select * into object_row
       from   acs_objects
       where  object_id = new_instance__event_id;

       -- We allow non-zero offset, so we copy
       v_timespan_id := timespan__copy(event_row.timespan_id, new_instance__date_offset);

       -- Create a new instance
       v_event_id := acs_event__new(
	    null,                     -- event_id (default)
            event_row.name,           -- name
            event_row.description,    -- description
            event_row.html_p,         -- html_p
            event_row.status_summary, -- status_summary
            v_timespan_id,	      -- timespan_id
            event_row.activity_id,    -- activity_id
            event_row.recurrence_id,  -- recurrence_id
	    ''acs_event'',	      -- object_type (default)
	    now(),		      -- creation_date (default)
            object_row.creation_user, -- creation_user
            object_row.creation_ip,   -- creation_ip
            object_row.context_id,     -- context_id
            object_row.package_id     -- context_id
	    );

      return v_event_id;

end;' language 'plpgsql';


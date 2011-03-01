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


drop function acs_event__new (integer,varchar,text,boolean,text,integer,integer,integer,varchar,timestamptz,integer,varchar,integer);

create function acs_event__new ( 
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
       integer		-- acs_objects.context_id%TYPE,	     
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
            null		-- package_id
	    );
                
       insert into acs_events
            (event_id, name, description, html_p, status_summary, activity_id, timespan_id, recurrence_id)
       values
            (v_event_id, new__name, new__description, new__html_p, new__status_summary, new__activity_id, new__timespan_id,
             new__recurrence_id);

       return v_event_id;

end;' language 'plpgsql';



drop function acs_activity__new (integer,varchar,text,boolean,text,varchar,timestamptz,integer,varchar,integer);

create function acs_activity__new (
       --
       -- Create a new activity
       --
       -- @author W. Scott Meeks
       --
       -- @param activity_id       Id to use for new activity
       -- @param name              Name of the activity 
       -- @param description       Description of the activity
       -- @param html_p            Is the description HTML?
       -- @param status_summary    Additional status note (optional)
       -- @param object_type       'acs_activity'
       -- @param creation_date     default now()
       -- @param creation_user     acs_object param
       -- @param creation_ip       acs_object param
       -- @param context_id        acs_object param
       --
       -- @return The id of the new activity.
       --
       integer,			 -- in acs_activities.activity_id%TYPE
       varchar,			 -- in acs_activities.name%TYPE,
       text,			 -- in acs_activities.description%TYPE
       boolean,			 -- in acs_activities.html_p%TYPE     
       text,			 -- in acs_activities.status_summary%TYPE     
       varchar,			 -- in acs_object_types.object_type%TYPE
       timestamptz,		 -- in acs_objects.creation_date%TYPE
       integer,			 -- in acs_objects.creation_user%TYPE
       varchar,			 -- in acs_objects.creation_ip%TYPE
       integer			 -- in acs_objects.context_id%TYPE
)
returns integer as '		 -- return acs_activities.activity_id%TYPE
declare       
       new__activity_id         alias for $1; -- default null, 
       new__name                alias for $2;
       new__description         alias for $3; -- default null,
       new__html_p              alias for $4; -- default ''f'',
       new__status_summary      alias for $5; -- default null,
       new__object_type         alias for $6; -- default ''acs_activity''
       new__creation_date       alias for $7; -- default now(), 
       new__creation_user       alias for $8; -- default null, 
       new__creation_ip         alias for $9; -- default null, 
       new__context_id          alias for $10; -- default null 
       v_activity_id		  acs_activities.activity_id%TYPE;
begin
       v_activity_id := acs_object__new(
            new__activity_id,	   -- object_id
            new__object_type,	   -- object_type
            new__creation_date,    -- creation_date  
            new__creation_user,    -- creation_user
            new__creation_ip,	   -- creation_ip
            new__context_id,	   -- context_id
            ''t'',		   -- security_inherit_p
            new__name,		   -- title
            null		   -- package_id
	    );

       insert into acs_activities
            (activity_id, name, description, html_p, status_summary)
       values
            (v_activity_id, new__name, new__description, new__html_p, new__status_summary);

       return v_activity_id;

end;' language 'plpgsql'; 


drop function acs_activity__edit (integer,varchar,text,boolean,text);

create function acs_activity__edit (
       --
       -- Update the name or description of an activity
       --
       -- @author W. Scott Meeks
       --
       -- @param activity_id activity to update
       -- @param name        optional New name for this activity
       -- @param description optional New description for this activity
       -- @param html_p      optional New value of html_p for this activity
       -- @param status_summary optional New value of status_summary for this activity
       --
       -- @return 0 (procedure dummy)
       --
       integer,		-- acs_activities.activity_id%TYPE, 
       varchar,		-- acs_activities.name%TYPE default null,
       text,		-- acs_activities.description%TYPE default null,
       boolean,		-- acs_activities.html_p%TYPE default null
       text		-- acs_activities.status_summary%TYPE default null,
) returns integer as '
declare
       edit__activity_id   alias for $1;
       edit__name          alias for $2; -- default null,
       edit__description   alias for $3; -- default null,
       edit__html_p        alias for $4; -- default null
       edit__status_summary alias for $5; -- default null
begin

       update acs_activities
       set    name        = coalesce(edit__name, name),
              description = coalesce(edit__description, description),
              html_p      = coalesce(edit__html_p, html_p),
              status_summary = coalesce(edit__status_summary, status_summary)
       where activity_id  = edit__activity_id;

       update acs_objects
       set    title = coalesce(edit__name, name)
       where activity_id  = edit__activity_id;

       return 0;

end;' language 'plpgsql';

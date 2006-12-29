-- /packages/intranet-calendar/sql/postgresql/intranet-calendar-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------------
-- 

-- Add a new field to acs_events to point back to the related object.

alter table acs_events
add related_object_id integer
	constraint acs_events_rel_oid_fk
	references acs_objects;

create index acs_events_rel_object_ids on acs_events (related_object_id);


-- Start off with a single (global) calendar

SELECT calendar__new(
	null,		-- calendar_id
	'Global Calendar',-- calendar_name
	'calendar',	-- object_type
	(select object_id from acs_magic_objects where name = 'registered_users'),-- owner_id
	'f',		-- private_p
	(select package_id from apm_packages where package_key = 'calendar'),-- package_id
	(select package_id from apm_packages where package_key = 'calendar'), -- context_id
	now(),		-- creation_date
	null,		-- creation_user
	'0.0.0.0'	-- creation_ip
);




drop trigger im_projects_calendar_update_tr on im_projects;
drop function im_projects_calendar_update_tr();

create or replace function im_projects_calendar_update_tr () returns trigger as '
declare
	v_old_event_id		integer;	
	v_timespan_id		integer;
	v_interval_id		integer;
	v_calendar_id		integer;
	v_activity_id		integer;
	v_recurrence_id		integer;
	v_cal_item_id		integer;
begin
	-- Check if the entry already exists
	v_old_event_id := null;
	SELECT	event_id
	INTO	v_old_event_id
	FROM	acs_events
	WHERE	related_object_id = new.project_id;

	IF v_old_event_id is not null THEN
		UPDATE	acs_events 
		SET	name = new.project_name,
			description = new.description
		WHERE	event_id = v_old_event_id;
		-- ToDo: Update the timepan/interval		
	    return new;
	END IF;

	v_timespan_id := timespan__new(new.start_date, new.end_date);
	RAISE NOTICE ''im_projects_calendar_update_tr: timespan_id=%'', v_timespan_id;

	v_activity_id := acs_activity__new(
		null, 
		new.project_name,
		new.description, 
		''f'', 
		'''', 
		''acs_activity'', now(), null, ''0.0.0.0'', null
	);
	RAISE NOTICE ''im_projects_calendar_update_tr: v_activity_id=%'', v_activity_id;

	SELECT	calendar_id
	INTO 	v_calendar_id
	FROM	calendars
	WHERE	calendar_name = ''Global Calendar'';

	v_recurrence_id := NULL;
	v_cal_item_id := cal_item__new (
		null,			-- cal_item_id
		v_calendar_id,		-- on_which_calendar
		new.project_name,	-- name
		new.description,	-- description
		''f'',			-- html_p
		'''',			-- status_summary
		v_timespan_id,		-- timespan_id
		v_activity_id,		-- activity_id
		v_recurrence_id,	-- recurrence_id
		''cal_item'', null, now(), null, ''0.0.0.0''	
	);
	RAISE NOTICE ''im_projects_calendar_update_tr: cal_id=%'', v_cal_item_id;

	update	acs_events
	set	related_object_id = new.project_id
	where	event_id = v_cal_item_id;

	return new;
end;' language 'plpgsql';

create trigger im_projects_calendar_update_tr after insert or update
on im_projects for each row
execute procedure im_projects_calendar_update_tr ();

update im_projects set start_date = start_date::date where project_nr like '2006_0051';
-- update im_projects set start_date = start_date::date where project_nr like '2006%';

select count(*) from acs_events;


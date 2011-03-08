-- /packages/intranet-calendar/sql/postgresql/intranet-calendar-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------------
-- 

-- Add a new field to acs_events to point back to the related object.

alter table acs_events
add related_object_id integer;

alter table acs_events
add related_object_type varchar(100)
	constraint acs_events_rel_otype_fk
	references acs_object_types;

create index acs_events_rel_object_ids on acs_events (related_object_id);


-- Start off with a single (global) calendar

SELECT calendar__new(
	null,		-- calendar_id
	'Global Calendar',-- calendar_name
	'calendar',	-- object_type
	(select object_id from acs_magic_objects where name = 'registered_users'), -- owner_id
	'f',		-- private_p
	(select package_id from apm_packages where package_key = 'calendar'), -- package_id
	(select package_id from apm_packages where package_key = 'calendar'), -- context_id
	now(),		-- creation_date
	null,		-- creation_user
	'0.0.0.0'	-- creation_ip
);




create or replace function inline_0() returns integer as '
declare
	row			record;
begin
	FOR row IN
		SELECT	cal_item_id
		FROM	cal_items
	LOOP
		RAISE NOTICE ''inline_0: cal_item_id=%'', row.cal_item_id;
		PERFORM cal_item__delete(row.cal_item_id);

	END LOOP;

        return 0;
end;' language 'plpgsql';

-- select inline_0();
drop function inline_0();




-- --------------------------------------------------------
-- Projects Trigger
-- --------------------------------------------------------

-- drop trigger im_projects_calendar_update_tr on im_projects;
-- drop function im_projects_calendar_update_tr();

create or replace function im_projects_calendar_update_tr () returns trigger as '
declare
	v_cal_item_id		integer;	

	v_timespan_id		integer;
	v_interval_id		integer;
	v_calendar_id		integer;
	v_activity_id		integer;
	v_recurrence_id		integer;
begin
	-- -------------- Skip if start or end date are null ------------
	IF new.start_date is null OR new.end_date is null THEN
		return new;
	END IF;

	-- -------------- Check if the entry already exists ------------
	v_cal_item_id := null;

	SELECT	event_id
	INTO	v_cal_item_id
	FROM	acs_events
	WHERE	related_object_id = new.project_id
		and related_object_type = ''im_project'';

	-- --------------------- Create entry if it isnt there -------------
	IF v_cal_item_id is null THEN

		v_timespan_id := timespan__new(new.end_date, new.end_date);
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
	
		SELECT	min(calendar_id)
		INTO 	v_calendar_id
		FROM	calendars
		WHERE	private_p = ''f'';
	
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

	END IF;

	-- --------------------- Update the entry --------------------
	SELECT	activity_id	INTO v_activity_id	FROM acs_events	WHERE	event_id = v_cal_item_id;
	SELECT	timespan_id	INTO v_timespan_id	FROM acs_events	WHERE	event_id = v_cal_item_id;
	SELECT	recurrence_id	INTO v_recurrence_id	FROM acs_events	WHERE	event_id = v_cal_item_id;

	-- Update the event
	UPDATE	acs_events 
	SET	name = new.project_name,
		description = new.description,
		related_object_id = new.project_id,
		related_object_type = ''im_project'',
		related_link_url = ''/intranet/projects/view?project_id=''||new.project_id,
		related_link_text = new.project_name || '' Project'',
		redirect_to_rel_link_p = ''t''
	WHERE	event_id = v_cal_item_id;

	-- Update the activity - same as event
	UPDATE	acs_activities
	SET	name = new.project_name,
		description = new.description
	WHERE	activity_id = v_activity_id;

	-- Update the timespan. Make sure there is only one interval
	-- in this timespan (there may be multiples)
	SELECT	interval_id	INTO v_interval_id	FROM timespans	WHERE	timespan_id = v_timespan_id;

	RAISE NOTICE ''cal_update_tr: cal_item:%, activity:%, timespan:%, recurrence:%, interval:%'', 
			v_cal_item_id, v_activity_id, v_timespan_id, v_recurrence_id, v_interval_id;

	UPDATE	time_intervals
	SET	start_date = new.end_date,
		end_date = new.end_date
	WHERE	interval_id = v_interval_id;

	return new;
end;' language 'plpgsql';

create trigger im_projects_calendar_update_tr after insert or update
on im_projects for each row
execute procedure im_projects_calendar_update_tr ();



-- --------------------------------------------------------
-- Translation Tasks Trigger
-- --------------------------------------------------------

create or replace function im_trans_tasks_calendar_update_tr () returns trigger as '
declare
	v_cal_item_id		integer;	

	v_timespan_id		integer;
	v_interval_id		integer;
	v_calendar_id		integer;
	v_activity_id		integer;
	v_recurrence_id		integer;

	v_name			varchar;

	v_project_name		varchar;
	v_project_nr		varchar;
begin
	-- -------------- Skip if start or end date are null ------------
	IF new.end_date is null THEN return new; END IF;

	-- -------------- Check if the entry already exists ------------
	v_cal_item_id := null;

	SELECT	event_id
	INTO	v_cal_item_id
	FROM	acs_events
	WHERE	related_object_id = new.task_id
		and related_object_type = ''im_trans_task'';

	-- --------------------- Create entry if it isnt there -------------
	IF v_cal_item_id is null THEN
		v_timespan_id := timespan__new(new.end_date, new.end_date);
		v_activity_id := acs_activity__new(
			null, 
			new.task_name,
			'''',
			''f'', 
			'''', 
			''acs_activity'', now(), null, ''0.0.0.0'', null
		);

		SELECT	min(calendar_id)
		INTO 	v_calendar_id
		FROM	calendars
		WHERE	private_p = ''f'';

		v_recurrence_id := NULL;
		v_cal_item_id := cal_item__new (
			null,			-- cal_item_id
			v_calendar_id,		-- on_which_calendar
			new.task_name,		-- name
			'''',			-- description
			''f'',			-- html_p
			'''',			-- status_summary
			v_timespan_id,		-- timespan_id
			v_activity_id,		-- activity_id
			v_recurrence_id,	-- recurrence_id
			''cal_item'', null, now(), null, ''0.0.0.0''	
		);
	END IF;

	-- --------------------- Update the entry --------------------
	SELECT	activity_id	INTO v_activity_id	FROM acs_events	WHERE	event_id = v_cal_item_id;
	SELECT	timespan_id	INTO v_timespan_id	FROM acs_events	WHERE	event_id = v_cal_item_id;
	SELECT	recurrence_id	INTO v_recurrence_id	FROM acs_events	WHERE	event_id = v_cal_item_id;

	SELECT	project_name	INTO v_project_name	FROM im_projects WHERE	project_id = new.project_id;
	SELECT	project_nr	INTO v_project_nr	FROM im_projects WHERE	project_id = new.project_id;

	v_name := new.task_name || '' @ '' || v_project_nr || '' - '' || v_project_name;

	-- Update the event
	UPDATE	acs_events 
	SET	name = v_name,
		description = '''',
		related_object_id = new.task_id,
		related_object_type = ''im_trans_task'',
		related_link_url = ''/intranet-translation/trans-tasks/task-list?project_id=''||new.project_id,
		related_link_text = v_name,
		redirect_to_rel_link_p = ''t''
	WHERE	event_id = v_cal_item_id;

	-- Update the activity - same as event
	UPDATE	acs_activities
	SET	name = v_name,
		description = ''''
	WHERE	activity_id = v_activity_id;

	-- Update the timespan. Make sure there is only one interval
	-- in this timespan (there may be multiples)
	SELECT	interval_id	INTO v_interval_id	FROM timespans	WHERE	timespan_id = v_timespan_id;

	RAISE NOTICE ''cal_update_tr: cal_item:%, activity:%, timespan:%, recurrence:%, interval:%'', 
			v_cal_item_id, v_activity_id, v_timespan_id, v_recurrence_id, v_interval_id;

	UPDATE	time_intervals
	SET	start_date = new.end_date,
		end_date = new.end_date
	WHERE	interval_id = v_interval_id;

	return new;
end;' language 'plpgsql';


-- dont install trigger if there is not translation module installed
-- (upgrade from V3.1 project-consulting)
create or replace function inline_0 ()
returns integer as '
DECLARE
        v_count         integer;
BEGIN
    select count(*) into v_count from user_tab_columns
    where lower(table_name) = ''im_timesheet_tasks'' and lower(column_name) = ''project_id'';
    IF v_count = 0 THEN return 0; END IF;

	create trigger im_trans_tasks_calendar_update_tr after insert or update
	on im_trans_tasks for each row
	execute procedure im_trans_tasks_calendar_update_tr ();

    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- update im_trans_tasks set end_date = end_date;






-- --------------------------------------------------------
-- Forum Topics Trigger
-- --------------------------------------------------------

-- drop trigger im_forum_topics_calendar_update_tr on im_forum_topics;
-- drop function im_forum_topics_calendar_update_tr();

create or replace function im_forum_topics_calendar_update_tr () returns trigger as '
declare
	v_cal_item_id		integer;	

	v_timespan_id		integer;
	v_interval_id		integer;
	v_calendar_id		integer;
	v_activity_id		integer;
	v_recurrence_id		integer;

	v_name			varchar;
begin
	-- -------------- Skip if start or end date are null ------------
	IF new.due_date is null THEN return new; END IF;

	-- -------------- Check if the entry already exists ------------
	v_cal_item_id := null;

	SELECT	event_id
	INTO	v_cal_item_id
	FROM	acs_events
	WHERE	related_object_id = new.topic_id
		and related_object_type = ''im_forum_topic'';

	-- --------------------- Create entry if it isnt there -------------
	IF v_cal_item_id is null THEN
		v_timespan_id := timespan__new(new.due_date, new.due_date);
		v_activity_id := acs_activity__new(
			null, 
			new.subject,
			'''',
			''f'', 
			'''', 
			''acs_activity'', now(), null, ''0.0.0.0'', null
		);
	
		SELECT	min(calendar_id)
		INTO 	v_calendar_id
		FROM	calendars
		WHERE	private_p = ''f'';

		v_recurrence_id := NULL;
		v_cal_item_id := cal_item__new (
			null,			-- cal_item_id
			v_calendar_id,		-- on_which_calendar
			new.subject,		-- name
			new.message,		-- description
			''f'',			-- html_p
			'''',			-- status_summary
			v_timespan_id,		-- timespan_id
			v_activity_id,		-- activity_id
			v_recurrence_id,	-- recurrence_id
			''cal_item'', null, now(), null, ''0.0.0.0''	
		);
	END IF;

	-- --------------------- Update the entry --------------------
	SELECT	activity_id	INTO v_activity_id	FROM acs_events	WHERE	event_id = v_cal_item_id;
	SELECT	timespan_id	INTO v_timespan_id	FROM acs_events	WHERE	event_id = v_cal_item_id;
	SELECT	recurrence_id	INTO v_recurrence_id	FROM acs_events	WHERE	event_id = v_cal_item_id;

	v_name := new.subject || '' @ '' || coalesce(acs_object__name(new.object_id), '''');

	-- Update the event
	UPDATE	acs_events 
	SET	name = v_name,
		description = new.message,
		related_object_id = new.topic_id,
		related_link_url = ''/intranet-forum/view?topic_id='' || new.topic_id,
		related_link_text = v_name,
		redirect_to_rel_link_p = ''t''
	WHERE	event_id = v_cal_item_id;

	-- Update the activity - same as event
	UPDATE	acs_activities
	SET	name = v_name,
		description = new.message
	WHERE	activity_id = v_activity_id;

	-- Update the timespan. Make sure there is only one interval
	-- in this timespan (there may be multiples)
	SELECT	interval_id	INTO v_interval_id	FROM timespans	WHERE	timespan_id = v_timespan_id;

	RAISE NOTICE ''cal_update_tr: cal_item:%, activity:%, timespan:%, recurrence:%, interval:%'', 
			v_cal_item_id, v_activity_id, v_timespan_id, v_recurrence_id, v_interval_id;

	UPDATE	time_intervals
	SET	start_date = new.due_date,
		end_date = new.due_date
	WHERE	interval_id = v_interval_id;

	return new;
end;' language 'plpgsql';

create trigger im_forum_topics_calendar_update_tr after insert or update
on im_forum_topics for each row
execute procedure im_forum_topics_calendar_update_tr ();

update im_forum_topics set due_date = due_date;



---------------------------------------------------------
-- Calendar Component
--

-- Show the forum component in project page
--
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Home Calendar Component',	-- plugin_name
	'intranet-calendar',		-- package_name
	'left',				-- location
	'/intranet/index',		-- page_url
	null,				-- view_name
	-10,				-- sort_order
	'im_calendar_home_component',
	'lang::message::lookup "" intranet-calendar.Calendar "Calendar"'
);


-- Bug in OpenACS 5.3 calendar component(?)
update im_component_plugins
set location = 'none'
where plugin_name = 'Home Calendar Component';



---------------------------------------------------------
-- Setup the Calendar main menu entry
--

create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
	v_main_menu		integer;

        -- Groups
        v_employees             integer;
        v_accounting            integer;
        v_senman                integer;
        v_companies             integer;
        v_freelancers           integer;
        v_proman                integer;
        v_admins                integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_companies from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';

    select menu_id
    into v_main_menu
    from im_menus
    where label=''main'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-calendar'',      -- package_name
        ''calendar'',               -- label
        ''Calendar'',               -- name
        ''/calendar/'',    -- url
        74,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

-- /packages/intranet-funambol/sql/postgresql/intranet-funambol-create.sql
--
-- Copyright (c) 2003-2010 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-----------------------------------------------------------
-- Funambol
--
-- Funambol is a SyncMS server, allowing Outlook and various types
-- of mobile devices to sync with a server.
-- This package syncs ]po[ user information to the Funambol DB,
-- plus PIM information about contacts, tasks and calendar events.



---------------------------------------------------------------------
-- Changes to the Funambol data model
---------------------------------------------------------------------

-- Add "po_id" fields to fnbl_pim_calendar to link back to ]project-open[ objects

create or replace function inline_0 ()
returns integer as $$
DECLARE
	v_count		integer;
BEGIN
    SELECT count(*) INTO v_count FROM user_tab_columns
    WHERE lower(table_name) = 'fnbl_user' AND lower(column_name) = 'po_id';
    IF v_count = 0 THEN
	ALTER TABLE fnbl_user ADD COLUMN po_id integer;
    END IF;

    SELECT count(*) INTO v_count FROM user_tab_columns
    WHERE lower(table_name) = 'fnbl_pim_calendar' AND lower(column_name) = 'po_id';
    IF v_count = 0 THEN
	ALTER TABLE fnbl_pim_calendar ADD COLUMN po_id integer;
    END IF;


    RETURN 0;
END;$$ language 'plpgsql';
select inline_0();
drop function inline_0();



---------------------------------------------------------------------
-- Auxillary
---------------------------------------------------------------------

create or replace function fnbl_next_id (varchar)
returns bigint as $$
DECLARE
	p_counter	alias for $1;
	v_count		bigint;
BEGIN
    select counter into v_count from fnbl_id where idspace = p_counter for update;
    update fnbl_id set counter = v_count + 1 where idspace = p_counter;

    RETURN v_count;
END;$$ language 'plpgsql';


---------------------------------------------------------------------
-- Meeting Status vs. ]po[ Ticket Status
---------------------------------------------------------------------

-- 0: Not started ->	30000:Open 
-- 4: Processing ->	30020:Executing
-- 5: Done ->		30096:Resolved
-- 8: Suspended ->	30026:Waiting for Other

create or replace function fnbl_to_po_task_status (integer)
returns integer as $$
DECLARE
	p_fnbl_meeting_status	alias for $1;
	v_status_id		integer;
BEGIN
	v_status_id := 30000;
	IF p_fnbl_meeting_status = 0 THEN v_status_id := 30000; END IF;
	IF p_fnbl_meeting_status = 4 THEN v_status_id := 30020; END IF;
	IF p_fnbl_meeting_status = 5 THEN v_status_id := 30096; END IF;
	IF p_fnbl_meeting_status = 8 THEN v_status_id := 30026; END IF;

	RAISE NOTICE 'fnbl_to_po_task_status(%) -> %', p_fnbl_meeting_status, v_status_id;

	RETURN v_status_id;
END;$$ language 'plpgsql';

create or replace function fnbl_from_po_task_status (integer)
returns integer as $$
DECLARE
	p_po_status_id	alias for $1;
	v_status	integer;
BEGIN
	-- Default: Processing
	v_status := 4;

	-- Open -> Processing
	IF p_po_status_id in (select child_id from im_category_hierarchy where parent_id = 30000 union select 30000) THEN 
		v_status := 4; 
	END IF;

	-- Closed -> Done
	IF p_po_status_id in (select child_id from im_category_hierarchy where parent_id = 30001 union select 30001) THEN 
		v_status := 5; 
	END IF;

	RAISE NOTICE 'fnbl_from_po_task_status(%) -> %', p_po_status_id, v_status;

	RETURN v_status;
END;$$ language 'plpgsql';


---------------------------------------------------------------------
-- User Accounts
---------------------------------------------------------------------

create or replace function fnbl_export_user_accounts ()
returns integer as $$
DECLARE
        row			RECORD;
	v_counter		integer;
	v_exists_p		integer;
BEGIN
    RAISE NOTICE 'fnbl_export_user_accounts: started';
    v_counter := 0;

    -- ToDo: Only Employees
    FOR row IN
        select	u.*
	from	cc_users u
	where	lower(u.username) not in ('admin', 'guest') AND
		u.user_id in (select member_id from group_distinct_member_map where group_id in (select group_id from groups where group_name = 'Employees'))
	order by user_id
    LOOP
	v_counter := v_counter + 1;

	------------------------ Insert Basic User Information ---------------------------------------------
	select count(*) into v_exists_p from fnbl_user
	where username = lower(trim(row.username));

	IF v_exists_p = 0 THEN
		insert into fnbl_user (username, password, email, first_name, last_name, po_id)
		values (lower(trim(row.username)), 'secret', lower(row.email), row.first_names, row.last_name, row.user_id);
	END IF;

	-- ToDo: replace the default "sa" password with a random pwd, and write the new password
	-- to the "persons" table so that the user can consult his password
	update fnbl_user set
		username = lower(trim(row.username)),
		password = 'lltUbBHM7oA=',
		email = lower(row.email),
		first_name = row.first_names,
		last_name = row.last_name
	where	po_id = row.user_id;

	------------------------ Insert User Roles ---------------------------------------------
	select count(*) into v_exists_p from fnbl_user_role
	where username = lower(trim(row.username));
	IF v_exists_p = 0 THEN
		insert into fnbl_user_role (username, role)
		values (lower(trim(row.username)), 'sync_user');
	END IF;
    END LOOP;

    RAISE NOTICE 'fnbl_export_user_accounts: updated % accounts.', v_counter;

    RETURN 0;
END;$$ language 'plpgsql';
-- select fnbl_export_user_accounts();




---------------------------------------------------------------------
-- Tickets
---------------------------------------------------------------------

create or replace function fnbl_export_tickets (integer)
returns integer as $$
DECLARE
	p_user_id		ALIAS for $1;

        row			RECORD;
	v_counter		integer;
	v_exists_p		integer;
	v_fnbl_id		bigint;
	v_now_seconds		bigint;
	v_last_update		bigint;
	v_username		varchar;
	v_percent_complete	integer;
	v_meeting_status	integer;
	v_status_id		integer;
	v_priority		integer;
BEGIN
    v_counter := 0;

    -- Get the username
    SELECT	lower(trim(username)) INTO v_username
    FROM	users WHERE user_id = p_user_id;
    -- RAISE NOTICE 'fnbl_export_tickets: user_id=%, username=%', p_user_id, v_username;

    -- Get the current time.
    -- Check if there is a newer entry in the PIM DB. This shouldn't be the case,
    -- because this is the latest update. However, clocks may be out of sync...
    SELECT (extract(epoch from now()) * 1000.0)::bigint INTO v_now_seconds;
    SELECT 1+max(last_update) INTO v_last_update FROM fnbl_pim_calendar;
    IF v_now_seconds > v_last_update THEN v_last_update := v_now_seconds; END IF;

    FOR row IN
	-- Extract im_ticket objects assigned to the current user
        SELECT	
		p.project_id as task_id,
		(extract(epoch from o.last_modified) * 1000.0)::bigint as task_last_modified,
		t.ticket_status_id as task_status_id,
		p.start_date as task_start_date,
		p.end_date as task_end_date,
		p.project_name as task_name,
		p.percent_completed as task_percent_completed
	FROM
		im_tickets t,
		im_projects p,
		acs_objects o,
		acs_rels r,
		im_biz_object_members bom
	WHERE	
		t.ticket_id = p.project_id AND
		t.ticket_id = o.object_id AND
		-- Allow all states to be synced, so that a user can "re-animate" an already closed ticket
		-- t.ticket_status_id in (select child_id from im_category_hierarchy where parent_id = 30000 UNION select 30000) AND
		r.rel_id = bom.rel_id AND
		r.object_id_one = p.project_id AND
		r.object_id_two = p_user_id
	ORDER BY
		t.ticket_id
    LOOP
	v_counter := v_counter + 1;

	------------------------ Insert New Record ---------------------------------------------
	SELECT	id INTO v_fnbl_id FROM fnbl_pim_calendar
	WHERE	po_id = row.task_id AND userid = v_username;

	IF v_fnbl_id is NULL THEN
		RAISE NOTICE 'fnbl_export_tickets: INSERT new record into Funambol';
		-- New Task in ]po[: Create in funambol
		v_fnbl_id = fnbl_next_id('pim.id');
		insert into fnbl_pim_calendar (id, last_update) values (v_fnbl_id, 0);
	END IF;


	------------------------ Sync ---------------------------------------------
	-- Get the info from Funambol
	SELECT	last_update, percent_complete, meeting_status
	INTO	v_last_update, v_percent_complete, v_meeting_status
	FROM	fnbl_pim_calendar
	WHERE	id = v_fnbl_id;

	RAISE NOTICE 'fnbl_export_tickets: username=%, po_id=%, Funambol=%, ]po[=%', v_username, row.task_id, v_last_update, row.task_last_modified;


	-- Funambol is more recent: Update ]po[ task state
	IF v_last_update > row.task_last_modified THEN

		RAISE NOTICE 'fnbl_export_tickets: Funambol more recent: %: fnbl_id=%, task_id=%', v_username, v_fnbl_id, row.task_id;

		UPDATE im_projects SET
			percent_completed = v_percent_complete
		WHERE	project_id = row.task_id;

		UPDATE im_tickets SET
			ticket_status_id = fnbl_to_po_task_status(v_meeting_status)
		WHERE	ticket_id = row.task_id;

		UPDATE acs_objects SET
			last_modified = timestamp with time zone 'epoch' + (v_last_update / 1000.0) * '1 second'::interval
		WHERE	object_id = row.task_id;
	END IF;

	-- ]po[ is more recent
	IF row.task_last_modified > v_last_update THEN
		RAISE NOTICE 'fnbl_export_tickets: ]po[ more recent: %, fnbl_id=%, task_id=%', v_username, v_fnbl_id, row.task_id;
		UPDATE fnbl_pim_calendar SET
			userid = v_username,
			last_update = row.task_last_modified,
			status = 'N',
			type = 2,
			busy_status = NULL,
			categories = '',
			duration = 0,
			dstart = row.task_start_date,
			dend = row.task_end_date,
			folder = 'DEFAULT_FOLDER',
			importance = 5,
			meeting_status = fnbl_from_po_task_status(row.task_status_id),
			reminder_time = row.task_end_date,
			reminder = 1,
			reminder_options = 0,
			reminder_repeat_count = 0,
			sensitivity = 0,
			subject = row.task_name,
			body = row.task_name,
			rec_type = -1,
			rec_interval = 0,
			rec_month_of_year = 0,
			rec_day_of_month = 0,
			rec_instance = 0,
			rec_no_end_date = '0',
			rec_occurrences = -1,
			percent_complete = coalesce(row.task_percent_completed, 0)::smallint,
			po_id = row.task_id
		WHERE	id = v_fnbl_id;
	END IF;

    END LOOP;

    -- RAISE NOTICE 'fnbl_export_tickets: user_id=%: updated % tasks', p_user_id, v_counter;
    RETURN 0;
END;$$ language 'plpgsql';
-- select fnbl_export_tickets();




---------------------------------------------------------------------
-- Run Synchronization
---------------------------------------------------------------------

create or replace function fnbl_sync ()
returns integer as $$
DECLARE
    row		RECORD;
BEGIN
    PERFORM fnbl_export_user_accounts();

    FOR row IN
	select	fu.*
	from	fnbl_user fu
	where	fu.po_id is not null
    LOOP
	PERFORM fnbl_export_tickets(row.po_id);
    END LOOP;

    RETURN 0;
END;$$ language 'plpgsql';
select fnbl_export();



-- upgrade-4.0.2.0.1-4.0.2.0.2.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-4.0.2.0.1-4.0.2.0.2.sql','');


-----------------------------------------------------------
-- 
-----------------------------------------------------------

-- Update the old im_project trigger to exclude tickets

create or replace function im_projects_tsearch ()
returns trigger as '
declare
	v_string	varchar;
	v_string2	varchar;
	v_object_type	varchar;
begin
	select  coalesce(project_name, '''') || '' '' ||
		coalesce(project_nr, '''') || '' '' ||
		coalesce(project_path, '''') || '' '' ||
		coalesce(description, '''') || '' '' ||
		coalesce(note, ''''),
		o.object_type
	into    v_string, v_object_type
	from    im_projects p,
		acs_objects o
	where   p.project_id = new.project_id and
		p.project_id = o.object_id;

	-- Skip if this is a ticket. There is a special trigger for tickets.
	-- im_timesheet_task is still handled as a project.
	IF ''im_ticket'' = v_object_type THEN return new; END IF;

	v_string2 := '''';
	IF column_exists(''im_projects'', ''company_project_nr'') THEN
		select  coalesce(company_project_nr, '''') || '' '' ||
			coalesce(final_company, '''')
		into    v_string2
		from    im_projects
		where   project_id = new.project_id;
		v_string := v_string || '' '' || v_string2;
	END IF;

	perform im_search_update(new.project_id, ''im_project'', new.project_id, v_string);

	return new;
end;' language 'plpgsql';



-----------------------------------------------------------
-- Full-Text Search for Tickets
-----------------------------------------------------------


create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select	count(*) into v_count from im_search_object_types
	where	object_type_id = 8;
	IF 0 != v_count THEN return 0; END IF;

	insert into im_search_object_types values (8, ''im_ticket'', 0.7);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function im_tickets_tsearch ()
returns trigger as '
declare
	v_string	varchar;
begin
	select  coalesce(p.project_name, '''') || '' '' ||
		coalesce(p.project_nr, '''') || '' '' ||
		coalesce(p.project_path, '''') || '' '' ||
		coalesce(p.description, '''') || '' '' ||
		coalesce(p.note, '''') || '' '' ||
		coalesce(t.ticket_note, '''') || '' '' ||
		coalesce(t.ticket_description, '''')
	into    v_string
	from    im_tickets t,
		im_projects p
	where   p.project_id = new.ticket_id and
		t.ticket_id = p.project_id;

	perform im_search_update(new.ticket_id, ''im_ticket'', new.ticket_id, v_string);

	return new;
end;' language 'plpgsql';




create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select	count(*) into v_count from pg_trigger
	where	lower(tgname) = ''im_tickets_tsearch_tr'';
	IF 0 != v_count THEN return 1; END IF;

	CREATE TRIGGER im_tickets_tsearch_tr
	AFTER INSERT or UPDATE
	ON im_tickets
	FOR EACH ROW
	EXECUTE PROCEDURE im_tickets_tsearch();

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



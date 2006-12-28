
-- drop trigger im_projects_update_tr on im_projects;
-- drop function im_projects_update_tr();

create function im_projects_update_tr () returns trigger as '
declare
	v_parent_sk		varbit default null;
	v_max_child_sortkey	varbit;
	v_old_parent_length	integer;
	v_timespan_id		integer;
	v_calendar_id		integer;
	v_activity_id		integer;
	v_recurrence_id		integer;
	v_cal_item_id		integer;
begin
	RAISE NOTICE ''im_projects_update_tr:'';

	if new.project_id = old.project_id and ((new.parent_id = old.parent_id)
	   or (new.parent_id is null and old.parent_id is null)) then
	   return new;
	end if;
	v_old_parent_length := length(new.tree_sortkey) + 1;
	if new.parent_id is null then
	    v_parent_sk := int_to_tree_key(new.project_id+1000);
	else
	    SELECT tree_sortkey, tree_increment_key(max_child_sortkey)
	    INTO v_parent_sk, v_max_child_sortkey
	    FROM im_projects WHERE project_id = new.parent_id FOR UPDATE;

	    UPDATE im_projects SET max_child_sortkey = v_max_child_sortkey
	    WHERE project_id = new.parent_id;

	    v_parent_sk := v_parent_sk || v_max_child_sortkey;
	end if;

	UPDATE im_projects
	SET tree_sortkey = v_parent_sk || substring(tree_sortkey, v_old_parent_length)
	WHERE tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);

	return new;
end;' language 'plpgsql';

-- create trigger im_projects_update_tr after update
-- on im_projects for each row
-- execute procedure im_projects_update_tr ();





drop trigger im_projects_calendar_update_tr on im_projects;
drop function im_projects_calendar_update_tr();

create function im_projects_calendar_update_tr () returns trigger as '
declare
	v_parent_sk		varbit default null;
	v_max_child_sortkey	varbit;
	v_old_parent_length	integer;
	v_timespan_id		integer;
	v_calendar_id		integer;
	v_activity_id		integer;
	v_recurrence_id		integer;
	v_cal_item_id		integer;
begin
	RAISE NOTICE ''im_projects_calendar_update_tr:'';

	v_timespan_id := timespan__new(new.start_date, new.end_date);
	RAISE NOTICE ''im_projects_calendar_update_tr: timespan_id=%'', v_timespan_id;

	v_activity_id := acs_activity__new(
		null, new.project_name,	new.description, ''f'', '''', 
		''acs_activity'', now(), null, ''0.0.0.0'', null
	);
	RAISE NOTICE ''im_projects_calendar_update_tr: v_activity_id=%'', v_activity_id;

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

	return new;
end;' language 'plpgsql';

create trigger im_projects_calendar_update_tr after insert or update
on im_projects for each row
execute procedure im_projects_calendar_update_tr ();

update im_projects set start_date = start_date::date+1 where project_nr = '2006_0051';
select count(*) from acs_events;




update im_projects set start_date = start_date::date+1 where project_nr = '2006_0051';
select count(*) from acs_events;

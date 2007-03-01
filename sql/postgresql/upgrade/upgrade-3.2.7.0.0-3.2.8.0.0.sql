-- upgrade-3.2.7.0.0-3.2.8.0.0.sql


----------------------------------------------------------------
-- percentage column for im_biz_object_members


create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = ''im_biz_object_members'' and lower(column_name) = ''percentage'';
        IF 0 != v_count THEN return 0; END IF;

	ALTER TABLE im_biz_object_members ADD column percentage numeric(8,2);
	ALTER TABLE im_biz_object_members ALTER column percentage set default 100;

        return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





create or replace function im_day_enumerator (
        date, date
) returns setof date as '
declare
        p_start_date            alias for $1;
        p_end_date              alias for $2;
        v_date                  date;
BEGIN
        v_date := p_start_date;
        WHILE (v_date < p_end_date) LOOP
                RETURN NEXT v_date;
                v_date := v_date + 1;
        END LOOP;
        RETURN;
end;' language 'plpgsql';






create or replace function im_day_enumerator_weekdays (
        date, date
) returns setof date as '
declare
        p_start_date            alias for $1;
        p_end_date              alias for $2;
        v_date                  date;
        v_weekday               integer;
BEGIN
        v_date := p_start_date;
        WHILE (v_date < p_end_date) LOOP

                v_weekday := to_char(v_date, ''D'');
                IF v_weekday != 1 AND v_weekday != 7 THEN
                        RETURN NEXT v_date;
                END IF;
                v_date := v_date + 1;
        END LOOP;
        RETURN;
end;' language 'plpgsql';



-- Delete the customer_project_nr DynField.
-- The DynField has become part of the static Project fields.

delete	
from im_dynfield_attributes
where	acs_attribute_id in (
		select	attribute_id 
		from
			acs_attributes 
		where 
			attribute_name = 'company_project_nr' 
			and object_type = 'im_project'
	)
;




SELECT  im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
	'Task Members',			-- plugin_name
	'intranet',			-- package_name
	'right',			-- location
	'/intranet-timesheet2-tasks/new',	-- page_url
	null,				-- view_name	
	20,				-- sort_order
	'im_table_with_title "[_ intranet-core.Task_Members]" [im_group_member_component $task_id $current_user_id $user_admin_p $return_url "" "" 1 ]'			-- component_tcl
    );




-- Allow for "Full-Member" membership of a timesheet-task
insert into im_biz_object_role_map values ('im_timesheet_task',85,1300);



-- Create an index on tree_sortkey to speed up child queries
create index im_project_treesort_idx on im_projects(tree_sortkey);



-- /packages/intranet-bug-tracker/sql/postgresql/intranet-bug-tracker-create.sql
--
-- Copyright (c) 2003-2006 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-----------------------------------------------------------
-- ]po[ Interface to OpenACS Bug-Tracker
--
-- There are two areas where we are interfacing with BT:
--
-- - We define a new type of "Bug Tracker" project that
--   will serve as a container for BT tasks
--
-- - Each BT task will get an 1:1 link to a BT bug, so that
--   we can display the bug instead of the normal task page

-- Categories
-- 4300-4499    Intranet Bug-Tracker


-- Add a link from Timesheet Tasks to a BT-Bug:
--

-- alter table im_timesheet_tasks drop column bt_bug_id;
alter table im_timesheet_tasks
	add bt_bug_id integer 
	constraint im_times_tasks_bt_bug_fk 
	references bt_bugs;




alter table bt_bugs add bug_container_project_id integer references im_projects;



-- Create a new BT Container Project Type


create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from im_categories
	where category = ''Bug Tracker Container'';
        IF 0 != v_count THEN return 0; END IF;

	INSERT INTO im_categories ( category_id, category, category_type) values
	(4300, ''Bug Tracker Container'', ''Intranet Project Type'');
	INSERT INTO im_categories ( category_id, category, category_type) values
	(4305, ''Bug Tracker Task'', ''Intranet Project Type'');

	insert into im_category_hierarchy values (
		(select category_id 
		from im_categories 
		where category = ''Consulting Project''),
		4300
	);

	insert into im_category_hierarchy values (
		(select category_id 
		from im_categories 
		where category = ''Consulting Project''),
		4305
	);

	return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-----------------------------------------------------------


-- Setup the "Bug-Tracker" main menu entry
--

create or replace function inline_0 ()
returns integer as '
declare
        v_menu                  integer;	v_main_menu		integer;
        v_employees             integer;        v_accounting            integer;
        v_senman                integer;        v_companies             integer;
        v_freelancers           integer;        v_proman                integer;
        v_admins                integer;	v_reg_users		integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_companies from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';
    select group_id into v_reg_users from groups where group_name = ''Registered Users'';

    select menu_id into v_main_menu from im_menus where label=''main'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-bug-tracker'',     -- package_name
        ''bug_tracker'',              -- label
        ''Bugs'',              -- name
        ''/bug-tracker/'',   -- url
        15,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_companies, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_reg_users, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-----------------------------------------------------------	

-- Bug Creation Component on HomePage
--
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Home Bug-Tracker Component',	-- plugin_name
        'intranet-bug-tracker',		-- package_name
        'right',			-- location
        '/intranet/index',		-- page_url
        null,                           -- view_name
        22,                             -- sort_order
	'im_bug_tracker_container_component',
	'lang::message::lookup "" intranet-bug-tracker.Bug_Tracker_Component "Bug Tracker Component"'
);



-- Create a new DynField widget for bt_projects
select im_dynfield_widget__new (
	null,				-- widget_id
	'im_dynfield_widget',   	-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'bt_project',			-- widget_name
	'#intranet-bug-tracker.BT_Product#',	-- pretty_name
	'#intranet-bug-tracker.BT_Product#',	-- pretty_plural
	10007,				-- storage_type_id
	'integer',			-- acs_datatype
	'generic_sql',			-- widget
	'integer',			-- sql_datatype
	'{custom {sql "select project_id, description from bt_projects"}}' -- parameters
);




-- Add BT information to im_projects
--
create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name	varchar;	v_attrib_pretty		varchar;
	v_table		varchar;	v_object		varchar;
	v_datatype	varchar;	v_acs_attrib_id		integer;
	v_attrib_id	integer;	v_count			integer;
	v_widget	varchar;
begin
	v_attrib_name := ''bt_project_id'';
	v_attrib_pretty := ''BT Product'';
	v_object := ''im_project'';
	v_table := ''im_projects'';
	v_datatype := ''integer''; -- (boolean,date,integer,keyword,number,string,text)
	v_widget := ''bt_project'';
	select count(*) into v_count from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = v_table and lower(column_name) = v_attrib_name;
	IF v_count = 0 THEN
		alter table im_projects 
			add bt_project_id integer 
			constraint im_project_bt_project_fk 
			references bt_projects;
	END IF;
	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object, v_attrib_name,	-- object_type, attribute_name
		v_datatype, v_attrib_pretty, 	-- datatype, pretty_name
		v_attrib_pretty, v_table,	-- pretty_plural, table_name
		NULL, NULL, 			-- column_name, default_value
		''0'', ''1'',			-- min_n_values, max_n_values
		NULL, NULL, NULL 		-- sort_order, storage, static_p
	);
	v_attrib_id := acs_object__new (null,''im_dynfield_attribute'',now(), null, null, null);
	insert into im_dynfield_attributes (attribute_id, acs_attribute_id, widget_name, deprecated_p) 
	values (v_attrib_id, v_acs_attrib_id, v_widget, ''f'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- Create a new DynField widget for bt_components
select im_dynfield_widget__new (
	null,				-- widget_id
	'im_dynfield_widget',   	-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'bt_component',		-- widget_name
	'#intranet-bug-tracker.BT_Component#',	-- pretty_name
	'#intranet-bug-tracker.BT_Component#',	-- pretty_plural
	10007,				-- storage_type_id
	'integer',			-- acs_datatype
	'generic_sql',			-- widget
	'integer',			-- sql_datatype
	'{custom {sql "select component_id, component_name from bt_components"}}' -- parameters
);


-- Add BT Component default to im_projects
--
create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name	varchar;	v_attrib_pretty		varchar;
	v_table		varchar;	v_object		varchar;
	v_datatype	varchar;	v_acs_attrib_id		integer;
	v_attrib_id	integer;	v_count			integer;
	v_widget	varchar;
begin
	v_attrib_name := ''bt_component_id'';
	v_attrib_pretty := ''BT Component'';
	v_object := ''im_project'';
	v_table := ''im_projects'';
	v_datatype := ''integer''; -- (boolean,date,integer,keyword,number,string,text)
	v_widget := ''bt_component'';
	select count(*) into v_count from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	select count(*) into v_count from user_tab_columns
	where lower(table_name) = v_table and lower(column_name) = v_attrib_name;
	IF v_count = 0 THEN
		alter table im_projects 
			add bt_component_id integer 
			constraint im_project_bt_comp_fk 
			references bt_components;
	END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object, v_attrib_name,	-- object_type, attribute_name
		v_datatype, v_attrib_pretty, 	-- datatype, pretty_name
		v_attrib_pretty, v_table,	-- pretty_plural, table_name
		NULL, NULL, 			-- column_name, default_value
		''0'', ''1'',			-- min_n_values, max_n_values
		NULL, NULL, NULL 		-- sort_order, storage, static_p
	);
	v_attrib_id := acs_object__new (null,''im_dynfield_attribute'',now(), null, null, null);
	insert into im_dynfield_attributes (attribute_id, acs_attribute_id, widget_name, deprecated_p) 
	values (v_attrib_id, v_acs_attrib_id, v_widget, ''f'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- Create a new DynField widget for bt_versions
select im_dynfield_widget__new (
        null,                           -- widget_id
        'im_dynfield_widget',           -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'bt_version',                	-- widget_name
        '#intranet-bug-tracker.BT_Version#',	-- pretty_name
        '#intranet-bug-tracker.BT_Version#',	-- pretty_plural
        10007,                          -- storage_type_id
        'integer',                      -- acs_datatype
        'generic_sql',                  -- widget
        'integer',                      -- sql_datatype
        '{custom {sql "select version_id, description from bt_versions"}}' -- parameters
);


-- Add BT Component default to im_projects
--
create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name	varchar;	v_attrib_pretty		varchar;
	v_table		varchar;	v_object		varchar;
	v_datatype	varchar;	v_acs_attrib_id		integer;
	v_attrib_id	integer;	v_count			integer;
	v_widget	varchar;
begin
	v_attrib_name := ''bt_found_in_version_id'';
	v_attrib_pretty := ''BT Found in Version'';
	v_object := ''im_project'';
	v_table := ''im_projects'';
	v_datatype := ''integer''; -- (boolean,date,integer,keyword,number,string,text)
	v_widget := ''bt_version'';
	select count(*) into v_count from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = v_table and lower(column_name) = v_attrib_name;
	IF v_count = 0 THEN
		alter table im_projects 
			add bt_found_in_version_id integer 
			constraint im_project_bt_found_ver_fk 
			references bt_versions;
	END IF;
	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object, v_attrib_name,	-- object_type, attribute_name
		v_datatype, v_attrib_pretty, 	-- datatype, pretty_name
		v_attrib_pretty, v_table,	-- pretty_plural, table_name
		NULL, NULL, 			-- column_name, default_value
		''0'', ''1'',			-- min_n_values, max_n_values
		NULL, NULL, NULL 		-- sort_order, storage, static_p
	);
	v_attrib_id := acs_object__new (null,''im_dynfield_attribute'',now(), null, null, null);
	insert into im_dynfield_attributes (attribute_id, acs_attribute_id, widget_name, deprecated_p) 
	values (v_attrib_id, v_acs_attrib_id, v_widget, ''f'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- Add BT Component default to im_projects
--
create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name	varchar;	v_attrib_pretty		varchar;
	v_table		varchar;	v_object		varchar;
	v_datatype	varchar;	v_acs_attrib_id		integer;
	v_attrib_id	integer;	v_count			integer;
	v_widget	varchar;
begin
	v_attrib_name := ''bt_fix_for_version_id'';
	v_attrib_pretty := ''BT Fix for Version'';
	v_object := ''im_project'';
	v_table := ''im_projects'';
	v_datatype := ''integer''; -- (boolean,date,integer,keyword,number,string,text)
	v_widget := ''bt_version'';
	select count(*) into v_count from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = v_table and lower(column_name) = v_attrib_name;
	IF v_count = 0 THEN
		alter table im_projects 
			add bt_fix_for_version_id integer 
			constraint im_project_bt_fix_for_ver_fk 
			references bt_versions;
	END IF;
	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object, v_attrib_name,	-- object_type, attribute_name
		v_datatype, v_attrib_pretty, 	-- datatype, pretty_name
		v_attrib_pretty, v_table,	-- pretty_plural, table_name
		NULL, NULL, 			-- column_name, default_value
		''0'', ''1'',			-- min_n_values, max_n_values
		NULL, NULL, NULL 		-- sort_order, storage, static_p
	);
	v_attrib_id := acs_object__new (null,''im_dynfield_attribute'',now(), null, null, null);
	insert into im_dynfield_attributes (attribute_id, acs_attribute_id, widget_name, deprecated_p) 
	values (v_attrib_id, v_acs_attrib_id, v_widget, ''f'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Bug List Component',		-- plugin_name
        'intranet-bug-tracker',		-- package_name
        'left',				-- location
        '/intranet/projects/view',	-- page_url
        null,                           -- view_name
        22,                             -- sort_order
	'im_bug_tracker_list_component $project_id',
	'lang::message::lookup "" intranet-bug-tracker.Bug_Tracker_Component "Bug Tracker Component"'
);


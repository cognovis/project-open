
-------------------------------------------------------------
-- Updates to upgrade to the "unified" V3.2 model where
-- Task is a subclass of Project.
-------------------------------------------------------------

-- Drop the generic uniqueness constraint on project_nr.
alter table im_projects drop constraint im_projects_nr_un;

-- Dont allow the same project_nr  for the same company+level
alter table im_projects add
        constraint im_projects_nr_un
        unique(project_nr, company_id, parent_id);


-- Add a new category for the project_type.
-- Puff, difficult to find one while maintaining compatible
-- the the fixed IDs from ACS 3.4 Intranet...
--
SELECT im_category_new(100, 'Task', 'Intranet Project Type');


-------------------------------------------------------------
-- Add a "sort order" field to Projects
--


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*)	into v_count from user_tab_columns
	where table_name = ''IM_PROJECTS'' and column_name = ''SORT_ORDER'';
	if v_count > 0 then return 0; end if;

	alter table im_projects add sort_order integer;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-------------------------------------------------------------
-- Add a "title_tcl" field to Components
--
create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*)	into v_count from user_tab_columns
	where table_name = ''IM_COMPONENT_PLUGINS'' and column_name = ''TITLE_TCL'';
	if v_count > 0 then return 0; end if;

	alter table im_component_plugins add title_tcl text;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-------------------------------------------------------------
-- Set the default value for title_tcl as the localization
-- of the package name
update im_component_plugins 
set title_tcl = 
	'lang::message::lookup "" "' || package_name || '.' || 
	plugin_name || '" "' || plugin_name || '"'
where title_tcl is null;


-------------------------------------------------------------
-- Manually set some components title_tcl

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Offices "Offices"' 
where plugin_name = 'Company Offices';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Project_Members "Project Members"' 
where plugin_name = 'Project Members';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Recent_Registrations "Recent Registrations"' 
where plugin_name = 'Recent Registrations';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Members "Members"' 
where plugin_name = 'Office Members';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-wiki.Project_Wiki "Project_Wiki"' 
where plugin_name = 'Project Wiki Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Home_Page_Help "Home Page Help"' 
where plugin_name = 'Home Page Help Blurb';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-wiki.HomeWiki "Home Wiki"' 
where plugin_name = 'Home Wiki Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-timesheet2-tasks.Timesheet_Tasks "Timesheet Tasks"' 
where plugin_name = 'Project Timesheet Tasks';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-timesheet2-invoices.Price_List "Price List"' 
where plugin_name = 'Company Timesheet Prices';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-hr.Employee_Information "Employee Information"' 
where plugin_name = 'User Employee Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-ganttproject.Scheduling "Scheduling"' 
where plugin_name = 'Project GanttProject Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Offices "Offices"' 
where plugin_name = 'User Offices';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-cost.Finance_Summary "Finance Summary"' 
where plugin_name = 'Project Finance Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-filestorage.Filestorage "Filestorage"'
where plugin_name = 'Home Filestorage Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-filestorage.Filestorage "Filestorage"' 
where plugin_name = 'Users Filestorage Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-timesheet2.Timesheet "Timesheet"' 
where plugin_name = 'Project Timesheet Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-filestorage.Sales_Filestorage "Sales Filestorage"' 
where plugin_name = 'Project Sales Filestorage Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-filestorage.Filestorage "Filestorage"' 
where plugin_name = 'Project Filestorage Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-cost "Finance"' 
where plugin_name = 'Project Cost Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Projects "Projects"' 
where plugin_name = 'Home Page Project Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-core.Random_Portrait "Random Portrait"' 
where plugin_name = 'Home Random Portrait';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-forum.Forum "Forum"' 
where plugin_name = 'Home Forum Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-wiki.User_Wiki "User Wiki"' 
where plugin_name = 'User Wiki Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-wiki.Office_Wiki "Office Wiki"' 
where plugin_name = 'Office Wiki Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-timesheet.Timesheet "Timesheet"' 
where plugin_name = 'Home Timesheet Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-cost.Finance_Summary "Finance Summary"' 
where plugin_name = 'Project Finance Summary Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-security-update-client.Security_Updates "Security Updates"' 
where plugin_name = 'Security Update Client Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-forum.Forum "Forum"' 
where plugin_name = 'Project Forum Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-filestorage.Filestorage "Filestorage"' 
where plugin_name = 'Companies Filestorage Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-cost.Finance "Finance"' 
where plugin_name = 'Company Cost Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-forum.Forum "Forum"' 
where plugin_name = 'Companies Forum Component';

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-wiki.Company_Wiki "Company Wiki"' 
where plugin_name = 'Company Wiki Component';


-------------------------------------------------------------
-- Update some components to remove the "im_table_with_title"

update im_component_plugins set 
component_tcl = 'im_forum_component -user_id $user_id -forum_object_id 0 -current_page_url $current_url -return_url $return_url -export_var_list [list forum_start_idx forum_order_by forum_how_many forum_view_name ] -forum_type home -view_name [im_opt_val forum_view_name] -forum_order_by [im_opt_val forum_order_by] -start_idx [im_opt_val forum_start_idx] -restrict_to_mine_p t -restrict_to_new_topics 1',
title_tcl = 'im_forum_create_bar "<B>[_ intranet-forum.Forum_Items]<B>" 0 $return_url'
where plugin_name = 'Home Forum Component';


update im_component_plugins set
component_tcl = 'im_forum_component -user_id $user_id -forum_object_id $project_id -current_page_url $current_url -return_url $return_url -forum_type "project" -export_var_list [list project_id forum_start_idx forum_order_by forum_how_many forum_view_name] -view_name [im_opt_val forum_view_name] -forum_order_by [im_opt_val forum_order_by] -start_idx [im_opt_val forum_start_idx] -restrict_to_mine_p "f" -restrict_to_new_topics 0',
title_tcl = 'im_forum_create_bar "<B>[_ intranet-forum.Forum_Items]<B>" $project_id $return_url'
where plugin_name = 'Project Forum Component';


update im_component_plugins set
component_tcl = 'im_forum_component -user_id $user_id -forum_object_id $company_id -current_page_url $current_url -return_url $return_url -export_var_list [list company_id forum_start_idx forum_order_by forum_how_many forum_view_name ] -forum_type company -view_name [im_opt_val forum_view_name] -forum_order_by [im_opt_val forum_order_by] -restrict_to_mine_p "f" -restrict_to_new_topics 0',
title_tcl = 'im_forum_create_bar "<B>[_ intranet-forum.Forum_Items]<B>" $company_id $return_url'
where plugin_name = 'Companies Forum Component';


update im_component_plugins set
component_tcl = 'im_timesheet_project_component $user_id $project_id'
where plugin_name = 'Project Timesheet Component';


update im_component_plugins set
component_tcl = 'im_timesheet_home_component $user_id'
where plugin_name = 'Home Timesheet Component';

update im_component_plugins set
component_tcl = 'im_group_member_component $project_id $current_user_id $user_admin_p $return_url "" "" 1'
where plugin_name = 'Project Members';


update im_component_plugins set
component_tcl = 'im_office_user_component $current_user_id $user_id'
where plugin_name = 'User Offices';


update im_component_plugins set
component_tcl = 'im_office_company_component $user_id $company_id'
where plugin_name = 'Company Offices';


update im_component_plugins set
component_tcl = 'im_group_member_component $office_id $user_id $admin $return_url "" "" 1'
where plugin_name = 'Office Members';





-------------------------------------------------------------
-- Update the .new for plugins
-- drop function im_component_plugin__new (
--        integer, varchar, timestamptz, integer, varchar, integer,
--        varchar, varchar, varchar, varchar, varchar, integer,
--       varchar);
--


create or replace function im_component_plugin__new (
        integer, varchar, timestamptz, integer, varchar, integer,
        varchar, varchar, varchar, varchar, varchar, integer,
        varchar, varchar
) returns integer as '
declare
        p_plugin_id     alias for $1;   -- default null
        p_object_type   alias for $2;   -- default ''acs_object''
        p_creation_date alias for $3;   -- default now()
        p_creation_user alias for $4;   -- default null
        p_creation_ip   alias for $5;   -- default null
        p_context_id    alias for $6;   -- default null

        p_plugin_name   alias for $7;
        p_package_name  alias for $8;
        p_location      alias for $9;
        p_page_url      alias for $10;
        p_view_name     alias for $11;  -- default null
        p_sort_order    alias for $12;
        p_component_tcl alias for $13;
        p_title_tcl     alias for $14;

        v_plugin_id     im_component_plugins.plugin_id%TYPE;
	v_count		integer;
begin
	select count(*)	into v_count from im_component_plugins
	where plugin_name = p_plugin_name;
	if v_count > 0 then return 0; end if;

        v_plugin_id := acs_object__new (
                p_plugin_id,    -- object_id
                p_object_type,  -- object_type
                p_creation_date,        -- creation_date
                p_creation_user,        -- creation_user
                p_creation_ip,  -- creation_ip
                p_context_id    -- context_id
        );

        insert into im_component_plugins (
                plugin_id, plugin_name, package_name, sort_order,
                view_name, page_url, location,
                component_tcl, title_tcl
        ) values (
                v_plugin_id, p_plugin_name, p_package_name, p_sort_order,
                p_view_name, p_page_url, p_location,
                p_component_tcl, p_title_tcl
        );

        return v_plugin_id;
end;' language 'plpgsql';





-------------------------------------------------------------
-- Map component plugins to users

comment on table im_component_plugins is '
 Components Plugins are handeled in the database in order to allow
 customizations to survive system updates.
';


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select into v_count count(*) from pg_proc where lower(proname) = ''im_component_plugin_user_map'';

	select count(*)	into v_count from user_tab_columns
	where table_name = ''IM_COMPONENT_PLUGIN_USER_MAP'';
	if v_count > 0 then return 0; end if;

	create table im_component_plugin_user_map (
	        plugin_id               integer
	                                constraint im_comp_plugin_user_map_plugin_fk
	                                references im_component_plugins,
	        user_id                 integer
	                                constraint im_comp_plugin_user_map_user_fk
	                                references users,
	        sort_order              integer not null,
	        minimized_p             char(1)
	                                constraint im_comp_plugin_user_map_min_p_ck
	                                check(minimized_p in (''t'',''f''))
	                                default ''f'',
	        location                varchar(100) not null,
	                constraint im_comp_plugin_user_map_plugin_pk
	                primary key (plugin_id, user_id)
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



comment on table im_component_plugin_user_map is '
 This table maps Component Plugins to particular users,
 effectively allowing users to customize their GUI
 layout.
';





-- View to show a "unified" view to the component_plugins, derived
-- from the main table and the overriding user_map:
--
create or replace view im_component_plugin_user_map_all as (
        select
                c.plugin_id,
                c.sort_order,
                c.location,
                null as user_id
        from
                im_component_plugins c
  UNION
        select
                m.plugin_id,
                m.sort_order,
                m.location,
                m.user_id
        from
                im_component_plugin_user_map m
);




create or replace function im_menu__new (integer, varchar, timestamptz, integer, varchar, integer, varchar, varchar, varchar, varchar, integer, integer, varchar) returns integer as '
declare
        p_menu_id         alias for $1;   -- default null
        p_object_type     alias for $2;   -- default ''acs_object''
        p_creation_date   alias for $3;   -- default now()
        p_creation_user   alias for $4;   -- default null
        p_creation_ip     alias for $5;   -- default null
        p_context_id      alias for $6;   -- default null
        p_package_name    alias for $7;
        p_label           alias for $8;
        p_name            alias for $9;
        p_url             alias for $10;
        p_sort_order      alias for $11;
        p_parent_menu_id  alias for $12;
        p_visible_tcl     alias for $13;  -- default null

        v_menu_id         im_menus.menu_id%TYPE;
begin
        select  menu_id into    v_menu_id
        from    im_menus m where   m.label = p_label;
        IF v_menu_id is not null THEN return v_menu_id; END IF;

        v_menu_id := acs_object__new (
                p_menu_id,    -- object_id
                p_object_type,  -- object_type
                p_creation_date,        -- creation_date
                p_creation_user,        -- creation_user
                p_creation_ip,  -- creation_ip
                p_context_id    -- context_id
        );
        insert into im_menus (
                menu_id, package_name, label, name,
                url, sort_order, parent_menu_id, visible_tcl
        ) values (
                v_menu_id, p_package_name, p_label, p_name, p_url,
                p_sort_order, p_parent_menu_id, p_visible_tcl
        );
        return v_menu_id;
end;' language 'plpgsql';




-- -----------------------------------------------------
-- User Exits Menu (Admin Page)
-- -----------------------------------------------------

create or replace function inline_1 ()
returns integer as '
declare
      v_menu                  integer;
      v_admin_menu            integer;
      v_admins                integer;
begin
    select group_id into v_admins from groups where group_name = ''P/O Admins'';

    select menu_id into v_admin_menu
    from im_menus where label=''admin'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''admin_user_exists'',   -- label
        ''User Exists'',            -- name
        ''/intranet/admin/user_exits'', -- url
        110,                     -- sort_order
        v_admin_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();






-- 060714 fraber: Function changes its type, so we have to delete first.
-- However, there is no dependency on the function by any other PlPg/SQL 
-- function, so that should be OK without recompilation.
drop function im_menu__name(integer);

-- Returns the name of the menu
create or replace function im_menu__name (integer) returns varchar as '
DECLARE
        p_menu_id   alias for $1;
        v_name      im_menus.name%TYPE;
BEGIN
        select  name
        into    v_name
        from    im_menus
        where   menu_id = p_menu_id;

        return v_name;
end;' language 'plpgsql';



-- /packages/intranet-wiki/sql/postgresql/intranet-wiki-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- Sets up an interface to the OpenACS Wiki System

---------------------------------------------------------
-- Register components

create or replace function inline_0 ()
returns integer as ' 
declare
    v_plugin            integer;
begin
    -- Home Page
    -- Set the wiki to the very end.
    --
    v_plugin := im_component_plugin__new (
	null,					-- plugin_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''Home Wiki Component'',		-- plugin_name
	''intranet-wiki'',			-- package_name
        ''right'',				-- location
	''/intranet/index'',			-- page_url
        null,					-- view_name
        60,					-- sort_order
        ''im_wiki_home_component''		-- component_tcl
    );
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as ' 
declare
    v_plugin            integer;
begin
    -- Home Page
    -- Set the wiki to the very end.
    --
    v_plugin := im_component_plugin__new (
	null,					-- plugin_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''Project Wiki Component'',		-- plugin_name
	''intranet-wiki'',			-- package_name
        ''right'',				-- location
	''/intranet/projects/view'',		-- page_url
        null,					-- view_name
        80,					-- sort_order
        ''im_wiki_project_component $project_id'' -- component_tcl
    );
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as ' 
declare
    v_plugin            integer;
begin
    -- Home Page
    -- Set the wiki to the very end.
    --
    v_plugin := im_component_plugin__new (
	null,					-- plugin_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''Company Wiki Component'',		-- plugin_name
	''intranet-wiki'',			-- package_name
        ''right'',				-- location
	''/intranet/companies/view'',		-- page_url
        null,					-- view_name
        80,					-- sort_order
        ''im_wiki_company_component $company_id'' -- component_tcl
    );
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as ' 
declare
    v_plugin            integer;
begin
    -- Home Page
    -- Set the wiki to the very end.
    --
    v_plugin := im_component_plugin__new (
	null,					-- plugin_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''User Wiki Component'',		-- plugin_name
	''intranet-wiki'',			-- package_name
        ''right'',				-- location
	''/intranet/users/view'',		-- page_url
        null,					-- view_name
        80,					-- sort_order
        ''im_wiki_user_component $user_id'' -- component_tcl
    );
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as ' 
declare
    v_plugin            integer;
begin
    -- Home Page
    -- Set the wiki to the very end.
    --
    v_plugin := im_component_plugin__new (
	null,					-- plugin_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''Office Wiki Component'',		-- plugin_name
	''intranet-wiki'',			-- package_name
        ''right'',				-- location
	''/intranet/offices/view'',		-- page_url
        null,					-- view_name
        80,					-- sort_order
        ''im_wiki_office_component $office_id'' -- component_tcl
    );
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as ' 
declare
    v_plugin            integer;
begin
    -- Home Page
    -- Set the wiki to the very end.
    --
    v_plugin := im_component_plugin__new (
	null,					-- plugin_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''Conf Item Wiki Component'',		-- plugin_name
	''intranet-wiki'',			-- package_name
        ''right'',				-- location
	''/intranet-confdb/new'',		-- page_url
        null,					-- view_name
        120,					-- sort_order
        ''im_wiki_base_component im_conf_item $conf_item_id'' -- component_tcl
    );
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as ' 
declare
    v_plugin            integer;
begin
    -- Home Page
    -- Set the wiki to the very end.
    --
    v_plugin := im_component_plugin__new (
	null,					-- plugin_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''Helpdesk Wiki Component'',		-- plugin_name
	''intranet-wiki'',			-- package_name
        ''right'',				-- location
	''/intranet-helpdesk/new'',		-- page_url
        null,					-- view_name
        120,					-- sort_order
        ''im_wiki_base_component im_ticket $ticket_id'' -- component_tcl
    );
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





---------------------------------------------------------
-- Setup the "Wiki" main menu entry
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
        ''intranet-wiki'',      -- package_name
        ''wiki'',               -- label
        ''Wiki'',               -- name
        ''/intranet-wiki/'',    -- url
        75,                     -- sort_order
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

    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();

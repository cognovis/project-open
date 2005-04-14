-- /packages/intranet-wiki/sql/postgresql/intranet-wiki-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- Sets up an interface to the OpenACS Wiki System

---------------------------------------------------------
-- delete potentially existing menus and plugins if this 
-- file is sourced multiple times during development...

select im_component_plugin__del_module('intranet-wiki');
select im_menu__del_module('intranet-wiki');


---------------------------------------------------------
-- Register the component:

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


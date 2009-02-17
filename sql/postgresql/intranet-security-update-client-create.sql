-- /packages/intranet-security-update-client/sql/postgres/intranet-security-update-client-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- Sets up an interface to show Security Server messages

---------------------------------------------------------
-- delete potentially existing menus and plugins if this 
-- file is sourced multiple times during development...

select im_component_plugin__del_module('intranet-security-update-client');
select im_menu__del_module('intranet-security-update-client');



---------------------------------------------------------
-- Register the component:
--	- at the ]po[ admin page ('/intranet/admin/index')
-- 	- at the right page column ('right')
--	- in the middle of the column (sortorder 50)
--

create or replace function inline_0 ()
returns integer as ' 
declare
    v_plugin            integer;
begin
    -- Show security messages inthe Admin Home Page
    --
    v_plugin := im_component_plugin__new (
	null,					-- plugin_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''Security Update Client Component'',	-- plugin_name
	''intranet-security-update-client'',	-- package_name
        ''right'',				-- location
	''/intranet/admin/index'',		-- page_url
        null,					-- view_name
        50,					-- sort_order
        ''im_security_update_client_component''	-- component_tcl
    );
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


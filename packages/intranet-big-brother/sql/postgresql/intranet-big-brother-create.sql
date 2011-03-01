-- /packages/intranet-big-brother/sql/oracle/intranet-big-brother-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- avila@digiteix.com

---------------------------------------------------------
-- Register the component:
--	- at the P/O homepage ('/intranet/index')
-- 	- at the left page column ('left')
--	- at the beginning of the left column ('10')
--

create or replace function inline_0 ()
returns integer as ' 
declare
    v_plugin            integer;
begin
    -- Home Page
    -- Set the big-brother to the very end.
    --
    v_plugin := im_component_plugin__new (
	null,					-- plugin_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''Home Big Brother Component'',		-- plugin_name
	''intranet-big-brother'',		-- package_name
        ''right'',				-- location
	''/intranet/index'',			-- page_url
        null,					-- view_name
        60,					-- sort_order
        ''im_big_brother_component $user_id''	-- component_tcl
    );
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


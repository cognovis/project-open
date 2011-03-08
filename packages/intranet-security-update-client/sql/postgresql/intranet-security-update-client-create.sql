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

-- select im_component_plugin__del_module('intranet-security-update-client');
-- select im_menu__del_module('intranet-security-update-client');


---------------------------------------------------------
-- Setup the "Software Updates" main menu entry
--

create or replace function inline_0 ()
returns integer as '
declare
	v_menu			integer;
	v_main_menu		integer;
	v_admin_menu		integer;
BEGIN
	select menu_id into v_admin_menu
	from im_menus where label=''admin'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-security-update-client'', -- package_name
		''software_updates'',   		-- label
		''Software Updates'',   		-- name
		''/intranet-security-update-client/'',	-- url
		12,					-- sort_order
		v_admin_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





---------------------------------------------------------
-- Register the component:
--	- at the ]po[ admin page ('/intranet/admin/index')
-- 	- at the right page column ('right')
--	- in the middle of the column (sortorder 50)
--

create or replace function inline_0 ()
returns integer as ' 
declare
	v_plugin		integer;
begin
	-- Show security messages in the Admin Home Page
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




create or replace function inline_0 ()
returns integer as ' 
declare
	v_plugin		integer;
begin
	-- Allow importing Exchange Rates from ASUS server
	--
	v_plugin := im_component_plugin__new (
		null,					-- plugin_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''Exchange Rates ASUS'',		-- plugin_name
		''intranet-security-update-client'',	-- package_name
		''right'',				-- location
		''/intranet-exchange-rate/index'',	-- page_url
		null,					-- view_name
		10,					-- sort_order
		''im_exchange_rate_update_component''	-- component_tcl
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



SELECT im_grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Exchange Rates ASUS'),
	(select group_id from groups where group_name = 'Accounting'), 
	'read'
);

SELECT im_grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Exchange Rates ASUS'),
	(select group_id from groups where group_name = 'Senior Managers'), 
	'read'
);

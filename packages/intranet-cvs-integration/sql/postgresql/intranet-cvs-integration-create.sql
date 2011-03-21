-- /packages/intranet-cvs-integration/sql/postgresql/intranet-cvs-integration.sql
--
-- Copyright (c) 2003-2006 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-----------------------------------------------------------
-- Integrate with CVS
--
-- We setup a database table to be filled with records
-- being returned from the CVS "rlog" command
-- Together with the "cvs_user" field in "persons"
-- this allows us to track how many lines have been
-- written on what project by a developer.

create sequence im_cvs_logs_seq start 1;
create table im_cvs_logs (
	cvs_line_id		integer
				constraint im_cvs_logs_pk
				primary key,
	cvs_repo		text,
	cvs_filename		text,
	cvs_revision		text,
	cvs_date		timestamptz,
	cvs_author		text,
	cvs_state		text,
	cvs_lines_add		integer,
	cvs_lines_del		integer,
	cvs_note		text,
	
	cvs_user_id		integer,
	cvs_project_id		integer,
	cvs_conf_item_id	integer,

		constraint im_cvs_logs_filname_un
		unique (cvs_filename, cvs_date, cvs_revision)
);



-----------------------------------------------------------
-- DynFields
--
-- Define fields necessary for CVS repository access


alter table persons add cvs_user text;


alter table im_conf_items add cvs_repository text;
alter table im_conf_items add cvs_protocol text;
alter table im_conf_items add cvs_user text;
alter table im_conf_items add cvs_password text;
alter table im_conf_items add cvs_hostname text;
alter table im_conf_items add cvs_port integer;
alter table im_conf_items add cvs_path text;


SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_repository', 'CVS Repository', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_protocol', 'CVS Protocol', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_user', 'CVS User', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_password', 'CVS Password', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_hostname', 'CVS Hostname', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_port', 'CVS Port', 'integer', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'cvs_path', 'CVS Path', 'textbox_medium', 'string', 'f');



-----------------------------------------------------------------------
-- Set visibility for all cvs_* field to CVS repositories only

-- Delete any visibility of cvs_* fields
delete from im_dynfield_type_attribute_map
where attribute_id in (
	select	da.attribute_id
	from	im_dynfield_attributes da,
		acs_attributes aa
	where	da.acs_attribute_id = aa.attribute_id and
		aa.object_type = 'im_conf_item' and
		aa.attribute_name like 'cvs_%'
);

-- Selectively add the visibility "edit" to the ConfItem type "CVS Repository"
insert into im_dynfield_type_attribute_map (
	select	da.attribute_id,
		12400 as object_type_id,
		'edit' as display_mode
	from	im_dynfield_attributes da,
		acs_attributes aa
	where	da.acs_attribute_id = aa.attribute_id and
		aa.object_type = 'im_conf_item' and
		aa.attribute_name like 'cvs_%'
);




-----------------------------------------------------------
-- Menu for CVS Administration
--
-- Create a menu item in the main menu bar and set some default 
-- permissions for various groups who should be able to see the menu.


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu		integer;

	-- Groups
	v_admin			integer;
BEGIN
	-- Get some group IDs
	select group_id into v_admin from groups where group_name = ''P/O Admins'';

	-- Determine the main menu. "Label" is used to
	-- identify menus.
	select menu_id into v_main_menu
	from im_menus where label=''admin'';

	-- Create the menu.
	v_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-cvs-integration'',	-- package_name
		''cvs_integration'',		-- label
		''CVS Integration'',		-- name
		''/intranet-cvs-integration/'',	-- url
		259,				-- sort_order
		v_main_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admin, ''read'');

	return 0;
end;' language 'plpgsql';
-- Execute and then drop the function
select inline_0 ();
drop function inline_0 ();




-----------------------------------------------------------
-- Plugin Components
--
-- Plugins are these grey boxes that appear in many pages in 
-- the system. This plugin shows the list of cvs commits per
-- ticket or project.


-- Create a Notes plugin for the ProjectViewPage.
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project CVS Logs',		-- plugin_name
	'intranet-cvs-integration',	-- package_name
	'left',				-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	140,				-- sort_order
	'im_cvs_log_component -object_id $project_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-cvs-integration.Project_CVS_Logs "CVS Logs"'
where plugin_name = 'Project CVS Logs';



-- Create a Notes plugin for the TicketViewPage
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Ticket CVS Logs',		-- plugin_name
	'intranet-cvs-integration',	-- package_name
	'left',				-- location
	'/intranet-helpdesk/new',	-- page_url
	null,				-- view_name
	140,				-- sort_order
	'im_cvs_log_component -object_id $ticket_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-cvs-integration.CVS_Logs "CVS Logs"'
where plugin_name = 'Ticket CVS Logs';




-- Create a Notes plugin for the TicketViewPage
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Conf Item CVS Logs',		-- plugin_name
	'intranet-cvs-integration',	-- package_name
	'left',				-- location
	'/intranet-confdb/new',		-- page_url
	null,				-- view_name
	140,				-- sort_order
	'im_cvs_log_component -conf_item_id $conf_item_id'	-- component_tcl
);

update im_component_plugins 
set title_tcl = 'lang::message::lookup "" intranet-cvs-integration.CVS_Logs "CVS Logs"'
where plugin_name = 'Conf Item CVS Logs';

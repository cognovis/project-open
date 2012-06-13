-- /packages/intranet-sharepoint/sql/postgresql/intranet-sharepoint-create.sql
--
-- Copyright (c) 2010 ]project-open[ for DHL
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--


-----------------------------------------------------------
-- Plugin Components
--
-- Plugins are these grey boxes that appear in many pages in 
-- the system. The plugin shows the list of notes that are
-- associated with the specific object.
-- This way we can add notes to projects, users companies etc.
-- with only a single TCL/ADP page.
--
-- You can add/modify these plugin definitions in the Admin ->
-- Plugin Components page



-- Create an iFrame to show the local Sharepoint server.
SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Sharepoint',			-- plugin_name
	'intranet-sharepoint',		-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	100,				-- sort_order
	'im_sharepoint_project_component -project_id $project_id'	-- component_tcl
);

-- /packages/intranet-trans-project-wizard/sql/postgresql/intranet-trans-project-wizard-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com




-- Show the wizard component in the project view page
--
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Project Translation Wizard',		-- plugin_name
	'intranet-intranet-trans-project-wizard',  -- package_name
	'left',					-- location
	'/intranet/projects/view',		-- page_url
	null,					-- view_name
	-10,					-- sort_order
	'im_trans_project_wizard_component -project_id $project_id',
	'lang::message::lookup "" intranet-trans-project-wizard.Translation_Project_Wizard "Translation Project Wizard"'
);

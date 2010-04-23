-- /packages/intranet-ganttproject/sql/postgresql/intranet-ganttproject-create.sql
--
-- Copyright (c) 2010 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


SELECT im_component_plugin__new (
	null,					-- plugin_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Resource Availability Component',	-- plugin_name
	'intranet-ganttproject',		-- package_name
	'bottom',				-- location
	'/intranet/member-add',			-- page_url
	null,					-- view_name
	110,					-- sort_order
	'im_resource_mgmt_resource_planning_add_member_component',
	'lang::message::lookup "" intranet-ganttproject.Resource_Availability "Resource Availability"'
);


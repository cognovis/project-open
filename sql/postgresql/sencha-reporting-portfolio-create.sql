-- /packages/sencha-reporting-portfolio/sql/postgresql/sencha-reporting-portfolio-create.sql
--
-- ]project[ Sencha Portfolio Reporting
-- Copyright (c) 2003 - 2012 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
-- @author frank.bergmann@project-open.com

----------------------------------------------------
-- Portlets
----------------------------------------------------

SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Sales Pipeline',			-- plugin_name
	'sencha-reporting-portfolio',		-- package_name
	'right',				-- location
	'/intranet/projects/index',		-- page_url
	null,					-- view_name
	10,					-- sort_order
	'sencha_scatter_diagram -diagram_width 300 -diagram_height 300 -sql "
		select	p.presales_value as x_axis,
			p.presales_probability as y_axis,
			''blue'' as color,
			sqrt(coalesce(p.presales_value, 200.0)) / 10.0 as diameter,
			p.project_name as title
		from	im_projects p
		where	p.parent_id is null and
			p.project_status_id in (select * from im_sub_categories(71)) and
			p.presales_value is not null and
			p.presales_probability is not null and
			p.presales_value > 0  and
			p.presales_probability > 0
		order by 
			p.project_id
	" -diagram_caption "Shows presales value vs. probability for potential projects."'
);



SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Margin Tracker',			-- plugin_name
	'sencha-reporting-portfolio',		-- package_name
	'right',				-- location
	'/intranet/projects/index',		-- page_url
	null,					-- view_name
	20,					-- sort_order
	'sencha_scatter_diagram -diagram_width 300 -diagram_height 300 -sql "
		select	p.presales_value as x_axis,
			p.presales_probability as y_axis,
			''blue'' as color,
			sqrt(coalesce(p.presales_value, 200.0)) / 10.0 as diameter,
			p.project_name as title
		from	im_projects p
		where	p.parent_id is null and
			p.project_status_id in (select * from im_sub_categories(76)) and
			p.presales_value is not null and
			p.presales_probability is not null and
			p.presales_value > 0  and
			p.presales_probability > 0
		order by 
			p.project_id
	" -diagram_caption "Shows planned vs. current margin of open projects."'
);



SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Milestone Tracker',			-- plugin_name
	'sencha-reporting-portfolio',		-- package_name
	'left',					-- location
	'/intranet/projects/view',		-- page_url
	null,					-- view_name
	10,					-- sort_order
	'sencha_milestone_tracker -project_id $project_id -diagram_caption "Milestones" -diagram_width 300 -diagram_height 300'
);




SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Project Timeline',			-- plugin_name
	'sencha-reporting-portfolio',		-- package_name
	'bottom',				-- location
	'/intranet/index',				-- page_url
	null,					-- view_name
	10,					-- sort_order
	'sencha_project_timeline -diagram_aggregation_level month'	-- Portlet TCL
);


SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'EVA Diagram',				-- plugin_name
	'sencha-reporting-portfolio',		-- package_name
	'bottom',				-- location
	'/intranet/projects/view',		-- page_url
	null,					-- view_name
	20,					-- sort_order
	'sencha_project_eva -project_id $project_id'	-- Portlet TCL
);


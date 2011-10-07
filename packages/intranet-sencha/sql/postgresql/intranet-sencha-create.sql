-- /packages/intranet-sencha/sql/oracle/intranet-sencha-create.sql
--
-- ]project[ Sencha Interface
-- Copyright (c) 2003 - 2009 ]project-open[
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
	'Margin Tracker',			-- plugin_name
	'intranet-sencha',			-- package_name
	'right',				-- location
	'/intranet/projects/index',		-- page_url
	null,					-- view_name
	10,					-- sort_order
	'im_sencha_scatter_diagram -diagram_width 200 -diagram_height 200 -sql "
		select	p.presales_value as x_axis,
			p.presales_probability as y_axis,
			''yellow'' as color,
			1 as diameter
		from	im_projects p
		where	p.parent_id is null and
			p.project_status_id in (select * from im_sub_categories(76)) and
			p.presales_value is not null and
			p.presales_probability is not null and
			p.presales_value > 0  and
			p.presales_probability > 0
		order by 
			p.project_id
	"'
);



SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Margin Tracker',			-- plugin_name
	'intranet-sencha',			-- package_name
	'right',				-- location
	'/intranet/projects/index',		-- page_url
	null,					-- view_name
	10,					-- sort_order
	'im_sencha_scatter_diagram -diagram_width 200 -diagram_height 200 -sql "
		select	p.presales_value as x_axis,
			p.presales_probability as y_axis,
			''yellow'' as color,
			1 as diameter
		from	im_projects p
		where	p.parent_id is null and
			p.project_status_id in (select * from im_sub_categories(76)) and
			p.presales_value is not null and
			p.presales_probability is not null and
			p.presales_value > 0  and
			p.presales_probability > 0
		order by 
			p.project_id
	"'
);


SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Milestone Tracker',			-- plugin_name
	'intranet-sencha',			-- package_name
	'left',					-- location
	'/intranet/projects/view',		-- page_url
	null,					-- view_name
	10,					-- sort_order
	'im_sencha_milestone_tracker -project_id $project_id -title "Milestones" -diagram_width 300 -diagram_height 300'
);


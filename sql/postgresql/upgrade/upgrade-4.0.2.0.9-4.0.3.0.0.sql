-- upgrade-4.0.2.0.9-4.0.3.0.0.sql

SELECT acs_log__debug('/packages/intranet-portfolio-management/sql/postgresql/upgrade/upgrade-4.0.2.0.9-4.0.3.0.0.sql','');


-- ----------------------------------------------------------------
-- Program Portfolio Portlet
-- ----------------------------------------------------------------

SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Program Portfolio List',	-- plugin_name
	'intranet-portfolio-management', -- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	15,				-- sort_order
	'im_program_portfolio_list_component -program_id $project_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Program Portfolio List'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);





-- 300-309              intranet-portfolio-management
-- 300			program_portfolio_list

--
delete from im_view_columns where view_id = 300;
delete from im_views where view_id = 300;
--
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (300, 'program_portfolio_list', 'view_projects', 1400);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30000,300,'Ok',
'"<center>[im_project_on_track_bb $on_track_status_id]</center>"','','',0,'');

-- insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (30001,300,'Project nr',
-- '"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"','','',1,'');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30010,300,'Project Name',
'"<A HREF=/intranet/projects/view?project_id=$project_id>[string range $project_name 0 30]</A>"','','',10,'');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30020,300,'Start','$start_date_formatted','','',20,'');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30025,300,'End','$end_date_formatted','','',25,'');


insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30030,300,'Budget','$project_budget','','',30,'');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30035,300,'Quoted','$cost_quotes_cache','','',35,'');

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30050,300,'Done','"$percent_completed_rounded%"','','',50,'');

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30080,300,'Plan Costs','$planned_costs','','',80,'');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (30085,300,'Cur Costs','$real_costs','','',85,'');



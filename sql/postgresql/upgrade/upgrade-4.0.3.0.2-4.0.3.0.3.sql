-- upgrade-4.0.3.0.2-4.0.3.0.3.sql

SELECT acs_log__debug('/packages/intranet-rest/sql/postgresql/upgrade/upgrade-4.0.3.0.2-4.0.3.0.3.sql','');


SELECT im_report_new (
	'REST My Timesheet Projects and Hours',				-- report_name
	'rest_my_timesheet_projects_hours',				-- report_code
	'intranet-rest',						-- package_key
	110,								-- report_sort_order
	(select menu_id from im_menus where label = 'reporting-rest'),	-- parent_menu_id
'select	child.project_id,
	child.parent_id,
	tree_level(child.tree_sortkey)-1 as level,
	child.project_name,
	child.project_nr,
	child.company_id,
	acs_object__name(child.company_id) as company_name,
	child.project_type_id,
	child.project_status_id,
	im_category_from_id(child.project_type_id) as project_type,
	im_category_from_id(child.project_status_id) as project_status,
	h.hours,
	h.note,
	h.material_id,
	acs_object__name(h.material_id) as material_name
from
	im_projects parent,
	im_projects child
	LEFT OUTER JOIN (
		select	*
		from	im_hours h
		where	h.user_id = %user_id% and
			h.day::date = ''%date%''::date
	) h ON (child.project_id = h.project_id),
	acs_rels r
where
	parent.parent_id is null and
	child.project_type_id not in (select * from im_sub_categories(81)) and
	child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) and
	r.object_id_one = parent.project_id and
	r.object_id_two = %user_id%
order by
	child.tree_sortkey
'
);


update im_reports
set report_description = '
Returns the list of all projects to which the current user
has the right to log hours, together with the list of hours
logged as of the specified %date% URL parameter.'
where report_code = 'rest_my_timesheet_projects_hours';

SELECT acs_permission__grant_permission(
        (select menu_id from im_menus where label = 'rest_my_timesheet_projects_hours'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);



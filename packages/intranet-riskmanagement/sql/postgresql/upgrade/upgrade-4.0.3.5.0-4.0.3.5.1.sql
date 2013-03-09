-- upgrade-4.0.3.5.0-4.0.3.5.1.sql

SELECT acs_log__debug('/packages/intranet-riskmanagement/sql/postgresql/upgrade/upgrade-4.0.3.5.0-4.0.3.5.1.sql','');


update im_categories
set category = 'Open'
where category_id = 75000;


update im_categories
set category = 'Closed'
where category_id = 75002;

SELECT im_category_new (75098, 'Deleted', 'Intranet Risk Status');

update im_categories
set category = 'Risk'
where category_id = 75100;

update im_categories
set category = 'Issue'
where category_id = 75002;

SELECT im_category_new (75102, 'Issue', 'Intranet Risk Type');



create or replace function inline_0 ()
returns integer as $body$
declare
	v_menu			integer;
	v_main_menu 		integer;
	v_employees		integer;
BEGIN
	select group_id into v_employees from groups where group_name = 'Employees';
	select menu_id into v_main_menu	from im_menus where label = 'reporting-other';

	v_menu := im_menu__new (
		null,							-- p_menu_id
		'im_menu', 						-- object_type
		now(),							-- creation_date
		null,							-- creation_user
		null,							-- creation_ip
		null,							-- context_id
		'intranet-riskmanagement',				-- package_name
		'reporting-project-risks',				-- label
		'Project Risks',					-- name
		'/intranet-riskmanagement/project-risks-report',	-- url
		2400,							-- sort_order
		v_main_menu,						-- parent_menu_id
		null							-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_employees, 'read');

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


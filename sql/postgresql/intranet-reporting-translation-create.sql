-- /package/intranet-reporting-translation/sql/postgresql/intranet-reporting-translation-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
--
-- Translation Reports for ]po[


---------------------------------------------------------
-- Translation Report Menu
--

--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_reporting_menu 	integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
	v_reg_users		integer;
BEGIN
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';
	select group_id into v_reg_users from groups where group_name = ''Registered Users'';

	select menu_id
	into v_reporting_menu
	from im_menus
	where label=''reporting'';

	v_reporting_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-translation'',		-- package_name
		''reporting-translation'',			-- label
		''Translation'',			-- name
		''/intranet-reporting-translation/'',	-- url
		50,					-- sort_order
		v_reporting_menu,			-- parent_menu_id
		null					-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





---------------------------------------------------------
-- Translation - Monthly Summary
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu 		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
	v_reg_users		integer;
BEGIN
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';
	select group_id into v_reg_users from groups where group_name = ''Registered Users'';

	select menu_id into v_main_menu
	from im_menus where label=''reporting-translation'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-translation'',		-- package_name
		''reporting-project-trans-tasks'',	-- label
		''Translation Tasks'',		-- name
		''/intranet-reporting-translation/project-trans-tasks'', -- url
		20,					-- sort_order
		v_main_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();






---------------------------------------------------------
-- Translation - PM Productivity
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu 		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
	v_reg_users		integer;
BEGIN
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';
	select group_id into v_reg_users from groups where group_name = ''Registered Users'';

	select menu_id into v_main_menu
	from im_menus where label=''reporting-translation'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-translation'',		-- package_name
		''reporting-trans-pm-productivity'',	-- label
		''Translation PM Productivity'',		-- name
		''/intranet-reporting-translation/trans-pm-productivity'', -- url
		30,					-- sort_order
		v_main_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



SELECT im_report_new (
	'Translation Units Sold by UoM and Language',
	'translation_units_sold_by_uom_and_language',
	'intranet-reporting-translation',
	40,
	(select menu_id from im_menus where label = 'reporting-translation'),
	'
select
        item_uom,
        source_language,
        target_language,
        sum(item_units) as item_units
from
        (select substring(im_category_from_id(m.source_language_id) from 1 for 2) as source_language,
                substring(im_category_from_id(m.target_language_id) from 1 for 2) as target_language,
                im_category_from_id(ii.item_uom_id) as item_uom,
                item_units
        from    im_invoice_items ii,
                im_materials m,
                im_costs c
        where   ii.item_material_id = m.material_id and
                ii.invoice_id = c.cost_id and
                c.cost_type_id = 3700
        ) ii
group by
      source_language,
      target_language,
      item_uom
order by
      item_uom,
      source_language,
      target_language
'
);	


-- /packages/intranet-cost-center/sql/postgresql/intranet-cost-center-create.sql
--
-- Profit Center Management Extension
--
-- Copyright (c) 2004-2006 ]project-open[
--
-- All rights including reserved. To inquire license terms please
-- refer to http://www.project-open.com/modules/<module-key>


-- Enable department level permissions
SELECT acs_log__debug('/packages/intranet-cost-center/sql/postgresql/upgrade/upgrade-4.0.3.1.0-4.0.3.1.1.sql','');

select acs_privilege__create_privilege('view_projects_dept','View Department Projects','View Department Projects');
select acs_privilege__add_child('admin', 'view_projects_dept');
select acs_privilege__create_privilege('edit_projects_dept','Edit Department Projects','Edit Department Projects');
select acs_privilege__add_child('admin', 'edit_projects_dept');




create or replace function inline_0 ()
returns integer as'
declare
	-- Menu IDs
	v_menu		  integer;
	v_admin_menu	  integer;

	-- Groups
	v_employees	     integer;
	v_accounting	    integer;
	v_senman		integer;
	v_customers	     integer;
	v_freelancers	   integer;
	v_proman		integer;
	v_admins		integer;
begin
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';

    select menu_id
    into v_admin_menu
    from im_menus
    where label=''admin'';

    v_menu := im_menu__new (
	null,		 			-- p_menu_id
	''acs_object'',	 			-- object_type
	now(),		 			-- creation_date
	null,		   			-- creation_user
	null,		   			-- creation_ip
	null,		   			-- context_id
	''intranet-cost-center'',		-- package_name
	''admin_cost_center_permissions'',	-- label
	''Cost Center Perms'',			-- name
	''/intranet-cost-center/index'',	-- url
	86,		     			-- sort_order
	v_admin_menu,				-- parent_menu_id
	null					-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



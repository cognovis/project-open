-- /packages/intranet-cost/sql/postgres/upgrade/upgrade-3.2.0.0.0-3.2.2.0.0.sql
--
-- Project/Open Cost Core
-- 040207 frank.bergmann@project-open.com
--
-- Copyright (C) 2006 Project/Open
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

-------------------------------------------------------------
-- 
---------------------------------------------------------

-- Add cache fields for Delivery Notes

alter table im_projects add     cost_delivery_notes_cache       numeric(12,2);
alter table im_projects alter   cost_delivery_notes_cache       set default 0;


-- Remove old "Travel Costs" cost type
delete from im_categories where category_id = 3712;

INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3724,'Delivery Note','Intranet Cost Type');

-- Establish that a Delivery Note is a "Customer Documents"
insert into im_category_hierarchy values (3708,3724);



-------------------------------------------------------------
-- 
---------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu		integer;
	v_admin_menu	integer;

	-- Groups
	v_accounting	integer;
	v_senman	integer;
	v_admins	integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';

    select menu_id
    into v_admin_menu
    from im_menus
    where label=''admin'';

    v_menu := im_menu__new (
	null,			-- p_menu_id
	''acs_object'',		-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	''intranet-cost'',  -- package_name
	''admin_cost_centers'',    -- label
	''Cost Centers'',	-- name
	''/intranet-cost/cost-centers/index'',   -- url
	85,			-- sort_order
	v_admin_menu,		-- parent_menu_id
	null			-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



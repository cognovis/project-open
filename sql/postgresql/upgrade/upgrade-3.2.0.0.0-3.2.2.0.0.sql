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



-------------------------------------------------------------
-- Cost Center Permissions for Financial Documents
-------------------------------------------------------------

-- Permissions and Privileges
--
select acs_privilege__create_privilege('fi_read_invoices','Read Invoices','Read Invoices');
select acs_privilege__create_privilege('fi_write_invoices','Write Invoices','Write Invoices');
select acs_privilege__add_child('read', 'fi_read_invoices');
select acs_privilege__add_child('write', 'fi_write_invoices');

select acs_privilege__create_privilege('fi_read_quotes','Read Quotes','Read Quotes');
select acs_privilege__create_privilege('fi_write_quotes','Write Quotes','Write Quotes');
select acs_privilege__add_child('read', 'fi_read_quotes');
select acs_privilege__add_child('write', 'fi_write_quotes');

select acs_privilege__create_privilege('fi_read_bills','Read Bills','Read Bills');
select acs_privilege__create_privilege('fi_write_bills','Write Bills','Write Bills');
select acs_privilege__add_child('read', 'fi_read_bills');
select acs_privilege__add_child('write', 'fi_write_bills');

select acs_privilege__create_privilege('fi_read_pos','Read Pos','Read Pos');
select acs_privilege__create_privilege('fi_write_pos','Write Pos','Write Pos');
select acs_privilege__add_child('read', 'fi_read_pos');
select acs_privilege__add_child('write', 'fi_write_pos');



select im_priv_create('fi_read_invoices','P/O Admins');
select im_priv_create('fi_read_invoices','Senior Managers');
select im_priv_create('fi_read_invoices','Accounting');
select im_priv_create('fi_write_invoices','P/O Admins');
select im_priv_create('fi_write_invoices','Senior Managers');
select im_priv_create('fi_write_invoices','Accounting');

select im_priv_create('fi_read_quotes','P/O Admins');
select im_priv_create('fi_read_quotes','Senior Managers');
select im_priv_create('fi_read_quotes','Accounting');
select im_priv_create('fi_write_quotes','P/O Admins');
select im_priv_create('fi_write_quotes','Senior Managers');
select im_priv_create('fi_write_quotes','Accounting');

select im_priv_create('fi_read_bills','P/O Admins');
select im_priv_create('fi_read_bills','Senior Managers');
select im_priv_create('fi_read_bills','Accounting');
select im_priv_create('fi_write_bills','P/O Admins');
select im_priv_create('fi_write_bills','Senior Managers');
select im_priv_create('fi_write_bills','Accounting');

select im_priv_create('fi_read_pos','P/O Admins');
select im_priv_create('fi_read_pos','Senior Managers');
select im_priv_create('fi_read_pos','Accounting');
select im_priv_create('fi_write_pos','P/O Admins');
select im_priv_create('fi_write_pos','Senior Managers');
select im_priv_create('fi_write_pos','Accounting');






-------------------------------------------------------------
-- Update the context_id field of the "Co - The Company"
-- so that permissions are inherited from SubSite
--
create or replace function inline_0 ()
returns integer as '
DECLARE
        v_subsite_id             integer;
BEGIN
     -- Get the Main Site id, used as the global identified for permissions
     select package_id
     into v_subsite_id
     from apm_packages
     where package_key=''acs-subsite'';

     update acs_objects
     set context_id = v_subsite_id
     where object_id in (
	select cost_center_id
	from im_cost_centers
	where parent_id is null
     );

     return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();




-------------------------------------------------------------
-- Update the context_id fields of the cost centers, 
-- so that permissions are inherited
--
create or replace function inline_0 ()
returns integer as '
DECLARE
    row                         RECORD;
BEGIN
    FOR row IN
        select  *
        from    im_cost_centers
    LOOP
        RAISE NOTICE ''inline_0: cc_id=%'', row.cost_center_id;

        update acs_objects
        set context_id = row.parent_id
        where object_id = row.cost_center_id;

    END LOOP;
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0();



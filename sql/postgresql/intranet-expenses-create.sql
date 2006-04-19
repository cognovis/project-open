-- /packages/intranet-expenses/sql/postgresql/intranet-expenses-create.sql
--
-- Project/Open Expenses Core
-- 060419 avila@digiteix.com 
--
-- Copyright (C) 2004 Project/Open
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

-------------------------------------------------------------
-- Expenses
--
-- Scenario:

-- An employee or freelancer travels for the company to perform some task (visit a customer, ...)
-- An employee rents a beamer and buys some cookies for a special meeting with a customer

create or replace function inline_0 ()
returns integer as '
declare
	v_object_type	integer;
begin
    v_object_type := acs_object_type__create_type (
	''im_expense'',			-- object_type
	''Expense'',			-- pretty_name
	''Expenses'',			-- pretty_plural
	''im_cost'',			-- supertype
	''im_expenses'',		-- table_name
	''expense_id'',			-- id_column
	''im_expenses'',		-- package_name
	''f'',				-- abstract_p
	null,				-- type_extension_table
	''im_expense__name''		-- name_method
    );
    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

-- prompt *** intranet-expenses: Creating im_expenses
create table im_expenses (
	expense_id		integer
				constraint im_expense_id_pk
				primary key
				constraint im_expense_id_fk
				references im_costs,
	vat_included		numeric(6,3)
				constraint im_expenses_vat_included_ck
				check (vat_included >=0 and vat_included <= 100),
	external_company_name   varchar(400),
	receipt_reference   varchar(100),
	expense_type_id    	integer
                                constraint im_expense_type_fk
                                references im_categories,
	invoice_id		integer
                                constraint im_expenses_invoice_fk
                                references im_costs,
	billable_p		char(1)
                                constraint im_expenses_billable_ck
                                check (billable_p in ('t','f')),
	reimbursable		numeric(6,3) default 100
				constraint im_expenses_reibursable_ck
				check (reimbursable >=0 and reimbursable <= 100),
	expense_payment_type_id	integer
                                constraint im_expense_payment_type_fk
                                references im_categories
);


-- Delete a single expense (if we know its ID...)
create or replace function im_expenses__delete (integer)
returns integer as '
DECLARE
        p_expense_id alias for $1;	   -- expense_id
begin
        -- Erase the im_expenses entry
        delete from     im_expenses
        where           expense_id = p_expense_id;

        -- Erase the object
        PERFORM im_cost__delete(p_expense_id);
        return 0;
end' language 'plpgsql';


create or replace function im_expenses__name (integer)
returns varchar as '
DECLARE
        p_expenses_id  alias for $1;        -- expense_id
        v_name  varchar(40);
    begin
        select  cost_name
        into    v_name
        from    im_costs
        where   cost_id = p_expense_id;

        return v_name;
end;' language 'plpgsql';



-------------------------------------------------------------
-- Permissions and Privileges
--
select acs_privilege__create_privilege('add_expenses','Add Expenses','Add Expenses');
select acs_privilege__add_child('admin', 'add_expenses');

select acs_privilege__create_privilege('add_expense_invoice','Add Expense Invoice','Add Expense Invoice');
select acs_privilege__add_child('admin', 'add_expense_invoice');

select acs_privilege__create_privilege('view_expenses','View Expenses','View Expenses');
select acs_privilege__add_child('admin', 'view_expenses');

select acs_privilege__create_privilege('view_expenses_all','View All Expenses','View All Expenses');
select acs_privilege__add_child('admin', 'view_expenses_all');



select im_priv_create('add_expenses','Project Managers');
select im_priv_create('add_expenses','Senior Managers');
select im_priv_create('add_expenses','Sales');
select im_priv_create('add_expenses','Accounting');

select im_priv_create('add_expense_invoice','Project Managers');
select im_priv_create('add_expense_invoice','Senior Managers');
select im_priv_create('add_expense_invoice','Sales');
select im_priv_create('add_expense_invoice','Accounting');

select im_priv_create('view_expenses','Project Managers');
select im_priv_create('view_expenses','Senior Managers');
select im_priv_create('view_expenses','Sales');
select im_priv_create('view_expenses','Accounting');

select im_priv_create('view_expenses_all','Project Managers');
select im_priv_create('view_expenses_all','Senior Managers');
select im_priv_create('view_expenses_all','Sales');
select im_priv_create('view_expenses_all','Accounting');


-------------------------------------------------------------
-- Expenses Menu System
--

create or replace function inline_0 ()
returns integer as'
declare
        -- Menu IDs
        v_menu                  integer;
        v_project_menu          integer;

        -- Groups

        v_accounting            integer;
        v_senman                integer;
        v_sales           	integer;
        v_proman                integer;

begin
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_sales from groups where group_name = ''Sales'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';

    select menu_id
    into v_project_menu
    from im_menus
    where label=''project'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-expenses'',      -- package_name
        ''project_expenses'',      -- label
        ''Expenses'',            -- name
        ''/intranet-expenses/index?view_name=not_used'',  -- url
        90,                     -- sort_order
        v_project_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_sales, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

-------------------------------------------------------------
-- Import common functionality

\i ../common/intranet-expenses-common.sql


-- /packages/intranet-expenses/sql/postgresql/upgrade/upgrade-3.2.1.0.0-3.2.2.0.0.sql

SELECT acs_log__debug('/packages/intranet-expenses/sql/postgresql/upgrade/upgrade-3.2.1.0.0-3.2.2.0.0.sql','');


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select  count(*) into v_count from user_tab_columns
	where   lower(table_name) = ''im_expenses'' and lower(column_name) = ''external_company_vat_number'';
	if v_count = 1 then return 0; end if;

	alter table im_expenses
	add external_company_vat_number varchar(50);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





-------------------------------------------------------
-- Reload the object methods
-------------------------------------------------------

-- Delete a single expense (if we know its ID...)
create or replace function im_expense__delete (integer)
returns integer as '
DECLARE
	p_expense_id alias for $1;		 -- expense_id
begin
	-- Erase the im_expenses entry
	delete from	im_expenses
	where		expense_id = p_expense_id;

	-- Erase the object
	PERFORM im_cost__delete(p_expense_id);
	return 0;
end' language 'plpgsql';


create or replace function im_expense__name (integer)
returns varchar as '
DECLARE
	p_expenses_id  alias for $1;	-- expense_id
	v_name  varchar;
begin
	select	cost_name
	into	v_name
	from	im_costs
	where	cost_id = p_expense_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_expense__new (
	integer, varchar, timestamptz, integer,
	varchar, integer, varchar, integer,
	timestamptz, char(3), integer, integer,
	integer, integer, numeric, numeric,
	numeric, varchar, varchar, varchar,
	varchar, integer, char(1), numeric,
	integer, integer, integer
) returns integer as '
declare
	p_expense_id		alias for $1;	-- expense_id default null
	p_object_type		alias for $2;	-- object_type default ''im_expense''
	p_creation_date		alias for $3;	-- creation_date default now()
	p_creation_user		alias for $4;	-- creation_user
	p_creation_ip		alias for $5;	-- creation_ip default null
	p_context_id		alias for $6;	-- context_id default null

	p_expense_name		alias for $7;	-- expense_name
	p_project_id		alias for $8;	-- project_id
	
	p_expense_date		alias for $9;	-- expense_date now()
	p_expense_currency	alias for $10;	-- expense_currency default ''EUR''
	p_expense_template_id   alias for $11;	-- expense_template_id default null
	p_expense_status_id     alias for $12;	-- expense_status_id default 602
	p_cost_type_id		alias for $13;	-- expense_type_id default 700
	p_payment_days		alias for $14;	-- payment_days default 30
	p_amount		alias for $15;	-- amount
	p_vat			alias for $16;	-- vat default 0
	p_tax			alias for $17;	-- tax default 0
	p_note			alias for $18;	-- note
	
	p_external_company_name alias for $19;	-- hotel name, taxi, ...
	p_external_company_vat_number alias for $20;	-- hotel name, taxi, ...
	p_receipt_reference	alias for $21;	-- receipt reference
	p_expense_type_id	alias for $22;	-- expense type default null
	p_billable_p		alias for $23;	-- is billable to client 
	p_reimbursable		alias for $24;	-- % reibursable from amount value
	p_expense_payment_type_id alias for $25; -- credit card used to pay, ...
	p_customer_id 		alias for $26;	-- customer_id
	p_provider_id 		alias for $27;	-- provider_id
	
	v_expense_id		integer;
    begin
	v_expense_id := im_cost__new (
		p_expense_id,		-- cost_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id,		-- context_id

		p_expense_name,		-- cost_name
		null,			-- parent_id
		p_project_id,		-- project_id
		p_customer_id, 		-- company_id
		p_provider_id,		-- provider_id
		null,			-- investment_id

		p_expense_status_id,	-- cost_status_id
		p_cost_type_id,		-- cost_type_id
		p_expense_template_id,	-- template_id

		p_expense_date,		-- effective_date
		p_payment_days,		-- payment_days
		p_amount,		-- amount
		p_expense_currency,     -- currency
		p_vat,			-- v
		p_tax,			-- tax

		''f'',			-- variable_cost_p
		''f'',			-- needs_redistribution_p
		''f'',			-- redistributed_p
		''f'',			-- planning_p
		null,			-- planning_type_id

		p_note,			-- note
		null			-- description
	);

	insert into im_expenses (
		expense_id,
		external_company_name,
		receipt_reference,
		expense_type_id,
		billable_p,
		reimbursable,
		expense_payment_type_id
	) values (
		v_expense_id,
		p_external_company_name,
		p_receipt_reference,
		p_expense_type_id,
		p_billable_p,
		p_reimbursable,
		p_expense_payment_type_id
	);

	return v_expense_id;
end;' language 'plpgsql';




-------------------------------------------------------
-- Expenses Menu in Main Finance Section
-------------------------------------------------------

create or replace function inline_0 ()
returns integer as'
declare
	-- Menu IDs
	v_menu			integer;
	v_finance_menu		integer;

	-- Groups
	v_accounting		integer;
	v_senman		integer;
	v_sales			integer;
	v_proman		integer;
begin
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_sales from groups where group_name = ''Sales'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';

    select menu_id
    into v_finance_menu
    from im_menus
    where label=''finance'';

    v_menu := im_menu__new (
	null,			-- p_menu_id
	''im_menu'',		-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	''intranet-expenses'',	-- package_name
	''finance_expenses'',	-- label
	''Expenses'',		-- name
	''/intranet-expenses/index'',  -- url
	90,			-- sort_order
	v_finance_menu,	-- parent_menu_id
	null			-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_sales, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- upgrade-3.4.0.1.0-3.4.0.2.0.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-invoices/sql/postgresql/upgrade/upgrade-3.4.0.1.0-3.4.0.2.0.sql','');


create or replace function inline_0 ()
returns integer as '
DECLARE
	v_count		integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where table_name = ''IM_TIMESHEET_INVOICES'' and column_name = ''INVOICE_PERIOD_START'';
	IF v_count > 0 THEN return 0; END IF;

	-- Start and end date of invoicing period
	alter table im_timesheet_invoices add invoice_period_start timestamptz;
	alter table im_timesheet_invoices add invoice_period_end timestamptz;

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();




create or replace function inline_0 ()
returns integer as '
DECLARE
	v_count		integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_hours'' and lower(column_name) = ''invoice_id'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_hours add invoice_id integer
		constraint im_hours_invoice_fk references im_costs;

	-- copy the cost_id values to invoice_id
	-- for all real invoices
	update	im_hours set invoice_id = cost_id
	where	cost_id in (
			select	cost_id
			from	im_costs
			where	cost_type_id = 3700
		);

	update	im_hours set cost_id = null
	where	cost_id in (
			select	cost_id
			from	im_costs
			where	cost_type_id = 3700
		);

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();


-- Delete a single invoice (if we know its ID...)
create or replace function  im_timesheet_invoice__delete (integer)
returns integer as '
DECLARE
	p_invoice_id	alias for $1;
BEGIN
	-- Reset the invoiced-flag of all invoiced tasks
	update	im_timesheet_tasks
	set	invoice_id = null
	where	invoice_id = p_invoice_id;

	-- Reset the invoiced-flag of all included hours
	update	im_hours
	set	invoice_id = null
	where	invoice_id = p_invoice_id;

	-- Compatibility for old invoices where cost_id
	-- indicated that hours belong to invoice
	update	im_hours
	set	cost_id = null
	where	cost_id = p_invoice_id;

	-- Erase the invoice itself
	delete from	im_timesheet_invoices
	where		invoice_id = p_invoice_id;

	-- Erase the CostItem
	PERFORM im_invoice__delete(p_invoice_id);

	return 0;
end;' language 'plpgsql';

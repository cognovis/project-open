-- upgrade-3.3.1.1.0-3.3.1.2.0.sql

update acs_object_types set status_column = 'cost_status_id' where object_type = 'im_expense';
update acs_object_types set type_column = 'cost_type_id' where object_type = 'im_expense';
update acs_object_types set status_type_table = 'im_costs' where object_type = 'im_expense';



-------------------------------------------------------------
-- Expense Invoice 

SELECT acs_object_type__create_type (
	'im_expense_invoice',		-- object_type
	'Expense Bundle',		-- pretty_name
	'Expense Bundles',		-- pretty_plural
	'im_cost',			-- supertype
	'im_expense_invoices',		-- table_name
	'invoice_id',			-- id_column
	'intranet-expenses',		-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_expense_invoice__name'	-- name_method
);


update acs_object_types set status_column = 'cost_status_id' where object_type = 'im_expense_invoice';
update acs_object_types set type_column = 'cost_type_id' where object_type = 'im_expense_invoice';
update acs_object_types set status_type_table = 'im_costs' where object_type = 'im_expense_invoice';



create table im_expense_invoices (
	invoice_id		 integer
				constraint im_expense_invoice_id_pk
				primary key
				constraint im_expense_invoice_id_fk
				references im_costs
);


-- Delete a single expense_invoice by ID
create or replace function im_expense_invoice__delete (integer)
returns integer as '
DECLARE
	p_invoice_id		alias for $1;
begin
	-- Erase the im_expense_invoices entry
	delete from im_expense_invoices
	where invoice_id = p_invoice_id;

	-- Erase the object
	PERFORM im_cost__delete(p_invoice_id);
	return 0;
end' language 'plpgsql';


create or replace function im_expense_invoice__name (integer)
returns varchar as '
DECLARE
	p_expenses_id		alias for $1;
	v_name			varchar(40);
begin
	select	cost_name into v_name
	from	im_costs
	where	cost_id = p_expenses_id;

	return v_name;
end;' language 'plpgsql';

-- No create script yet - Just create a cost itema and add an 
-- entry into im_expense_invoices. No idea yet what additional
-- fields we'll need soon...
--
-- create or replace function im_expense_invoice__new (


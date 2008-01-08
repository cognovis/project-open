-- upgrade-3.3.1.1.0-3.3.1.2.0.sql


update im_categories set category = 'Expense Bundle' where category_id = 3722;

update acs_object_types set status_column = 'cost_status_id' where object_type = 'im_expense';
update acs_object_types set type_column = 'cost_type_id' where object_type = 'im_expense';
update acs_object_types set status_type_table = 'im_costs' where object_type = 'im_expense';




-------------------------------------------------------------
-- Expense Bundle 

SELECT acs_object_type__create_type (
	'im_expense_bundle',		-- object_type
	'Expense Bundle',		-- pretty_name
	'Expense Bundles',		-- pretty_plural
	'im_cost',			-- supertype
	'im_expense_bundles',		-- table_name
	'bundle_id',			-- id_column
	'intranet-expenses-bundle',	-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_expense_bundle__name'	-- name_method
);


update acs_object_types set status_column = 'cost_status_id' where object_type = 'im_expense_bundle';
update acs_object_types set type_column = 'cost_type_id' where object_type = 'im_expense_bundle';
update acs_object_types set status_type_table = 'im_costs' where object_type = 'im_expense_bundle';



create table im_expense_bundles (
	bundle_id		 integer
				constraint im_expense_bundle_id_pk
				primary key
				constraint im_expense_bundle_id_fk
				references im_costs
);


-- Delete a single expense_bundle by ID
create or replace function im_expense_bundle__delete (integer)
returns integer as '
DECLARE
	p_bundle_id		alias for $1;
begin
	-- Erase the im_expense_bundles entry
	delete from im_expense_bundles
	where bundle_id = p_bundle_id;

	-- Erase the object
	PERFORM im_cost__delete(p_bundle_id);
	return 0;
end' language 'plpgsql';


create or replace function im_expense_bundle__name (integer)
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
-- entry into im_expense_bundles. No idea yet what additional
-- fields we'll need soon...
--
-- create or replace function im_expense_bundle__new (





-------------------------------------------------------
-- Expenses Menu in Main Finance Section
-------------------------------------------------------

SELECT im_new_menu ('intranet-expenses', 'expenses', 'Expenses', '/intranet-expenses/', 200, 'main', '');


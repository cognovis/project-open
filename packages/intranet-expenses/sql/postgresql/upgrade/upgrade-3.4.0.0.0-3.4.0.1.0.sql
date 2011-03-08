-- upgrade-3.4.0.0.0-3.4.0.1.0.sql

SELECT acs_log__debug('/packages/intranet-expenses/sql/postgresql/upgrade/upgrade-3.4.0.0.0-3.4.0.1.0.sql','');



create or replace function im_expense__name (integer)
returns varchar as '
DECLARE
        p_expenses_id  alias for $1;    -- expense_id
        v_name  varchar;
begin
        select  cost_name
        into    v_name
        from    im_costs
        where   cost_id = p_expenses_id;

        return v_name;
end;' language 'plpgsql';



create or replace function im_expense_bundle__name (integer)
returns varchar as '
DECLARE
        p_expenses_id           alias for $1;
        v_name                  varchar;
begin
        select  cost_name into v_name
        from    im_costs
        where   cost_id = p_expenses_id;

        return v_name;
end;' language 'plpgsql';





update im_categories set category = 'Expense Bundle' where category_id = 3722;

update acs_object_types set status_column = 'cost_status_id' where object_type = 'im_expense';
update acs_object_types set type_column = 'cost_type_id' where object_type = 'im_expense';
update acs_object_types set status_type_table = 'im_costs' where object_type = 'im_expense';


-------------------------------------------------------------



create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from user_tab_columns
	where table_name = ''IM_EXPENSES'' and column_name = ''BUNDLE_ID'';
        if v_count > 0 then return 0; end if;

	alter table im_expenses add bundle_id integer references im_costs;
	update im_expenses set bundle_id = invoice_id;
	alter table im_expenses drop column invoice_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-------------------------------------------------------------
-- Expense Bundle 



create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from acs_object_types
	where  object_type = ''im_expense_bundle'';
        if v_count > 0 then return 0; end if;

	PERFORM acs_object_type__create_type (
		''im_expense_bundle'',		-- object_type
		''Expense Bundle'',		-- pretty_name
		''Expense Bundles'',		-- pretty_plural
		''im_cost'',			-- supertype
		''im_expense_bundles'',		-- table_name
		''bundle_id'',			-- id_column
		''intranet-expenses-bundle'',	-- package_name
		''f'',				-- abstract_p
		null,				-- type_extension_table
		''im_expense_bundle__name''	-- name_method
	);

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




update acs_object_types set status_column = 'cost_status_id' where object_type = 'im_expense_bundle';
update acs_object_types set type_column = 'cost_type_id' where object_type = 'im_expense_bundle';
update acs_object_types set status_type_table = 'im_costs' where object_type = 'im_expense_bundle';




create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from im_biz_object_urls
	where object_type = ''im_expense_bundle'';
        if v_count > 0 then return 0; end if;

	insert into im_biz_object_urls (object_type, url_type, url) values (
	''im_expense_bundle'',''view'',''/intranet-expenses/bundle-new?form_mode=display&bundle_id='');
	insert into im_biz_object_urls (object_type, url_type, url) values (
	''im_expense_bundle'',''edit'',''/intranet-expenses/bundle-new?bundle_id='');

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from user_tab_columns
	where table_name = ''IM_EXPENSE_BUNDLES'';
        if v_count > 0 then return 0; end if;

	create table im_expense_bundles (
		bundle_id		 integer
					constraint im_expense_bundle_id_pk
					primary key
					constraint im_expense_bundle_id_fk
					references im_costs
	);

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



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
	v_name			varchar;
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






create or replace view im_expense_type as
select
	category_id as expense_type_id,
	category as expense_type
from 	im_categories
where	category_type = 'Intranet Expense Type'
	and (enabled_p is null OR enabled_p = 't');

create or replace view im_expense_payment_type as
select	category_id as expense_payment_type_id, 
	category as expense_payment_type
from 	im_categories
where 	category_type = 'Intranet Expense Payment Type'
	and (enabled_p is null OR enabled_p = 't');


-- Really ugly stuff. But Accounting needs to be able to fix stuff.
select acs_privilege__create_privilege('edit_bundled_expense_items','Edit Bundled Expenses','Edit Bundled Expenses');
select acs_privilege__add_child('admin', 'edit_bundled_expense_items');

select im_priv_create('edit_bundled_expense_items','Accounting');



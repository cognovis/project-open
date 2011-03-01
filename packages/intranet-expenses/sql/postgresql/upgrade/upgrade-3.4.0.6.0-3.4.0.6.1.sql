-- upgrade-3.4.0.6.0-3.4.0.6.1.sql

SELECT acs_log__debug('/packages/intranet-expenses/sql/postgresql/upgrade/upgrade-3.4.0.6.0-3.4.0.6.1.sql','');



create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
	-- im_expense is a sub-type of im_costs, so it needs to define both
	-- tables as "extension tables".

        select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_expense'' and table_name = ''im_expenses'';
        IF v_count = 0 THEN

		insert into acs_object_type_tables (object_type,table_name,id_column)
		values (''im_expense'', ''im_expenses'', ''expense_id'');

	END IF;

        select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_expense'' and table_name = ''im_costs'';
        IF v_count = 0 THEN

		insert into acs_object_type_tables (object_type,table_name,id_column)
		values (''im_expense'', ''im_costs'', ''cost_id'');

	END IF;


        select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_expense'' and table_name = ''im_costs'';
        IF v_count = 0 THEN

		insert into acs_object_type_tables (object_type,table_name,id_column)
		values (''im_expense'', ''im_costs'', ''cost_id'');

	END IF;


	-- im_expense_bundle is a sub-type of im_costs, so it needs to define
	-- both tables as "extension tables".
        select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_expense_bundle'' and table_name = ''im_expense_bundles'';
        IF v_count = 0 THEN

		insert into acs_object_type_tables (object_type,table_name,id_column)
		values (''im_expense_bundle'', ''im_expense_bundles'', ''bundle_id'');

	END IF;

        select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_expense_bundle'' and table_name = ''im_costs'';
        IF v_count = 0 THEN

		insert into acs_object_type_tables (object_type,table_name,id_column)
		values (''im_expense_bundle'', ''im_costs'', ''cost_id'');

	END IF;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

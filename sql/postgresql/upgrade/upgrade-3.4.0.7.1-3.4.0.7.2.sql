-- upgrade-3.4.0.7.1-3.4.0.7.2.sql

SELECT acs_log__debug('/packages/intranet-cost/sql/postgresql/upgrade/upgrade-3.4.0.7.1-3.4.0.7.2.sql','');





create or replace function inline_0()
returns integer as '
DECLARE
        v_count			integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_costs'' and lower(column_name) = ''vat_type_id'';
	IF v_count > 0 THEN return 1; END IF;

	alter table im_costs 
	add column vat_type_id	integer
				constraint im_cost_vat_type_fk
				references im_categories;


        return 0;
END;' language 'plpgsql';
select inline_0();
drop function inline_0();


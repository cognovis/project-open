-- upgrade-3.2.10.0.0-3.2.11.0.0.sql

SELECT acs_log__debug('/packages/intranet-trans-invoices/sql/postgresql/upgrade/upgrade-3.2.11.0.0-3.2.12.0.0.sql','');


create or replace function inline_0 ()
returns integer as '
DECLARE
	v_count		integer;
BEGIN
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_trans_prices'' and lower(column_name) = ''min_price'';
	IF v_count > 0 THEN return 1; END IF;

	alter table im_trans_prices add min_price numeric(12,4);

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();






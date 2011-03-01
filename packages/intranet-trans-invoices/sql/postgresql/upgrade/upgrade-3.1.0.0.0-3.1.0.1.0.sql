-- upgrade from 3.0.0.4.0 to 3.1.0.0.0

SELECT acs_log__debug('/packages/intranet-trans-invoices/sql/postgresql/upgrade/upgrade-3.1.0.0.0-3.1.0.1.0.sql','');



create or replace function inline_0 ()
returns integer as '
DECLARE
	v_count		integer;
BEGIN
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_trans_prices'' and lower(column_name) = ''note'';
	IF v_count > 0 THEN return 0; END IF;

	ALTER TABLE im_trans_prices ADD note text;

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();




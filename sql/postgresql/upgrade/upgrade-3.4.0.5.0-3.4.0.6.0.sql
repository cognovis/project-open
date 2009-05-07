-- upgrade-3.4.0.5.0-3.4.0.6.0.sql

SELECT acs_log__debug('/packages/intranet-material/sql/postgresql/upgrade/upgrade-3.4.0.5.0-3.4.0.6.0.sql','');


create or replace function inline_0 ()
returns integer as '
DECLARE
	v_count		integer;
BEGIN
	select	count(*) into v_count
	from	user_tab_columns
	where	lower(table_name) = ''im_materials''
		and lower(column_name) = ''material_billable_p'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_materials add
	material_billable_p	char(1);

	alter table im_materials add
	constraint im_materials_billable_ck
	check (material_billable_p in (''t'',''f''));

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();


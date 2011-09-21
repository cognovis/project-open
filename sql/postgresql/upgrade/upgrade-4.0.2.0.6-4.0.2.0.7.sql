-- upgrade-4.0.2.0.6-4.0.2.0.7.sql

SELECT acs_log__debug('/packages/intranet-audit/sql/postgresql/upgrade/upgrade-4.0.2.0.6-4.0.2.0.7.sql','');



create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where  lower(table_name) = 'im_projects_audit' and lower(column_name) = 'audit_id';
	IF v_count > 0 THEN return 1; END IF;

	alter table im_projects_audit
	add column audit_id integer;

	return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();


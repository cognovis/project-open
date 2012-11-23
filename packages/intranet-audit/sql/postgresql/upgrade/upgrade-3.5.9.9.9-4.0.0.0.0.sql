-- upgrade-3.5.9.9.9-4.0.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-audit/sql/postgresql/upgrade/upgrade-3.5.9.9.9-4.0.0.0.0.sql','');



-- Introduce audit_status_id field which receives the objects status
-- after the audit. This way, we can follow up on the object status
-- changes.
create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where  lower(table_name) = 'im_audits' and lower(column_name) = 'audit_object_status_id';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_audits 
	add column audit_object_status_id integer
	constraint im_audits_object_status_fk
	references im_categories;

	return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();

select im_component_plugin__delete(
	(select plugin_id from im_component_plugins where plugin_name = 'Earned Value' and package_name = 'intranet-audit')
);

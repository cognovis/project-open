-- upgrade-3.5.9.9.9-4.0.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.5.9.9.9-4.0.0.0.0.sql','');




create or replace function inline_0 ()
returns integer as $body$
declare
        v_count                 integer;
begin
        select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'apm_package_types' and lower(column_name) = 'inherit_templates_p';
        IF v_count = 0 THEN
		alter table apm_package_types
		add column inherit_templates_p boolean default 't'
			constraint inherit_templates_p_nn
			not null;
	END IF;

        select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'apm_package_types' and lower(column_name) = 'implements_subsite_p';
        IF v_count = 0 THEN
		alter table apm_package_types
		add column implements_subsite_p boolean default 'f'
			constraint apm_packages_impl_subs_p_nn
			not null;
	END IF;

        select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'apm_package_types' and lower(column_name) = 'implements_subsite_p';
        IF v_count = 0 THEN
		alter table apm_parameters
		add column scope varchar(10) default 'instance'
			constraint apm_parameters_scope_ck
			check (scope in ('global','instance'))
			constraint apm_parameters_scope_nn
			not null;
	END IF;


        return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




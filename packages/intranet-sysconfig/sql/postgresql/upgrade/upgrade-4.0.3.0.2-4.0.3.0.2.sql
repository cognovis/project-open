-- upgrade-4.0.3.0.2-4.0.3.0.2.sql

SELECT acs_log__debug('/packages/intranet-sysconfig/sql/postgresql/upgrade/upgrade-4.0.3.0.2-4.0.3.0.2.sql','');




-------------------------------------------------------------
-- Return permissions on an object in human readable form
--

create or replace function im_sysconfig_display_permissions (integer)
returns varchar as $body$
declare
	p_object_id		alias for $1;
	v_result		varchar;
	row			record;
begin
	v_result := '';
	FOR row IN
		select	ap.*
		from	acs_permissions ap
		where	ap.object_id = p_object_id
		order by ap.grantee_id
	LOOP
		IF v_result != '' THEN v_result := v_result || ', '; END IF;
		v_result := v_result || coalesce(acs_object__name(row.grantee_id), '') || ':' || row.privilege;
	END LOOP;

	return v_result;
end;$body$ language 'plpgsql';



create or replace function im_sysconfig_display_privileges (varchar)
returns varchar as $body$
declare
	p_priv			alias for $1;
	v_result		varchar;
	row			record;
begin
	v_result := '';
	FOR row IN
		select distinct	ap.grantee_id
		from	acs_permissions ap
		where	ap.privilege = p_priv and
			ap.object_id in (
        			select min(object_id) from acs_objects
				where object_type = 'apm_service'
			)
	LOOP
		IF v_result != '' THEN v_result := v_result || ', '; END IF;
		v_result := v_result || coalesce(acs_object__name(row.grantee_id), '');
	END LOOP;

	return v_result;
end;$body$ language 'plpgsql';

select im_sysconfig_display_privileges('view_costs');



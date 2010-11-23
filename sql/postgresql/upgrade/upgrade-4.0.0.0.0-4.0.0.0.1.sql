-- upgrade-4.0.0.0.0-4.0.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.0.0.0-4.0.0.0.1.sql','');

create or replace function im_name_from_id(double precision)
returns varchar as '
DECLARE
	v_result	alias for $1;
BEGIN
	return v_result::varchar;
END;' language 'plpgsql';

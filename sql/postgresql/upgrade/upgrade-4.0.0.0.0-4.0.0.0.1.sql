-- upgrade-4.0.0.0.0-4.0.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.0.0.0-4.0.0.0.1.sql','');

create or replace function im_name_from_id(double precision)
returns varchar as '
DECLARE
	v_result	alias for $1;
BEGIN
	return v_result::varchar;
END;' language 'plpgsql';



-- Fixed issue deleting authorities by
-- deleting parameters now
--
create or replace function authority__del (integer)
returns integer as '
declare
  p_authority_id            alias for $1;
begin

  delete from auth_driver_params
  where authority_id = p_authority_id;

  perform acs_object__delete(p_authority_id);

  return 0; 
end;' language 'plpgsql';



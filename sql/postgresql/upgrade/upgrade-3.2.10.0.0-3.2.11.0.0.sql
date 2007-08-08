-- upgrade-3.2.10.0.0-3.2.11.0.0.sql



create or replace function im_integer_from_id(integer)
returns varchar as '
DECLARE
        v_result        alias for $1;
BEGIN
        return v_result::varchar;
END;' language 'plpgsql';


create or replace function im_integer_from_id(varchar)
returns varchar as '
DECLARE
        v_result        alias for $1;
BEGIN
        return v_result;
END;' language 'plpgsql';


create or replace function im_integer_from_id(numeric)
returns varchar as '
DECLARE
        v_result        alias for $1;
BEGIN
        return v_result::varchar;
END;' language 'plpgsql';






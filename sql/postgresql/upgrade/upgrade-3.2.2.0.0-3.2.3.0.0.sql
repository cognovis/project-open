-- upgrade-3.2.3.0.0-3.2.3.0.0.sql


create or replace function im_country_from_code (varchar)
returns varchar as '
DECLARE
        p_cc            alias for $1;
        v_country       varchar;
BEGIN
    select country_name
    into v_country
    from country_codes
    where iso = p_cc;

    return v_country;
END;' language 'plpgsql';


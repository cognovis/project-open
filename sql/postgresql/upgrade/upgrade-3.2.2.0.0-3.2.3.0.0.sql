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


SELECT pg_catalog.setval('im_categories_seq', 10000000, true);



-- Update the security tokensof the local server 
-- Users might be a way to gain access if the tokens are
-- publicly known (from the default installation)

delete from secret_tokens;
SELECT pg_catalog.setval('t_sec_security_token_id_seq', 1, true);


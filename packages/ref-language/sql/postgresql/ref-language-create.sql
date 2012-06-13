-- packages/ref-language/sql/postgresql/language.sql
--
-- @author jon@jongriffin.com
-- @creation-date 2000-11-21
-- @cvs-id $Id$
--


-- ISO 639

-- fraber 110322: language_codes already existed in ]po[ V3.4,
-- so we have to put a "v_count" around this creation here.

create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''language_codes'';
	IF v_count > 0 THEN return 1; END IF;

	create table language_codes (
	    language_id char(2)
	        constraint language_codes_language_id_pk
	        primary key,
	    name varchar(100)
	        constraint language_codes_name_nn
	        not null
	);

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



comment on table language_codes is '
    This is data from the ISO 639-1 standard on language codes.
';

comment on column language_codes.language_id is '
    This is the ISO standard language 2 chars code
';

comment on column language_codes.name is '
    This is the English version of the language name. 
';



-- Make sure the reference did not exist before
delete from acs_reference_repositories where table_name = 'LANGUAGE_CODES';

-- now register this table with the repository
select acs_reference__new(
    'LANGUAGE_CODES',
    null,
    'ISO 639-1',
    'http://www.iso.ch',
    now()
);

-- Languages ISO-639-2 codes

create table language_639_2_codes (
       iso_639_2            char(3) constraint language_codes_iso_639_2_pk primary key,
       iso_639_1            char(2),
       label                varchar(200)
);

comment on table language_639_2_codes is 'Contains ISO-639-2 language codes and their corresponding ISO-639-1 when it exists.';

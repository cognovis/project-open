-- upgrade-3.4.0.7.2-3.4.0.7.3.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.7.2-3.4.0.7.3.sql','');



-- Re-create the person__new function.
-- There was an issue with one SaaS customer where this routines
-- wasn't compiled correctly by PG for some reason.
--
create or replace function person__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,varchar,integer)
returns integer as '
declare
  new__person_id              alias for $1;  -- default null  
  new__object_type            alias for $2;  -- default ''person''
  new__creation_date          alias for $3;  -- default now()
  new__creation_user          alias for $4;  -- default null
  new__creation_ip            alias for $5;  -- default null
  new__email                  alias for $6;  
  new__url                    alias for $7;  -- default null
  new__first_names            alias for $8; 
  new__last_name              alias for $9;  
  new__context_id             alias for $10; -- default null 
  v_person_id                 persons.person_id%TYPE;
begin
  v_person_id :=
   party__new(new__person_id, new__object_type,
             new__creation_date, new__creation_user, new__creation_ip,
             new__email, new__url, new__context_id);

  insert into persons
   (person_id, first_names, last_name)
  values
   (v_person_id, new__first_names, new__last_name);

  return v_person_id;
  
end;' language 'plpgsql';
 


-- http://fisheye.openacs.org/browse/OpenACS/openacs-4/packages/ref-countries/sql/common/ref-country-data.sql?r=1.1
insert into country_codes (iso,country_name) values ('AN', 'Netherlands Antilles');
insert into country_codes (iso,country_name) values ('NP', 'Nepal');
insert into country_codes (iso,country_name) values ('MK', 'Macedonia, TFYRO');
insert into country_codes (iso,country_name) values ('KP', 'Korea, Democratic People''s Republic Of');
insert into country_codes (iso,country_name) values ('KR', 'Korea, Republic Of');
insert into country_codes (iso,country_name) values ('AM', 'Armenia');
insert into country_codes (iso,country_name) values ('KY', 'Cayman Islands'); 
insert into country_codes (iso,country_name) values ('PA', 'Panama');


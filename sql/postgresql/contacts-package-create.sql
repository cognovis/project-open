-- contacts-package-create.sql
--
-- @author Matthew Geddert openacs@geddert.com
-- @creation-date 2004-07-28
-- @cvs-id $Id$
--
--



create or replace function contact__name (
        varchar,                -- first_names
        varchar,                -- last_name
        varchar,                -- organization
        boolean                 -- recursive_p
) returns varchar 
as '
declare
        p_first_names           alias for $1;
        p_last_name             alias for $2;
        p_organization          alias for $3;
        p_recursive_p           alias for $4;
        v_name                  varchar;
begin

        if p_recursive_p then
           if p_first_names is null and p_last_name is null then
              v_name := p_organization;
           else
              v_name := p_last_name;
              if p_first_names is not null and p_last_name is not null then
                 v_name := v_name || '', '';
              end if;
              v_name := v_name || p_first_names;
          end if;
        else 
           if p_first_names is null and p_last_name is null then
              v_name := p_organization;
           else
              v_name := p_first_names;
              if p_first_names is not null and p_last_name is not null then
                 v_name := v_name || '' '';
              end if;
              v_name := v_name || p_last_name;
          end if;
        end if;

        return v_name;
end;' language 'plpgsql';

create or replace function contact__name (
        integer                 -- party_id
) returns varchar 
as '
declare
        p_party_id              alias for $1;
        v_name                  varchar;
begin
        v_name := im_name_from_id(p_party_id);

        return v_name;
end;' language 'plpgsql';

create or replace function contact__name (
        integer,                -- party_id
        boolean                 -- recursive_p  
) returns varchar 
as '
declare
        p_party_id              alias for $1;
        p_recursive_p           alias for $2;
        v_name                  varchar;
begin

        select name
          into v_name
          from organizations where organization_id = p_party_id;

        if v_name is null then

        if p_recursive_p = ''t'' then
          select last_name || '', '' || first_names
          into v_name
          from persons where person_id = p_party_id;
        else 
          select first_names || '' '' || last_name
          into v_name
          from persons where person_id = p_party_id;
        end if;

        end if;
        return v_name;
end;' language 'plpgsql';

create or replace function contact_group__member_count (
        integer                 -- group_id
) returns integer 
as '
declare
        p_group_id              alias for $1;
        v_member_count          integer;
begin
        v_member_count := count(*) from group_distinct_member_map where group_id = p_group_id ;

        return v_member_count;
end;' language 'plpgsql';


create or replace function contact_group__member_p (integer,integer) returns boolean 
as '
declare
        p_group_id              alias for $1;
        p_member_id             alias for $2;
        v_member_p              boolean;
begin

        v_member_p := ''1'' from group_distinct_member_map where group_id = p_group_id and member_id = p_member_id;

        if v_member_p is true then
           v_member_p := ''1'';
        else
           v_member_p := ''0'';
        end if;

        return v_member_p;
end;' language 'plpgsql';


-- create functions for organization_rels
select define_function_args('organization_rel__new','rel_id,rel_type;organization_rel,object_id_one,object_id_two,creation_user,creation_ip');

create or replace function organization_rel__new (integer,varchar,integer,integer,integer,varchar)
returns integer as '
declare
  new__rel_id            alias for $1;  -- default null  
  rel_type               alias for $2;  -- default ''organization_rel''
  object_id_one          alias for $3;  
  object_id_two          alias for $4;  
  creation_user          alias for $5;  -- default null
  creation_ip            alias for $6;  -- default null
  v_rel_id               integer;       
begin
    v_rel_id := acs_rel__new (
      new__rel_id,
      rel_type,
      object_id_one,
      object_id_two,
      object_id_one,
      creation_user,
      creation_ip
    );

    return v_rel_id;
   
end;' language 'plpgsql';

-- function new
create or replace function organization_rel__new (integer,integer)
returns integer as '
declare
  object_id_one          alias for $1;  
  object_id_two          alias for $2;  
begin
        return organization_rel__new(null,
                                    ''organization_rel'',
                                    object_id_one,
                                    object_id_two,
                                    null,
                                    null);
end;' language 'plpgsql';

-- procedure delete
create or replace function organization_rel__delete (integer)
returns integer as '
declare
  rel_id                 alias for $1;  
begin
    PERFORM acs_rel__delete(rel_id);

    return 0; 
end;' language 'plpgsql';

-- procedure for dates
create or replace function contacts_util__next_instance_of_date(timestamptz)
returns date as '
declare
        p_date          alias for $1;
        v_years         integer;
        v_next_instance date;
begin

    v_years := extract(year from now()) - extract(year from p_date);

    v_next_instance := p_date + (v_years::varchar || '' years'')::interval;

    -- if this already happend we and one more year
    if v_next_instance::date < now()::date then
        v_next_instance := v_next_instance + ''1 year''::interval;
    end if;

    return v_next_instance;
end;' language 'plpgsql';
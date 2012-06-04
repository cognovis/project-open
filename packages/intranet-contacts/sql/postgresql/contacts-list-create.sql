-- contacts-lists-create.sql
--
-- @author Matthew Geddert openacs@geddert.com
-- @creation-date 2006-06-25
-- @cvs-id $Id$
--
--

create table contact_lists (
        list_id         integer primary key
                        constraint contact_lists_list_id_fk 
			references acs_objects(object_id) on delete cascade
);

-- a list can have many owners to allow collaboration

create table contact_list_members (
        list_id         integer not null
                        constraint contact_list_members_list_id_fk 
			references contact_lists(list_id) on delete cascade,
        party_id        integer not null
                        constraint contact_list_members_party_id_fk 
			references parties(party_id) on delete cascade,
        unique(list_id,party_id)
);


select acs_object_type__create_type (
   'contact_list',           -- content_type
   'Contact List',           -- pretty_name 
   'Contact Lists',          -- pretty_plural
   'acs_object',             -- supertype
   'contact_lists',          -- table_name
   'list_id',                -- id_column 
   'contact_list',           -- package_name
   'f',                      -- abstract_p
   NULL,                     -- type_extension_table
   NULL                      -- name_method
);



select define_function_args('contact_list__new','list_id,title,package_id,creation_date;now(),creation_user,creation_ip,context_id');

create or replace function contact_list__new (integer,varchar,integer,timestamptz,integer,varchar,integer)
returns integer as '
declare
        p_list_id            alias for $1;
        p_title              alias for $2;
        p_package_id         alias for $3;
        p_creation_date      alias for $4;
        p_creation_user      alias for $5;
        p_creation_ip        alias for $6;
        p_context_id         alias for $7;
        v_list_id            integer;
begin

        v_list_id := acs_object__new(
                p_list_id,
                ''contact_list'',
                p_creation_date,
                p_creation_user,
                p_creation_ip,
                coalesce(p_context_id, p_package_id),
                ''t'',
                p_title,
                p_package_id
        );

	update acs_objects set title = p_title where object_id = v_list_id;

        insert into contact_lists
                (list_id)
        values
                (v_list_id);

        return v_list_id;
end;' language 'plpgsql';

select define_function_args('contact_list__delete','list_id');

create or replace function contact_list__delete (integer)
returns integer as '
declare
        p_list_id           alias for $1;
begin

        delete from contact_list_members where list_id = p_list_id;
        delete from contact_lists where list_id = p_list_id;
        perform acs_object__delete(p_list_id);

        return ''0'';
end;' language 'plpgsql';






create table contact_owner_rels (
	rel_id		integer primary key
			constraint contact_owner_rels_rel_id_fk 
			references acs_rels(rel_id) on delete cascade
);

create view contact_owners as
  select object_id_one as object_id,
         object_id_two as owner_id
    from acs_rels,
         contact_owner_rels
   where acs_rels.rel_id = contact_owner_rels.rel_id;


select acs_rel_type__create_type (
        'contact_owner',
        'Contact Object Owner',
        'Contact Object Owner',
        'relationship',
        'contact_owner_rels',
        'rel_id',
        'contact_owner',
        'acs_object',
        null, 
        0, 
        null,
        'acs_object', 
        null,
        0, 
        null
    );

select define_function_args('contact_owner__new','rel_id,rel_type;contact_owner,object_id_one,object_id_two,creation_user,creation_ip');

create function contact_owner__new(integer,varchar,integer,integer,integer,varchar)
returns integer as '
DECLARE
        p_rel_id                alias for $1;
        p_rel_type              alias for $2;
        p_object_id_one         alias for $3;
        p_object_id_two         alias for $4;
        p_creation_user         alias for $5;
        p_creation_ip           alias for $6;
        v_rel_id                integer;
BEGIN
        v_rel_id:= acs_rel__new(
            p_rel_id,
            p_rel_type,
            p_object_id_one,
            p_object_id_two,
            null,
            p_creation_user,
            p_creation_ip
        );

        insert
        into contact_owner_rels
        (rel_id)
        values
        (v_rel_id);

        return v_rel_id;
END;
' language 'plpgsql';


select define_function_args('contact_owner__delete','rel_id');

create or replace function contact_owner__delete (integer)
returns integer as '
DECLARE
        p_rel_id                alias for $1;
BEGIN

        PERFORM acs_object__delete(p_rel_id);

        return 0;
END;
' language 'plpgsql';

    

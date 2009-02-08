-- contacts-search-create.sql
--
-- @author Matthew Geddert openacs@geddert.com
-- @creation-date 2004-07-28
-- @cvs-id $Id$
--
--

create table contact_searches (
        search_id               integer
                                constraint contact_searches_id_fk references acs_objects(object_id) on delete cascade
                                constraint contact_searches_id_pk primary key,
        owner_id                integer
                                constraint contact_searches_owner_id_fk references acs_objects(object_id) on delete cascade
                                constraint contact_searches_owner_id_nn not null,
        all_or_any              varchar(20)
                                constraint contact_searches_and_or_all_nn not null,
        object_type             varchar(1000)
                                constraint contact_searches_object_type_nn not null,
        deleted_p               boolean default 'f'
                                constraint contact_searches_deleted_p_nn not null,
	aggregated_attribute    integer
);

-- create the content type
select acs_object_type__create_type (
   'contact_search',              -- content_type
   'Contacts Search',             -- pretty_name 
   'Contacts Searches',           -- pretty_plural
   'acs_object',                  -- supertype
   'contact_searches',            -- table_name (should this be pm_task?)
   'search_id',                   -- id_column 
   'contact_search',              -- package_name
   'f',                           -- abstract_p
   NULL,                          -- type_extension_table
   NULL                           -- name_method
);

create table contact_search_conditions (
        condition_id            integer
                                constraint contact_search_conditions_id_pk primary key,
        search_id               integer
                                constraint contact_search_conditions_search_id_fk references contact_searches(search_id) on delete cascade
                                constraint contact_search_conditions_search_id_nn not null,
        type                    varchar(255)
                                constraint contact_search_conditions_type_nn not null,
        var_list                text
                                constraint contact_search_conditions_var_list_nn not null
);

create table contact_search_log (
        search_id               integer
                                constraint contact_search_log_search_id_fk references contact_searches(search_id) on delete cascade
                                constraint contact_search_logs_search_id_nn not null,
        user_id                 integer
                                constraint contact_search_log_user_id_fk references users(user_id) on delete cascade
                                constraint contact_search_log_user_id_nn not null,
        n_searches              integer
                                constraint contact_search_log_n_searches_nn not null,
        last_search             timestamptz
                                constraint contact_search_log_last_search_nn not null,
        unique(search_id,user_id)
);

select define_function_args ('contact_search__new', 'search_id,title,owner_id,all_or_any,object_type,deleted_p;f,creation_date,creation_user,creation_ip,context_id,package_id');

create or replace function contact_search__new (integer,varchar,integer,varchar,varchar,boolean,timestamptz,integer,varchar,integer,integer)
returns integer as '
declare
    p_search_id                     alias for $1;
    p_title                         alias for $2;
    p_owner_id                      alias for $3;
    p_all_or_any                    alias for $4;
    p_object_type                   alias for $5;
    p_deleted_p                     alias for $6;
    p_creation_date                 alias for $7;
    p_creation_user                 alias for $8;
    p_creation_ip                   alias for $9;
    p_context_id                    alias for $10;
    p_package_id                    alias for $11;
    v_search_id                     contact_searches.search_id%TYPE;
begin
    v_search_id := acs_object__new(
        p_search_id,
        ''contact_search'',
        p_creation_date,
        p_creation_user,
        p_creation_ip,
        coalesce(p_context_id, p_owner_id),
        ''1'',
        p_title,
        p_package_id
    );
    -- the acs_object__new proc is broken
    update acs_objects set title = p_title where object_id = v_search_id ;

    insert into contact_searches
    (search_id,owner_id,all_or_any,object_type,deleted_p)
    values
    (v_search_id,p_owner_id,p_all_or_any,p_object_type,p_deleted_p);

    return v_search_id;

end;' language 'plpgsql';



create or replace function contact_search__log (integer,integer)
returns integer as '
declare
    p_search_id                     alias for $1;
    p_user_id                       alias for $2;
    v_last_search_id                integer;
    v_exists_p                      boolean;
begin
    -- if the user has used this search in the last 60 minutes we do not log it as a new search
    v_last_search_id := search_id
                   from contact_search_log
                  where user_id = p_user_id
                    and last_search > now() - ''1 hour''::interval
                  order by last_search desc
                  limit 1;

    if v_last_search_id != p_search_id or v_last_search_id is null then
       -- this is a new search we need to log
       v_exists_p := ''1''::boolean
                from contact_search_log 
               where search_id = p_search_id
                 and user_id = p_user_id;

       if v_exists_p then
         update contact_search_log
            set n_searches = n_searches + 1,
                last_search = now()
          where search_id = p_search_id
            and user_id = p_user_id;
       else
         insert into contact_search_log
         (search_id,user_id,n_searches,last_search)
         values
         (p_search_id,p_user_id,''1''::integer,now());
       end if;
    else
       -- we just update the last search time but no n_sesions
       update contact_search_log
          set last_search = now()
        where search_id = p_search_id
          and user_id = p_user_id;
    end if;

    return ''1'';
end;' language 'plpgsql';


-- Create a sequence and a table for extended searches.

create sequence contact_extend_search_seq;

create table contact_extend_options (
	extend_id 	integer
			constraint contact_extend_options_pk primary key,
	var_name	varchar(100) unique not null,
	pretty_name	varchar(100) not null,
	subquery 	varchar(5000) not null,
	aggregated_p    char default 'f' constraint check_aggregate_p check (aggregated_p in ('t','f')),
	description     varchar(500)
);

-- Creates a table to map contact_extend_options(extend_id)'s to 
-- contact_searches(search_id)

create table contact_search_extend_map (
	search_id	integer
			constraint contact_search_extend_map_search_id_fk
			references contact_searches (search_id)
			on delete cascade,
	extend_id	integer
			constraint contact_search_extend_map_extend_id_fk
			references contact_extend_options (extend_id)
			on delete cascade,
	extend_column   varchar(255)
);

-- /packages/intranet-forum/sql/oracle/intranet-forum-pg-create.sql
--
-- Copyright (c) 2003-2005 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- FIXME need to load tsearch2.sql from postgresql/share/contrib
-- (on debian /usr/share/postgresql/contrib)


-- "Abbreviation" of object_type for search purposes -
-- we don't want to add a varchar(100) to the main search
-- table...
--
create table im_search_object_types (
	object_type_id	integer
			constraint im_search_object_types_pk
			primary key,
	object_type	varchar(100)
			constraint im_search_objects_object_type_fk
			references acs_object_types
			on delete cascade
);


-- The main search table with Full Text Index.
--
create table im_search_objects (
	object_id		integer
				constraint im_search_objects_object_id_fk
				references acs_objects
				on delete cascade,
				-- may include "object types" outside of OpenACS
				-- that are not in the "acs_object_types" table.
	object_type_id		integer
				constraint im_search_objects_object_type_id_fk
				references im_search_object_types
				on delete cascade,
				-- What is the topmost container for this object?
				-- Allows to speed up the elimination of objects
				-- that the current user can't access
	biz_object_id		integer
				constraint im_search_objects_biz_obj_id_fk
				references acs_objects
				on delete cascade,
				-- counter for number of accesses to this object
				-- either from the permission() proc or from
				-- reading in the server log file.
	hit_count		integer,
				-- Full Text Index
	fti			tsvector,
				-- For tables that don't respect the OpenACS object 
				-- scheme we may get "object_id"s that start with 0.
	primary key (object_id, object_type_id)
);

create index im_search_objects_fti_idx on im_search_objects using gist(fti);
create index im_search_objects_object_id_idx on im_search_objects (object_id);



create or replace function im_search_update (integer, varchar, integer, varchar)
returns integer as '
declare
	p_object_id	alias for $1;
	p_object_type	alias for $2;
	p_biz_object_id	alias for $3;
	p_text		alias for $4;

	v_object_type_id	integer;
	v_exists_p		integer;
begin
	select	object_type_id
	into	v_object_type_id
	from	im_search_object_types
	where	object_type = p_object_type;

	select	count(*)
	into	v_exists_p
	from	im_search_objects
	where	object_id = p_object_id
		and object_type_id = v_object_type_id;

	if v_exists_p = 1 then
		update im_search_objects set
			object_type_id	= v_object_type_id,
			biz_object_id	= p_biz_object_id,
			fti		= to_tsvector(''default'', p_text)
		where
			object_id	= p_object_id;
	else 
		insert into im_search_objects (
			object_id,
			object_type_id,
			biz_object_id,
			fti
		) values (
			p_object_id,
			v_object_type_id,
			p_biz_object_id,
			to_tsvector(''default'', p_text)
		);
	end if;

	return 0;
end;' language 'plpgsql';


-----------------------------------------------------------
-- im_project

insert into im_search_object_types values (0,'im_project');

create or replace function im_projects_tsearch () 
returns trigger as '
begin
	perform im_search_update(new.project_id, ''im_project'', 0, 
		coalesce(new.project_name, '''') || '' '' ||
		coalesce(new.project_nr, '''') || '' '' ||
		coalesce(new.project_path, '''') || '' '' ||
		coalesce(new.description, '''') || '' '' ||
		coalesce(new.note, '''') || '' '' ||
		coalesce(new.project_risk, '''')
	);
	return new;
end;' language 'plpgsql';

CREATE TRIGGER im_projects_tsearch_tr 
BEFORE INSERT or UPDATE
ON im_projects
FOR EACH ROW 
EXECUTE PROCEDURE im_projects_tsearch();



-----------------------------------------------------------
-- user

insert into im_search_object_types values (1,'user');

create or replace function users_tsearch () 
returns trigger as '
declare
	v_string	varchar;
begin
	select	coalesce(email, '''') || '' '' ||
		coalesce(url, '''') || '' '' ||
		coalesce(first_names, '''') || '' '' ||
		coalesce(last_name, '''') || '' '' ||
		coalesce(username, '''') || '' '' ||
		coalesce(screen_name, '''') || '' '' ||
		coalesce(username, '''')
	into	v_string
	from	cc_users
	where	user_id = new.user_id;

	perform im_search_update(new.user_id, ''user'', 0, v_string);
	return new;
end;' language 'plpgsql';

CREATE TRIGGER users_tsearch_tr 
BEFORE INSERT or UPDATE
ON users
FOR EACH ROW 
EXECUTE PROCEDURE users_tsearch();



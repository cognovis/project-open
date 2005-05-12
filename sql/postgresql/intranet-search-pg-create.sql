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

insert into im_search_object_types values (0,'im_project');



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




create or replace function im_search_insert (integer, varchar, integer, varchar)
returns integer as '
declare
	p_object_id	alias for $1;
	p_object_type	alias for $2;
	p_biz_object_id	alias for $3;
	p_text		alias for $4;

	v_object_type_id	integer;
        ts2_result		varchar;
begin
	select	object_type_id
	into	v_object_type_id
	from	im_search_object_types
	where	object_type = p_object_type;

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

	return 0;
end;' language 'plpgsql';


create or replace function im_search_update (integer, varchar, integer, varchar)
returns integer as '
declare
	p_object_id	alias for $1;
	p_object_type	alias for $2;
	p_biz_object_id	alias for $3;
	p_text		alias for $4;

	v_object_type_id	integer;
        ts2_result		varchar;
begin
	select	object_type_id
	into	v_object_type_id
	from	im_search_object_types
	where	object_type = p_object_type;

	update im_search_objects set
		object_type_id	= v_object_type_id,
		biz_object_id	= p_biz_object_id,
		fti		= to_tsvector(''default'', p_text)
	where
		object_id	= p_object_id;

	return 0;
end;' language 'plpgsql';



create or replace function im_projects_tsearch_insert () 
returns trigger as '
begin
	perform im_search_insert(new.project_id, ''im_project'', 0, new.project_name);
	return new;
end;' language 'plpgsql';

CREATE TRIGGER im_projects_tsearch_insert_tr 
BEFORE INSERT ON im_projects
FOR EACH ROW 
EXECUTE PROCEDURE im_projects_tsearch_insert();



create or replace function im_projects_tsearch_update () 
returns trigger as '
begin
	perform im_search_update(new.project_id, ''im_project'', 0, new.project_name);
	return new;
end;' language 'plpgsql';

CREATE TRIGGER im_projects_tsearch_update_tr 
BEFORE UPDATE ON im_projects
FOR EACH ROW 
EXECUTE PROCEDURE im_projects_tsearch_update();






-- select im_search_insert(9689, 'im_project', 0, 
-- 'Installation of Project/Open at Tigerpond');




CREATE TRIGGER im_search_objects_tr BEFORE UPDATE OR INSERT ON im_search_objects
FOR EACH ROW EXECUTE PROCEDURE tsearch2(fti, 'projec test');

create or replace function ts2_to_tsvector ( varchar, varchar ) 
returns varchar as '
declare
	ts2_cfg alias for $1;
	ts2_txt alias for $2;
	ts2_result varchar;
begin
	perform set_curcfg(ts2_cfg);
	select to_tsvector(ts2_cfg,ts2_txt) into ts2_result;
	return ts2_result;
end;' language 'plpgsql';



create or replace function ts2_to_tsquery ( varchar, varchar ) 
returns tsquery as '
declare
	ts2_cfg alias for $1;
	ts2_txt alias for $2;
	ts2_result tsquery;
begin
	perform set_curcfg(ts2_cfg);
	select 1 into ts2_result;
	select to_tsquery(ts2_cfg,ts2_txt) into ts2_result;
	return ts2_result;
end;' language 'plpgsql';



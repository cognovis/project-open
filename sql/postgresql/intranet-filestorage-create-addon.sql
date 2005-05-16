-- /packages/intranet-filestorage/sql/postgresql/intranet-filestorage-create-addon.sql
--
-- Copyright (c) 2003-2005 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es
--

-- Defines a new object type for files in the filesystem.
-- This code should eventually go into the filestorage
-- with P/O V3.1, but is located in this add-on package
-- in intranet-search-pg meanwhile.

-- Also, filestorage folders should be converted to
-- OpenACS objects then.




-----------------------------------------------------------
-- Filestorage Files
--

create table im_fs_files (
	fs_file_id		integer
				constraint im_fs_file_pk 
				primary key
				constraint im_fs_file_fk
				references acs_objects,
	fs_file_path		varchar(2000),
	fs_file_type_id		integer not null
				constraint im_fs_files_fs_file_type_fk
				references im_categories,
	fs_file_status_id	integer
				constraint im_fs_files_fs_file_status_fk
				references im_categories
);

---------------------------------------------------------
-- Filestorage File Object Type

select acs_object_type__create_type (
	'im_fs_file',		-- object_type
	'Filestorage File',	-- pretty_name
	'Filestorage Files',	-- pretty_plural
	'acs_object',		-- supertype
	'im_fs_files',		-- table_name
	'fs_file_id',		-- id_column
	'intranet-filestorage',	-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_fs_file.name'	-- name_method
);


create or replace function im_fs_file__new (
	integer,
	varchar,
	timestamptz,
	integer,
	varchar,
	integer,
	
	varchar,
	integer,
	integer
) returns integer as '
declare
	p_fs_file_id		alias for $1;		-- fs_file_id default null
	p_object_type		alias for $2;		-- object_type default ''im_fs_file''
	p_creation_date		alias for $3;		-- creation_date default now()
	p_creation_user		alias for $4;		-- creation_user
	p_creation_ip		alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	p_fs_file_path		alias for $7;	
	p_fs_file_type_id	alias for $8;
	p_fs_file_status_id	alias for $9;

	v_fs_file_id		integer;
    begin
 	v_fs_file_id := acs_object__new (
                p_fs_file_id,            -- object_id
                p_object_type,            -- object_type
                p_creation_date,          -- creation_date
                p_creation_user,          -- creation_user
                p_creation_ip,            -- creation_ip
                p_context_id,             -- context_id
                ''t''                     -- security_inherit_p
        );

	insert into im_fs_files (
		fs_file_id,
		fs_file_path,
		fs_file_type_id,
		fs_file_status_id
	) values (
		p_fs_file_id,
		p_fs_file_path,
		p_fs_file_type_id,
		p_fs_file_status_id
	);

	return v_fs_file_id;
end;' language 'plpgsql';



-- Delete a single fs_file (if we know its ID...)
create or replace function  im_fs_file__delete (integer)
returns integer as '
declare
	p_fs_file_id alias for $1;	-- fs_file_id
begin
	-- Erase the fs_file
	delete from 	im_fs_files
	where		fs_file_id = p_fs_file_id;

        -- Erase the object
        PERFORM acs_object__delete(p_fs_file_id);
        return 0;
end;' language 'plpgsql';


create or replace function im_fs_file__name (integer)
returns varchar as '
declare
	p_fs_file_id alias for $1;	-- fs_file_id
	v_name	varchar(40);
begin
	select	fs_file_path
	into	v_name
	from	im_fs_files
	where	fs_file_id = p_fs_file_id;
	return v_name;
end;' language 'plpgsql';



-- -------------------------------------------------------------
-- Helper function

create or replace function im_fs_file_path_from_id (integer)
returns varchar as '
DECLARE
        p_id    alias for $1;
        v_name  varchar(50);
BEGIN
        select m.fs_file_path
        into v_name
        from im_fs_files m
        where fs_file_id = p_id;

        return v_name;
end;' language 'plpgsql';


----------------------------------------------------------
-- Filestorage File Cateogries
--

-- Filestorage File Types
delete from im_categories where category_type = 'Intranet Filestorage File Type';

-- Intranet Filestorage File Status
delete from im_categories where category_type = 'Intranet Filestorage File Status';



create or replace view im_fs_file_status as 
select 	category_id as fs_file_type_id, 
	category as fs_file_type
from im_categories 
where category_type = 'Intranet Filestorage File Status';
	

create or replace view im_fs_file_status_active as 
select 	category_id as fs_file_type_id, 
	category as fs_file_type
from im_categories 
where	category_type = 'Intranet Filestorage File Status'
	and category_id not in (9102);


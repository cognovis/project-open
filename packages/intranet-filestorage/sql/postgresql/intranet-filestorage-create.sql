-- /packages/intranet-filestorage/sql/postgresql/intranet-filestorage-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es
--

-- Sets up the persisten memory about folders, their permissions
-- and the state (opened or closed) in which the user they have
-- left the last time he used the filestorage module.
--
-- Note: These tables are not yet used by the filestorage module,
-- but thought for the next version of the module.


---------------------------------------------------------
-- Folders
--
-- A table to keep the list of folers.  Folders are not OpenACS objects 
-- because applying OpenACS permission means a storage complexity of
-- order (users * folders). Here we are using "sparce" permission, only 
-- to store explicit user permission grants. The permission of subfolders 
-- (without explicit permission records) are inherited from the super 
-- folder while calculating the filestorage component (in TCL).
-- During indexing with a search engine, documents are given a pointer 
-- to the folder which carries the permissions.

\i ../common/intranet-filestorage-common.sql

create sequence im_fs_folder_seq start 1;
create table im_fs_folders (
	folder_id		integer 
				constraint im_fs_folders_pk
				primary key,
	object_id		integer
				constraint im_fs_folder_object_fk
				references acs_objects,
	path			text
				constraint im_fs_folder_status_path_nn 
				not null,
	folder_type_id		integer
				constraint im_fs_folder_type_fk
				references im_categories,
	description		text,
		constraint im_fs_folders_un
		unique (object_id, path)
);
-- We need to select frequently all folders for a given business object.
create index im_fs_folders_object_idx on im_fs_folders(object_id);


---------------------------------------------------------
-- Files
--
-- A table to keep the list of files. Files are not OpenACS objects 
-- because applying OpenACS permission means a storage complexity of
-- order (users * folders). 
-- Instead, we are using "sparce" permissions on the file's folders
-- to save storage complexity. 

create sequence im_fs_file_seq start 1;
create table im_fs_files (
	file_id		integer 
			constraint im_fs_files_pk
			primary key,
			-- Pointer to folder - this is where all 
			-- security is located
	folder_id	integer 
			constraint im_fs_files_folder_fk
			references im_fs_folders,
			-- Who is the owner? (Creator/Updator/...)
	owner_id	integer 
			constraint im_fs_files_owner_fk
			references persons,
			-- Filename, starting at folder. Should not
			-- contain any slash / characters.
	filename	text
			constraint im_fs_files_filename_nn 
			not null,
	language_id	integer
			constraint im_fs_file_lang_fk
			references im_categories,
			-- Full file hash to identify duplicate files
	binary_hash	character(40),
			-- Hash on file strings for similar files
	text_hash	character(40),
			-- How many times has the file been downloaded?
			-- Calculated from im_fs_actions
	downloads_cache	integer,
			-- Used to mark deleted files as non-existing
			-- before they are deleted from the list.
	exists_p	char(1) default '1'
			constraint im_fs_files_exists_ck
			check(exists_p in ('0','1')),
			-- Full-Text indexed? Used to indicate the
			-- necessity to FTindex a new file
	ft_indexed_p	char(1) default '0'
			constraint im_fs_files_ft_indexed_ck
			check(exists_p in ('0','1')),
			-- last changed date of file on the Hard Disk
	last_modified	varchar(30),
			-- last time of PO update
	last_updated	timestamptz,
			-- contents normalized for FTI
	fti_content	text,
		-- Only one file with the same name below a folder
		constraint im_fs_files_un
		unique (folder_id, filename)
);
-- We need to select frequently the files per folder:
create index im_fs_files_folder_idx on im_fs_files(folder_id);



---------------------------------------------------------
-- Folder Status
--
-- Basically, a folder can be opened ("+" - showing all files 
-- and subfolders) or closed ("-" - reduced to a single line).
-- This information depends on the users (this is why we
-- need to put it into a separate table).

create sequence im_fs_folder_status_seq start 1;
create table im_fs_folder_status (
	folder_id	integer
			constraint im_fs_folder_status_folder_fk
			references im_fs_folders,
	user_id		integer
			constraint im_fs_folder_status_user_fk 
			references users,
	open_p		char(1)
			constraint im_fs_folder_status_nn not null
			constraint im_fs_folder_status_state_ck
			check(open_p in ('o','c')),
	last_modified	date default now(),
	primary key (user_id, folder_id)
);
create index im_fs_folder_status_user_idx on im_fs_folder_status(user_id);


---------------------------------------------------------
-- Folder Permission Map and Cache
--
-- Maps folders to groups with read_p, write_p and view_p.
-- Perhaps we should change this to separate entries for
-- read, write and admin, to get closer to the HP data model.

create table im_fs_folder_perms (
	folder_id		integer
				constraint im_fs_folder_perm_folder_fk
				references im_fs_folders,
				-- profile doesn't reference im_profiles because
				-- we use it to store "roles" as well.
	profile_id		integer,
	view_p			char(1) default('0')
				constraint im_fs_folder_perms_status_view_ck
				check(view_p in ('0','1')),
	read_p			char(1) default('0')
				constraint im_fs_folder_perms_status_read_ck
				check(read_p in ('0','1')),
	write_p			char(1) default('0')
				constraint im_fs_folder_perms_status_write_ck
				check(write_p in ('0','1')),
	admin_p			char(1) default('0')
				constraint im_fs_folder_perms_status_admin_ck 
				check(admin_p in ('0','1')),
				-- Is this a genuine entry, or is this
				-- a precalculated (cached) entry?
	cached_p		char(1)
				constraint im_fs_folder_perms_cached_ck 
				check(admin_p in ('0','1')),
	constraint im_fs_folders_permd_pk
	primary key (folder_id, profile_id)
);


---------------------------------------------------------
-- File Actions
--
-- Protocol of .dDownload and upload actions of a file.
-- This is used to keep track for knowledge management
-- to see in which documents a user was interested.

create table im_fs_actions (
	action_type_id		integer references im_categories,
	user_id			integer not null references persons,
	action_date		timestamptz,
	file_name		text,
		primary key (user_id, action_date, file_name)
);


---------------------------------------------------------
-- Normalize Company Pathes
--


create or replace function im_company_normalize_path (varchar) 
returns varchar as '
DECLARE
	v_path		alias for $1;
	path		varchar;
	i		integer;
	pos		integer;
	char		varchar;
	latin_char	varchar;
	pathlen		integer;
	spacing		integer;
	asc		integer;
BEGIN
	path = '''';
	pathlen = char_length(v_path);
	spacing = 0;
	FOR i IN 1 .. pathlen LOOP
		char = substring(v_path, i, 1);
--		char = convert(char, ''UNICODE'', ''LATIN1'');
		asc = ascii(char);
		pos = position(char in ''abcdefghijklmnopqrstuvwxyz'' || 
			''ABCDEFGHIJKLMNOPQRSTUVWXYZ'' || 
			''0123456789_'');
--		IF char = ''ö'' THEN  pos=1; char = ''oe'' END IF;
		IF asc > 127 THEN
		RAISE NOTICE ''path=%, i=%, char=%, pos=%, asc=%'', 
			v_path, i, char, pos, asc;
		END IF;
		IF pos < 1 THEN
		-- Add new char only if it is not another underscore
		IF 0 = spacing THEN
			path = path || ''_'';
			spacing = 1;
		END IF;
		ELSE
		path = path || char;
		spacing = 0;
		END IF;
	END LOOP;
	path = lower(path);
	path = trim(both ''_'' from path);
	return path;
end;' language 'plpgsql';
select im_company_normalize_path ('Profilex +newtec GmbH/');


---------------------------------------------------------
-- Register the component in the core TCL pages
--
-- These DB-entries allow the pages of Core
-- to render the filestorage components in the Home, Users,
-- Projects and Company pages.


-- delete potentially existing menus and plugins if this 
-- file is sourced multiple times during development...

select	im_component_plugin__del_module('intranet-filestorage');
select	im_menu__del_module('intranet-filestorage');


-- create components

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Home Filestorage Component',   -- plugin_name
	'intranet-filestorage',		-- package_name
	'bottom',			-- location
	'/intranet/index',		-- page_url
	null,				-- view_name
	90,				-- sort_order
	'im_filestorage_home_component $user_id' -- component_tcl
);

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Users Filestorage Component',  -- plugin_name
	'intranet-filestorage',		-- package_name
	'right',			-- location
	'/intranet/users/view',		-- page_url
	null,				-- view_name
	90,				-- sort_order
	'im_filestorage_user_component $current_user_id $user_id $name $return_url' -- component_tcl
);

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Companies Filestorage Component',  -- plugin_name
	'intranet-filestorage',		-- package_name
	'right',			-- location
	'/intranet/companies/view',     -- page_url
	null,				-- view_name
	50,				-- sort_order
	'im_filestorage_company_component $user_id $company_id $company_name $return_url' -- component_tcl
);


--  Create a special privilege to control the "Sales" Filestorage 
--  which may actually be located on a different server for
--  security reasons

select acs_privilege__create_privilege('view_filestorage_sales','View Sales Filestorage','View Sales Filestorage');
select acs_privilege__add_child('admin', 'view_filestorage_sales');


SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Sales Filestorage Component',  -- plugin_name
	'intranet-filestorage',		-- package_name
	'files',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	89,				-- sort_order
	'im_filestorage_project_sales_component $user_id $project_id $project_name $return_url' -- component_tcl
);


SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Filestorage Component',  -- plugin_name
	'intranet-filestorage',		-- package_name
	'files',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	90,				-- sort_order
	'im_filestorage_project_component $user_id $project_id $project_name $return_url' -- component_tcl
);


SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Expense Bundle Filestorage',		-- plugin_name
	'intranet-filestorage',			-- package_name
	'bottom',				-- location
	'/intranet-expenses/bundle-new',	-- page_url
	null,					-- view_name
	30,					-- sort_order
	'im_filestorage_cost_component $user_id $bundle_id $bundle_name $return_url' -- component_tcl
);



-- -----------------------------------------------------
-- Add privileges to handle the default privileges on
-- empty filestorages

select acs_privilege__create_privilege('fs_root_view','Default view privilege for FS root?','');
select acs_privilege__add_child('admin', 'fs_root_view');

select acs_privilege__create_privilege('fs_root_read','Default read privilege for FS root?','');
select acs_privilege__add_child('admin', 'fs_root_read');

select acs_privilege__create_privilege('fs_root_write','Default write privilege for FS root?','');
select acs_privilege__add_child('admin', 'fs_root_write');

select acs_privilege__create_privilege('fs_root_admin','Default admin privilege for FS root?','');
select acs_privilege__add_child('admin', 'fs_root_admin');


-- View Privileges
--
select im_priv_create('fs_root_view',	'Employees');
select im_priv_create('fs_root_view',	'Accounting');
select im_priv_create('fs_root_view',	'P/O Admins');
select im_priv_create('fs_root_view',	'Project Managers');
select im_priv_create('fs_root_view',	'Senior Managers');


-- Read Privileges
--
select im_priv_create('fs_root_read',	'Employees');
select im_priv_create('fs_root_read',	'Accounting');
select im_priv_create('fs_root_read',	'P/O Admins');
select im_priv_create('fs_root_read',	'Project Managers');
select im_priv_create('fs_root_read',	'Senior Managers');


-- Write Privileges
--
select im_priv_create('fs_root_write',	'Employees');
select im_priv_create('fs_root_write',	'Accounting');
select im_priv_create('fs_root_write',	'P/O Admins');
select im_priv_create('fs_root_write',	'Project Managers');
select im_priv_create('fs_root_write',	'Senior Managers');


-- Admin Privileges
--
select im_priv_create('fs_root_admin',	'Employees');
select im_priv_create('fs_root_admin',	'Accounting');
select im_priv_create('fs_root_admin',	'P/O Admins');
select im_priv_create('fs_root_admin',	'Project Managers');
select im_priv_create('fs_root_admin',	'Senior Managers');


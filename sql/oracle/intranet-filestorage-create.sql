-- /packages/intranet-filestorage/sql/oracle/intranet-filestorage-create.sql
--
-- Sets up the persisten memory about folders, their permissions
-- and the state (opened or closed) in which the user they have
-- left the last time he used the filestorage module.
--
-- @author Frank Bergmann (fraber@fraber.de)
--
-- Note: These tables are not yet used by the filestorage module,
-- but thought for the next version of the module.


---------------------------------------------------------
-- Register the component in the core TCL pages
--
-- These DB-entries allow the pages of Project/Open Core
-- to render the filestorage components in the Home, Users,
-- Projects and Customer pages.


-- delete potentially existing menus and plugins if this 
-- file is sourced multiple times during development...

BEGIN
	im_component_plugin.del_module(module_name => 'intranet-filestorage');
	im_menu.del_module(module_name => 'intranet-filestorage');
END;
/
show errors
commit;


declare
	v_plugin		integer;
begin
	-- Home Page
	-- Set the filestorage to the very end.
	--
	v_plugin := im_component_plugin.new (
	plugin_name =>	'Home Filestorage Component',
	package_name =>	'intranet-filestorage',
	page_url =>	 '/intranet/index',
	location =>	 'bottom',
	sort_order =>   90,
	component_tcl => 
	'im_filestorage_home_component \
		$user_id \
		$return_url'
	);

	v_plugin := im_component_plugin.new (
	plugin_name =>	'Users Filestorage Component',
	package_name =>	'intranet-filestorage',
	page_url =>	 '/intranet/users/view',
	location =>	 'bottom',
	sort_order =>   90,
	component_tcl => 
	'im_filestorage_user_component \
		$current_user_id \
		$user_id \
		$name \
		$return_url'
	);

	v_plugin := im_component_plugin.new (
	plugin_name =>	'Customers Filestorage Component',
	package_name =>	'intranet-filestorage',
	page_url =>	 '/intranet/customers/view',
	location =>	 'right',
	sort_order =>   50,
	component_tcl => 
	'im_filestorage_customer_component \
		$user_id \
		$customer_id \
		$customer_name \
		$return_url'
	);

end;
/
show errors
commit;

declare
	v_plugin		integer;
begin
	v_plugin := im_component_plugin.new (
	plugin_name =>	'Project Filestorage Component',
	package_name =>	'intranet-filestorage',
	page_url =>	 '/intranet/projects/view',
	location =>	 'files',
	sort_order =>   90,
	component_tcl => 
	'im_filestorage_project_component \
		$user_id \
		$project_id \
		$project_name \
		$return_url'
	);
end;
/


---------------------------------------------------------
-- Folders
--
-- A table to keep the list of folers.
-- Should folders become OpenACS objects so that we are 
-- able to use permissions on them?

create sequence im_fs_folder_seq start with 1;
create table im_fs_folders (
	folder_id		integer primary key,
	project_id		references im_projects,
	folder_name		varchar(400),
	folder_type_id		references im_categories
);

---------------------------------------------------------
-- Folder Status
--
-- Basicly, a folder can be opened ("+" - showing all files 
-- and subfolders) or closed ("-" - reduced to a single line).
-- This information depends on the users (this is why we
-- need to put it into a separate table from im_fs_folders).

create sequence im_fs_folder_status_seq start with 1;
create table im_fs_folder_status (
	folder_id	integer
			constraint im_fs_folder_status_pk
			primary key,
	object_id	integer
			constraint im_fs_folder_status_object_fk
			references acs_objects,
	user_id		integer
			constraint im_fs_folder_status_user_fk 
			references users,
	path		varchar(500)
			constraint im_fs_folder_status_path_nn 
			not null,
	open_p		char(1)
			constraint im_fs_folder_status_nn not null
			constraint im_fs_folder_status_state_ck
			check(open_p in ('o','c')),
	last_modified	date default sysdate,
	description	varchar(255)
);
create index im_fs_folder_status_user_idx on im_fs_folder_status(user_id);
create index im_fs_folder_status_object_idx on im_fs_folder_status(object_id);

---------------------------------------------------------
-- Folder Permission Map
--
-- Maps folders to groups with read_p, write_p and view_p.
-- Perhaps we should change this to separate entries for
-- read, write and view, to get closer to the HP data model.

create table im_fs_folder_permission_map (
	folder_id		 references im_fs_folders,
	group_id		references groups,
	read_p		  char(1) default('t')
	constraint im_fs_folder_status_read_p check(read_p in ('t','f')),
	write_p		 char(1) default('t')
	constraint im_fs_folder_status_write_p check(write_p in ('t','f')),
	view_p		  char(1) default('t')
	constraint im_fs_folder_status_view_p check(view_p in ('t','f'))
);


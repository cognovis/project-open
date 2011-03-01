-- upgrade-3.2.1.0.0-3.2.2.0.0.sql

SELECT acs_log__debug('/packages/intranet-filestorage/sql/postgresql/upgrade/upgrade-3.2.1.0.0-3.2.2.0.0.sql','');



-- -----------------------------------------------------
-- Update to allow for file-name search

create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select  count(*) into v_count from user_tab_columns
	where   lower(table_name) = ''im_fs_files'';
	if v_count > 0 then return 0; end if;

	create sequence im_fs_file_seq start 1;
	create table im_fs_files (
		file_id	 integer
				constraint im_fs_files_pk
				primary key,
		folder_id       integer
				constraint im_fs_files_folder_fk
				references im_fs_folders,
		owner_id	integer
				constraint im_fs_files_owner_fk
				references users,
		filename	varchar(500)
				constraint im_fs_files_filename_nn
				not null,
		language_id     integer
				constraint im_fs_file_lang_fk
				references im_categories,
		binary_hash     character(40),
		text_hash       character(40),
		downloads_cache integer,
		exists_p	char(1) default ''1''
				constraint im_fs_files_exists_ck
				check(exists_p in (''0'',''1'')),
		ft_indexed_p    char(1) default ''0''
				constraint im_fs_files_ftindexed_ck
				check(exists_p in (''0'',''1'')),
		last_updated	timestamptz,
		last_modified   varchar(30),
			constraint im_fs_files_un
			unique (folder_id, filename)
	);

	create index im_fs_files_folder_idx on im_fs_files(folder_id);

	alter table im_fs_folder_perms add
		cached_p		char(1)
					constraint im_fs_folder_perms_cached_ck
					check(admin_p in (''0'',''1''))
	;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


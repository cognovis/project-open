-- -----------------------------------------------------
-- Update to allow for file-name search


create sequence im_fs_file_seq start 1;
create table im_fs_files (
        file_id         integer
                        constraint im_fs_files_pk
                        primary key,
                        -- Pointer to folder - this is where all
                        -- security is located
        folder_id       integer
                        constraint im_fs_files_folder_fk
                        references im_fs_foldters,
                        -- Who is the owner? (Creator/Updator/...)
        owner_id        integer
                        constraint im_fs_files_folder_fk
                        references im_fs_foldters,
                        -- Filename, starting at folder. Should not
                        -- contain any slash / characters.
        filename        varchar(100)
                        constraint im_fs_files_filename_nn
                        not null,
        language_id     integer
                        constraint im_fs_file_lang_fk
                        references im_categories,
                        -- Full file hash to identify duplicate files
        binary_hash     character(40),
                        -- Hash on file strings for similar files
        text_hash       character(40),
                        -- How many times has the file been downloaded?
                        -- Calculated from im_fs_actions
        downloads_cache integer,
                        -- Used to mark deleted files as non-existing
                        -- before they are deleted from the list.
        exists_p        char(1) default '1'
                        constraint im_fs_files_exists_ck
                        check(exists_p in ('0','1')),
			-- last time of update
	last_updated	timestamptz,
                -- Only one file with the same name below a folder
                constraint im_fs_files_un
                unique (folder_id, filename)
);
-- We need to select frequently the files per folder:
create index im_fs_files_folder_idx on im_fs_files(folder_id);



alter table im_fs_folder_perms add
        cached_p                char(1)
                                constraint im_fs_folder_perms_cached_ck
                                check(admin_p in ('0','1'))
;


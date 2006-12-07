
alter table im_fs_files
add last_modified varchar(30);

alter table im_fs_files
add last_updated timestamptz;


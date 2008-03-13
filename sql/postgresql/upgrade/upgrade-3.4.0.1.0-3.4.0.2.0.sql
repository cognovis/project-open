-- upgrade-3.4.0.1.0-3.4.0.2.0.sql

alter table im_fs_files drop constraint im_fs_files_owner_fk;

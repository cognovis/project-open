-- /packages/intranet-filestorage/sql/oracle/intranet-filestorage-drop.sql
--

drop table im_fs_folder_permission_map;

drop sequence im_fs_folder_status_seq;
drop table im_fs_folder_status;

drop sequence im_fs_folder_seq;
drop table im_fs_folders;

delete from im_component_plugins where component_tcl like 'im_filestorage_%';

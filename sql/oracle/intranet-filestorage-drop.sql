-- /packages/intranet-filestorage/sql/oracle/intranet-filestorage-drop.sql
--

drop table im_fs_folder_permission_map;

drop sequence im_fs_folder_status_seq;
drop table im_fs_folder_status;

drop sequence im_fs_folder_seq;
drop table im_fs_folders;



begin
    im_component_plugin.del_module('intranet-filestorage');
end;
/


-- /packages/intranet-filestorage/sql/oracle/intranet-filestorage-drop.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

drop table im_fs_actions;
drop table im_fs_folder_perms;

drop sequence im_fs_folder_status_seq;
drop table im_fs_folder_status;

drop sequence im_fs_folder_seq;
drop table im_fs_folders;



begin
    im_component_plugin.del_module('intranet-filestorage');
end;
/


-- /packages/intranet-filestorage/sql/oracle/intranet-filestorage-drop.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruiz@yahoo.es

drop table im_fs_folder_perms;

drop sequence im_fs_folder_status_seq;
drop table im_fs_folder_status;

drop sequence im_fs_folder_seq;
drop table im_fs_folders;

select acs_privilege__drop_privilege('view_filestorage_sales');

select im_component_plugin__del_module('intranet-filestorage');



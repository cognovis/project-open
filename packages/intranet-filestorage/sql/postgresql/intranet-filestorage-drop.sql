-- /packages/intranet-filestorage/sql/oracle/intranet-filestorage-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruiz@yahoo.es
create or replace function inline_revoke_permission (varchar)
returns integer as '
DECLARE
        p_priv_name     alias for $1;
BEGIN
     lock table acs_permissions_lock;

     delete from acs_permissions
     where privilege = p_priv_name;
     delete from acs_privilege_hierarchy
     where child_privilege = p_priv_name;
     return 0;

end;' language 'plpgsql';

drop table im_fs_actions;
drop table im_fs_folder_perms;

drop sequence im_fs_folder_status_seq;
drop table im_fs_folder_status;

drop sequence im_fs_folder_seq;
drop table im_fs_folders;

select inline_revoke_permission ('view_filestorage_sales');
select acs_privilege__drop_privilege('view_filestorage_sales');

select im_component_plugin__del_module('intranet-filestorage');



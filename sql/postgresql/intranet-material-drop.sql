-- /package/intranet-material/sql/intranet-material-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-----------------------------------------------------
-- Drop menus and components defined by the module

select im_menu__del_module('intranet-material');
select im_component_plugin__del_module('intranet-material');


delete from im_view_columns where column_id >= 90000 and column_id < 90999;
delete from im_views where view_id >= 900 and view_id <= 909;


-- before remove priviliges remove granted permissions
create or replace function inline_revoke_permission (varchar)
returns integer as '
DECLARE
        p_priv_name     alias for $1;
BEGIN
--     lock table acs_permissions_lock;

     delete from acs_privilege_hierarchy
     where child_privilege = p_priv_name;

     delete from acs_permissions
     where privilege = p_priv_name;

     delete from acs_privileges
     where privilege = p_priv_name;

     return 0;

end;' language 'plpgsql';

select inline_revoke_permission ('add_material');
select inline_revoke_permission ('view_material');


-- no objects yet...
-- delete from acs_objects where object_type='im_menu';


-- delete all objects
create or replace function inline_0 ()
returns integer as '
DECLARE
        row RECORD;
BEGIN
    for row in
        select material_id
        from im_materials;
    loop
        im_material__delete(row.material_id);
    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



delete from im_component_plugins where package_name = 'intranet-material';

drop table im_materials;

-- /packages/intranet-hr/sql/oracle/intranet-hr-drop.sql
--
-- ]project-open[ HR Module
--
-- frank.bergmann@project-open.com, 030828
-- A complete revision of June 1999 by dvr@arsdigita.com
--
-- Copyright (C) 1999-2004 ArsDigita, Frank Bergmann and others
--
-- This program is free software. You can redistribute it 
-- and/or modify it under the terms of the GNU General 
-- Public License as published by the Free Software Foundation; 
-- either version 2 of the License, or (at your option) 
-- any later version. This program is distributed in the 
-- hope that it will be useful, but WITHOUT ANY WARRANTY; 
-- without even the implied warranty of MERCHANTABILITY or 
-- FITNESS FOR A PARTICULAR PURPOSE. 
-- See the GNU General Public License for more details.


-----------------------------------------------------
-- Drop menus and components defined by the module

-- BEGIN
    select im_menu__del_module('intranet-hr');
    select im_component_plugin__del_module('intranet-hr');
-- END;

-- show errors;


-- Delete the employees_list view so that /intranet/users/ is going
-- to show the regular users_list view again.
delete from im_view_columns where view_id >= 55 and view_id <= 59;
delete from im_views where view_id >= 55 and view_id <= 59;



drop table im_emp_checkpoint_checkoffs;
drop table im_employee_checkpoints;
drop sequence im_employee_checkpoint_id_seq;
drop view im_employees_active;
drop table im_employees;
drop function im_supervises_p(integer, integer);

-- before remove priviliges remove granted permissions
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


-- begin
   select inline_revoke_permission ('view_hr');
   select acs_privilege__drop_privilege ('view_hr');

-- commit;
-- delete categories from 450 to 455
delete from im_category_hierarchy where (parent_id >= 3700 and parent_id < 3799) or (child_id >= 3700 and child_id < 3799);
delete from im_categories where category_id >= 3700 and category_id < 3799;
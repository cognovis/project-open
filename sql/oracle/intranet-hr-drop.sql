-- /packages/intranet-hr/sql/oracle/intranet-hr-drop.sql
--
-- Project/Open HR Module, frank.bergmann@project-open.com, 030828
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

BEGIN
    im_menu.del_module(module_name => 'intranet-hr');
    im_component_plugin.del_module(module_name => 'intranet-hr');
END;
/
show errors;


-- Delete the employees_list view so that /intranet/users/ is going
-- to show the regular users_list view again.
delete from im_view_columns where view_id >= 55 and view_id <= 59;
delete from im_views where view_id >= 55 and view_id <= 59;



drop table im_emp_checkpoint_checkoffs;
drop table im_employee_checkpoints;
drop sequence im_employee_checkpoint_id_seq;
drop table im_employees;
drop function im_supervises_p;

commit;

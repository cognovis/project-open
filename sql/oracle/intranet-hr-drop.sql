-- /packages/intranet-hr/sql/oracle/intranet-hr-drop.sql
--
-- Project/Open HR Module, fraber@fraber.de, 030828
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


drop table im_emp_checkpoint_checkoffs;
drop table im_employee_checkpoints;
drop sequence im_employee_checkpoint_id_seq;
drop im_supervises_p;
drop table im_employees;

commit;

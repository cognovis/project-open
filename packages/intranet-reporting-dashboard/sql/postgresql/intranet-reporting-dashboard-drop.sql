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

select im_menu__del_module('intranet-reporting-dashboard');
select im_component_plugin__del_module('intranet-reporting-dashboard');


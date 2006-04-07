-- /packages/intranet-timesheet/sql/oracle/intranet-timesheet-create.sql
--
-- Copyright (C) 1999-2004 various parties
-- The code is based on ArsDigita ACS 3.4
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
--
-- @author      unknown@arsdigita.com
-- @author      frank.bergmann@project-open.com
-- @author	mai-bee@gmx.net

------------------------------------------------------------
-- Riskmanagement
--
-- We record project risks and represent them graphically.
--

drop table im_risks;

--------------
-- View in Project
--------------

drop view im_risk_types;

-- 5100 - 5199 Absence types
delete from im_categories where category_id >= 5100 and category_id <= 5199;

-- views to "risk" items: 210-219
delete from im_view_columns where column_id >= 20100 and column_id < 20200;
delete from im_views where view_id >= 210 and view_id < 220;

---------------------------------------------------------
-- Register the component in the core TCL pages
--

BEGIN
    im_component_plugin.del_module(module_name => 'intranet-riskmanagement');
END;
/
show errors

commit;

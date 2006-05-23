-- /packages/intranet-cost/sql/postgres/upgrade/upgrade-3.1.4.0.0-3.2.0.0.0.sql
--
-- Project/Open Cost Core
-- 040207 frank.bergmann@project-open.com
--
-- Copyright (C) 2004 Project/Open
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

-------------------------------------------------------------
-- 
---------------------------------------------------------

-- Add cache fields for expenses

alter table im_projects add     cost_expense_planned_cache	numeric(12,2);
alter table im_projects alter	cost_expense_planned_cache	set default 0;

alter table im_projects add     cost_expense_logged_cache	numeric(12,2);
alter table im_projects alter	cost_expense_logged_cache	set default 0;



-- /packages/intranet-cost/sql/postgres/upgrade/upgrade-3.2.0.0.0-3.2.2.0.0.sql
--
-- Project/Open Cost Core
-- 040207 frank.bergmann@project-open.com
--
-- Copyright (C) 2006 Project/Open
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

-------------------------------------------------------------
-- 
---------------------------------------------------------

-- Add cache fields for Delivery Notes

alter table im_projects add     cost_delivery_notes_cache       numeric(12,2);
alter table im_projects alter   cost_delivery_notes_cache       set default 0;



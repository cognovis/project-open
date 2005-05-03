-- /packages/intranet-hr/sql/xxx/upgrade-3.0.alpha3-3.0.0.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

alter table im_employees add
hourly_cost	numeric(12,3)
;

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5607,56,'Hourly Cost','$hourly_cost',07);

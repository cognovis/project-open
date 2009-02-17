-- /packages/intranet-trans-quality/sql/postgresql/intranet-trans-quality-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author guillermo.belcic@project-open.com

-----------------------------------------------------------
-- Drop Tables

drop sequence quality_report_id;
drop table im_trans_quality_entries;
drop table im_trans_quality_reports;

-----------------------------------------------------------
-- Remove menus and plugin components

select im_menu__del_module('intranet-trans-quality');
select im_component_plugin__del_module('intranet-trans-quality');




-- /packages/intranet-invoices/sql/postgresql/intranet-reporting-finance-drop.sql
--
-- Copyright (C) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


select im_menu__del_module('intranet-reporting-finance');
select im_component_plugin__del_module('intranet-reporting-finance');


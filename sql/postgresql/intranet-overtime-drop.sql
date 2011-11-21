-- /packages/intranet-overtime/sql/postgresql/intranet-overtime-drop.sql
--
-- Copyright (c) 2011 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author klaus.hofeditz@project-open.com

select im_component_plugin__del_module('im_overtime_balance_component');
select im_component_plugin__del_module('im_rwh_balance_component');


-- /packages/intranet--trans-project-wizard/sql/oracle/-trans-project-wizard-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

---------------------------------------------------------
-- delete potentially existing menus and plugins

select im_component_plugin__del_module('intranet-trans-project-wizard');
select im_menu__del_module('intranet-trans-project-wizard');

-- Fix for wrong metainformation of previous version
select im_component_plugin__del_module('intranet-intranet-trans-project-wizard');
select im_menu__del_module('intranet-intranet-trans-project-wizard');


-- /packages/intranet-big-brother/sql/oracle/intranet-big-brother-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- avila@digiteix.com

-- Sets up an interface to the Big Brother System Monitoring system


---------------------------------------------------------
-- delete potentially existing menus and plugins

select im_component_plugin__del_module('intranet-big-brother');
select im_menu__del_module('intranet-big-brother');


-- /packages/intranet-invoices/sql/postgresql/intranet-reporting-cubes-drop.sql
--
-- Copyright (C) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


select im_menu__del_module('intranet-reporting-cubes');
select im_component_plugin__del_module('intranet-reporting-cubes');

drop function im_reporting_cube_tree_ancestor_key(varbit, integer);

drop table im_reporting_cube_values;
drop sequence im_reporting_cube_values_seq;
drop table im_reporting_cubes;
drop sequence im_reporting_cubes_seq;

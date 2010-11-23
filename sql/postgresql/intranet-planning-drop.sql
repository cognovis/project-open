-- /package/intranet-planning/sql/intranet-plannging-drop.sql
--
-- Copyright (c) 2003-2010 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Drop plugins and menus for the module
--
select  im_component_plugin__del_module('intranet-planning');
select  im_menu__del_module('intranet-planning');


-----------------------------------------------------------
-- Drop main structures info

-- Drop functions
drop function im_planning_item__name(integer);
drop function im_planning_item__new (
        integer, varchar, timestamptz,
        integer, varchar, integer,
        integer, integer, integer, integer, date
);
drop function im_planning_item__delete(integer);


-- Drop the main table
drop table im_planning_items;

-- Delete entries from acs_objects
delete from acs_objects where object_type = 'im_planning_item';
delete from acs_object_type_tables where object_type = 'im_planning_item';
delete from im_biz_object_urls where object_type = 'im_planning_item';

-- Completely delete the object type from the
-- object system
SELECT acs_object_type__drop_type ('im_planning_item', 't');


-- Drop permissions
delete from acs_permissions where privilege = 'view_planning_all';
select acs_privilege__remove_child('admin', 'view_planning_all');
select acs_privilege__drop_privilege('view_planning_all');



-----------------------------------------------------------
-- Drop Categories
--

drop view im_planning_item_status;
drop view im_planning_item_types;

delete from im_categories where category_type = 'Intranet Planning Status';
delete from im_categories where category_type = 'Intranet Planning Type';


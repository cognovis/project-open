-- /package/intranet-forum/sql/intranet-sla-management-drop.sql
--
-- Copyright (c) 2003-2006 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Drop plugins and menus for the module
--
select  im_component_plugin__del_module('intranet-sla-management');
select  im_menu__del_module('intranet-sla-management');


-----------------------------------------------------------
-- Drop main structures info

-- Drop functions
drop function im_note__name(integer);
drop function im_note__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	varchar, integer, integer, integer
);
drop function im_note__delete(integer);


-- Drop the main table
drop table im_sla-management;

-- Delete entries from acs_objects
delete from acs_objects where object_type = 'im_note';


-- Completely delete the object type from the
-- object system
SELECT acs_object_type__drop_type ('im_note', 't');



-----------------------------------------------------------
-- Drop Categories
--

drop view im_note_status;
drop view im_note_type;

delete from im_categories where category_type = 'Intranet Sla-Management Status';
delete from im_categories where category_type = 'Intranet Sla-Management Type';



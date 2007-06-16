-- /package/intranet-forum/sql/intranet-notes-drop.sql
--
-- Copyright (c) 2003-2006 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Drop plugins and menus for the module
--
select  im_component_plugin__del_module('intranet-notes');
select  im_menu__del_module('intranet-notes');


-- Drop functions
drop function im_note__name(integer);
drop function im_note__new (
	integer, varchar, timestamptz,
	integer, varchar, integer,
	varchar, integer, integer, integer
);
drop function im_note__delete(integer);


-- Drop the main table
drop table im_notes;

-- Delete entries from acs_objects
delete from acs_objects where object_type = 'im_note';


-- Completely delete the object type from the
-- object system
SELECT acs_object_type__drop_type ('im_note', 't');

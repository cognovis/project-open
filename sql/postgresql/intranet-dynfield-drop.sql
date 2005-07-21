--
-- packages/intranet-dynfield/sql/postgresql/intranet-dynfield-drop.sql
--
-- @author Frank Bergmann frank.bergmann@project-open.com
-- @creation-date 2005-01-06
--
--

drop table im_dynfield_layout;
drop table im_dynfield_layout_pages;
drop table im_dynfield_attr_multi_value;
drop table im_dynfield_attributes;
drop table im_dynfield_widgets;
-- drop table im_dynfield_storage_types;


delete from acs_objects where object_type = 'im_dynfield_widget';
delete from acs_objects where object_type = 'im_dynfield_attribute';


-- begin
        select acs_object_type__drop_type('im_dynfield_widget', 'f');
        select acs_object_type__drop_type('im_dynfield_attribute', 'f');
-- end;

delete from im_categories where category_type = 'Intranet DynField Storage Type';

-- show errors

-- \i upgrade-20050414-drop.sql


-- \i upgrade-20050419-drop.sql
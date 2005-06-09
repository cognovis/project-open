--
-- packages/flexbase/sql/postgresql/flexbase-drop.sql
--
-- @author Frank Bergmann frank.bergmann@project-open.com
-- @creation-date 2005-01-06
--
--

drop table flexbase_layout;
drop table flexbase_layout_pages;
drop table flexbase_attributes;
drop table flexbase_widgets;
drop table flexbase_storage_types;


delete from acs_objects where object_type = 'flexbase_widget';
delete from acs_objects where object_type = 'flexbase_attribute';


begin
        acs_object_type.drop_type('flexbase_widget', 'f');
        acs_object_type.drop_type('flexbase_attribute', 'f');
end;
/
show errors

@upgrade-20050414-drop.sql


@upgrade-20050419-drop.sql
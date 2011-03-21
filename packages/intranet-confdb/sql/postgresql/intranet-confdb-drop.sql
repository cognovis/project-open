-- /packages/intranet-confdb/sql/postgres/intranet-confdb-drop.sql
--
-- Copyright (c) 2007 ]project-open[
-- All rights reserved.
--
-- @author	frank.bergmann@project-open.com

-- Drop plugins and menus for the module
--

select  im_component_plugin__del_module('intranet-confdb');
select  im_menu__del_module('intranet-confdb');


drop view im_conf_item_status;
drop view im_conf_item_type;

delete from im_conf_items;

delete from im_categories where category_type = 'Intranet Conf Item Status';
delete from im_categories where category_type = 'Intranet Conf Item Type';

drop function im_conf_item_insert_tr() CASCADE;
drop function im_conf_items_update_tr () CASCADE;
drop function im_conf_item__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, integer, integer
);
drop function im_conf_item__delete (integer);
drop function im_conf_item__name (integer);
drop function im_conf_item_name_from_id (integer);
drop function im_conf_item_nr_from_id (integer);

drop table im_conf_items CASCADE;



select acs_rel_type__drop_role ('im_conf_item_project_rel');
delete from acs_rel_types where rel_type = 'im_conf_item_project_rel';


# delete from acs_object_types where object_type = 'im_conf_item';
select acs_object_type__drop_type ('im_conf_item', 'f');

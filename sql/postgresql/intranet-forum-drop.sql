-- /package/intranet-forum/sql/intranet-forum-drop.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-----------------------------------------------------
-- Drop menus and components defined by the module

select im_menu__del_module('intranet-forum');
select im_component_plugin__del_module('intranet-forum');


delete from im_view_columns where column_id >= 4000 and column_id < 4099;
delete from im_view_columns where column_id >= 4100 and column_id < 4199;
delete from im_view_columns where column_id >= 4200 and column_id < 4299;
delete from im_views where view_id >= 40 and view_id < 50;

-- no objects yet...
-- delete from acs_objects where object_type='im_menu';

delete from im_component_plugins where package_name = 'intranet-forum';

drop sequence im_forum_topics_seq;
drop sequence im_forum_files_seq;

drop table im_forum_files;
drop table im_forum_topic_user_map;
drop table im_forum_folders;
drop table im_forum_topics;


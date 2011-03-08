-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2005-01-29
-- @arch-tag: 938abc15-f59c-4397-b882-f5a89884be62
-- @cvs-id $Id: upgrade-1.0b3-1.0b4.sql,v 1.2 2006/08/08 21:27:07 donb Exp $
--

alter table dav_site_node_folder_map drop constraint dav_side_node_folder_map_node_id_fk;
alter table dav_site_node_folder_map add constraint dav_side_node_folder_map_node_id_fk foreign key (node_id) references site_nodes (node_id) on delete cascade;

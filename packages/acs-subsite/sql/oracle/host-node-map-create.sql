-- @author Mark Dettinger (mdettinger@arsdigita.com)
-- $Id: host-node-map-create.sql,v 1.2 2010/10/19 20:12:14 po34demo Exp $

-- This has not been tested against Oracle.
create table host_node_map (
   host                 varchar(200) 
	constraint host_node_map_host_pk primary key 
	constraint host_node_map_host_nn not null,
   node_id              integer 
	constraint host_node_map_node_id_fk references site_nodes
);

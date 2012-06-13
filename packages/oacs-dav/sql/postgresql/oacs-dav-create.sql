-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2003-09-14
-- @cvs-id $Id$
--

-- create a table to map site node_ids to cr_folders

create table dav_site_node_folder_map (
        node_id      integer
		        constraint dav_site_node_folder_map_node_id_un
			unique
                        constraint dav_side_node_folder_map_node_id_fk
                        references site_nodes on delete cascade,
        folder_id       integer
                        constraint dav_impls_folder_id_fk
                        references cr_folders on delete cascade,
	enabled_p 	boolean
);


        
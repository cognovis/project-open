-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2003-10-18
-- @cvs-id $Id: oacs-dav-create.sql,v 1.4 2009/10/12 22:52:22 daveb Exp $
--

-- create a table to map site node_ids to cr_folders

create table dav_site_node_folder_map (
        node_id      integer
		        constraint dav_sn_folder_map_node_id_un
			unique
                        constraint dav_sn_folder_map_node_id_fk
                        references site_nodes on delete cascade,
        folder_id       integer
                        constraint dav_impls_folder_id_fk
                        references cr_folders on delete cascade,
	enabled_p	char(1)
			constraint dav_sn_folder_map_enbld_p_bl
			check (enabled_p in ('t','f'))
);

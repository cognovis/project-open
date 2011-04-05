ad_library {

    Intranet-FS Install Library
    
    Porcedures to deal with installing, mounting intranet-fs 

    @creation_date 2010-07-09
    @author Iuri Sampaio <iuri.sampaio@gmail.com>
}

namespace eval intranet_fs::install {}

ad_proc -private intranet_fs::install::after_install {} {

    Setup intranet-fs to be used together with intranet-core and file-storage

} {

    # Get Main Site's node_id 
    set parent_node_id [db_string qry "
	select node_id 
	from site_nodes s, apm_packages p, acs_objects o 
	where p.package_key = 'acs-subsite' 
	and p.instance_name = 'Main Site' 
	and p.package_id = o.package_id
	and s.object_id = o.object_id
    "]
    
    # Get File Storage's package_id mounted under Main Site
    set file_storage_package_id [db_list qry "
	    select package_id 
    	       from acs_objects o, site_nodes s 
               	where o.object_id = s.object_id 
                and parent_id = :parent_node_id 
                and name = 'file-storage'
    "]

    if {![exists_and_not_null file_storage_package_id]} {
	# Mount file-storage application under Main Site
	set file_storage_package_id [site_node::instantiate_and_mount \
					 -parent_node_id $parent_node_id \
					 -node_name "file-storage" \
					 -package_name "File Storage" \
					 -package_key "file-storage"]
    }

    # Get File-Storage's Root Folder 
    set root_folder_id [fs::get_root_folder -package_id $file_storage_package_id]

    # Create Intranet Project's Root Folder
    set folder_id [fs::new_folder -name "projects" -pretty_name "Projects" -parent_id $root_folder_id -creation_user [ad_conn user_id] -creation_ip [ad_conn peeraddr] -description "PO Projects Root Folder"]
    
    set intranet_core_object_id [db_list get_intranet_core_obj_id "
	select object_id 
	from site_nodes 
	where parent_id = :parent_node_id 
	and name = 'intranet'
    "]

    # Create new relation types on table acs_rel_types
    rel_types::new "project_folder" "Project Folder" "Project Folder" "im_project" 0 1 "content_folder" 0 1
    rel_types::new "package_folder" "Package Folder" "Package Folder" "apm_package" 0 1 "content_folder" 0 1

    relation_add "package_folder" $intranet_core_object_id $folder_id 



}
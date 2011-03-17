#
#  Copyright (C) 2001, 2002 MIT
#
#  This file is part of dotLRN.
#
#  dotLRN is free software; you can redistribute it and/or modify it under the
#  terms of the GNU General Public License as published by the Free Software
#  Foundation; either version 2 of the License, or (at your option) any later
#  version.
#
#  dotLRN is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
#  details.
#

ad_library {

    Procedures to support the file-storage portlet

    @creation-date July 08 2010
    @author iuri sampaio (iuri.sampaio@gmail.com)

}

namespace eval intranet_fs {}

ad_proc -private intranet_fs::my_package_key {
} {
    return "intranet-fs"
}

ad_proc -private intranet_fs::get_my_name {
} {
    return intranet_fs
}

ad_proc -public intranet_fs::get_pretty_name {
} {
    return [parameter::get_from_package_key -package_key [my_package_key] -parameter pretty_name]
}

ad_proc -public intranet_fs::link {
} {
    return ""
}


ad_proc -public intranet_fs::get_projects_root_folder_id {
    {-package_id ""}
} {
    Returns projects root folder id
} {
    
    if {![exists_and_not_null package_id]} {
	set package_id [im_package_core_id]
    }
    
    return [util_memoize [list intranet_fs::get_projects_root_folder_id_not_cached -package_id $package_id]]
}


ad_proc -public intranet_fs::get_projects_root_folder_id_not_cached {
    {-package_id ""}
} {
    
    Returns projects root folder id
    
} {
    
    return [db_list select_folder_id "
	    select object_id_two 
	    from acs_rels 
	    where object_id_one = :package_id
	    and rel_type = 'package_folder'
	"]
}


ad_proc -public intranet_fs::get_project_folder_id {
    {-project_id:required}
} {
    
    Returns the folder id of the intranet project 
    
} {
    return [util_memoize [list intranet_fs::get_project_folder_id_not_cached -project_id $project_id]]
}

ad_proc -public intranet_fs::get_project_folder_id_not_cached {
    {-project_id:required}
} {
    Returns the folder id of the intranet project not chached
} {
    
    return [db_list select_folder_id "
	select object_id_two 
	from acs_rels 
	where object_id_one = :project_id
	and rel_type = 'project_folder'
    "] 
}

ad_proc -public intranet_fs::get_fs_package_id {
} {
    Return the package_id of the filestorage instance that intranet-core runs
} {

    set package_id [db_list select_package_id "
	select package_id from apm_packages where package_key = 'file-storage'
    "]

    return $package_id
}


ad_proc -public intranet_fs::create_project_folder {
    {-project_id:required}
} {
    Create and relate folder to project 
    
    @return folder_id ID of the created folder
} {

    util_memoize_flush [list intranet_fs::get_project_folder_id_not_cached -project_id $project_id]
    set parent_id [db_string parent_id "select parent_id from im_projects where project_id=:project_id" -default ""]

    if {$parent_id eq ""} { 
	# get the folder id of the intranet projects root dir, which is  'projects'
	# Assume we are using the first file-storage instance we can find for that
	set package_id [db_string get_package_id " select package_id from apm_packages where package_key = 'file-storage' limit 1" ]
	set root_folder_id [fs::get_root_folder -package_id $package_id]
	set parent_folder_id [fs::get_folder -name "projects" -parent_id $root_folder_id]
    } else { 
	set parent_folder_id [db_list get_folder_id { select object_id_two from acs_rels where object_id_one = :parent_id and rel_type = 'project_folder'}]

	if {$parent_folder_id eq ""} {
	    # Recursively create the folders
	    intranet_fs::create_project_folder -project_id $parent_id
	}
    }	
    
    set project_name [db_string project_name "select project_name from im_projects where project_id = $project_id" -default ""]
    set folder_name [string tolower [util_text_to_url -text $project_name]]
    set folder_id [fs::new_folder \
		   -name $folder_name \
		   -pretty_name $project_name \
		   -parent_id $parent_folder_id
		]
	
	set rel_id [relation_add "project_folder" $project_id $folder_id]
	return $folder_id
}



ad_proc -public im_fs_component { 
    -project_id
    -user_id
    -return_url
} { 
} {

    # ---------------------------------------------------------------------
    # Intranet FS 
    # ---------------------------------------------------------------------

    # make sure we have a project and not a task
    if {[db_string object_type "select object_type from acs_objects where object_id = :project_id"] ne "im_project"} {
	return
    }
    
    set folder_id [intranet_fs::get_project_folder_id -project_id $project_id]

    if {$folder_id eq ""} {
		# we don't have a folder_id as the project was created without one. Now we need to create a folder for the project
		set folder_id [intranet_fs::create_project_folder -project_id $project_id]
    }
    
    set params [list  [list base_url "/intranet-fs/"]  [list folder_id $folder_id] [list return_url [im_biz_object_url $project_id]]]
    
    set result [ad_parse_template -params $params "/packages/intranet-fs/lib/intranet-fs"]
    return [string trim $result]
    
}


# Deleting the project folder 
ad_proc -public -callback im_project_after_delete -impl fs_folder {
	{-object_id:required}
    {-status_id}
    {-type_id}
} {
    
	Delete the folders from the project

    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2010-09-27
    
	@param project_id Project_id of the project
    @return             nothing
    @error
} {

    if {[db_0or1row select_folder_id "
	select object_id_two, rel_id
	from acs_rels 
	where object_id_one = :object_id
	and rel_type = 'project_folder'
    "]} {
    
        db_string del_rel "select acs_rel__delete(:rel_id) from dual"
        
        content::folder::delete -folder_id $object_id_two -cascade_p 1
    }
}
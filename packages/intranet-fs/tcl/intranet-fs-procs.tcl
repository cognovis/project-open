
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
    {-try_parent:boolean}
} {
    
    Returns the folder id of the intranet project 
    
} {
    set folder_id [util_memoize [list intranet_fs::get_project_folder_id_not_cached -project_id $project_id]]
    
    if {$try_parent_p} {
        if {$folder_id eq ""} {
            set parent_id [db_string parent_id "select parent_id from im_projects where project_id = :project_id" -default ""]
            if {$parent_id ne ""} {
                set folder_id [intranet_fs::get_project_folder_id -project_id $parent_id -try_parent]
            }
        }
    }
    return $folder_id
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
        order by object_id_two asc
        limit 1   
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

    util_memoize_flush_pattern [list intranet_fs::get_project_folder_id_not_cached -project_id $project_id]
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
    
    # If the parend_folder_id is empty then we usually us -100 for parent
    if {$parent_folder_id ne ""} {
        set folder_id [db_string folder_id "select item_id from cr_items where name = :folder_name and parent_id = :parent_folder_id" -default ""]
    } else {
        set folder_id [db_string folder_id "select item_id from cr_items where name = :folder_name and parent_id = -100" -default ""]
    }
    if {$folder_id eq ""} {
        set folder_id [fs::new_folder \
                           -name $folder_name \
                           -pretty_name $project_name \
                           -parent_id $parent_folder_id
                      ]
    }	
    set rel_id [relation_add "project_folder" $project_id $folder_id]
    callback intranet_fs::after_project_folder_create -project_id $project_id -folder_id $folder_id

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

    ds_comment "folder $folder_id"
    if {$folder_id eq ""} {
		# we don't have a folder_id as the project was created without one. Now we need to create a folder for the project
		set folder_id [intranet_fs::create_project_folder -project_id $project_id]
    }
    
    set params [list  [list base_url "/intranet-fs/"]  [list folder_id $folder_id] [list project_id $project_id] [list return_url [im_biz_object_url $project_id]]]
    
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


ad_proc -public -callback im_project_after_update -impl intranet-fs_update_parent_folder {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    Move the imap folder to the new parent project
} {

    set project_id $object_id
    
    set project_folder_id [db_string project_folder_id {
	SELECT object_id_two FROM acs_rels WHERE object_id_one = :project_id AND rel_type = 'project_folder'
    } -default ""]
    
    
    set new_parent_id [db_string parent_id {
	SELECT parent_id FROM im_projects WHERE project_id = :project_id
    } -default ""]
    
    if {[exists_and_not_null new_parent_id]} {
	set new_parent_folder_id [db_string select_folder_id {
	    SELECT object_id_two FROM acs_rels WHERE object_id_one = :new_parent_id AND rel_type = 'project_folder'
	} -default ""]
    } else {
	#in case it is a root project the parent folder is the main folder "projects", which is retrieved from intranet-core package instance
	set new_parent_id  [db_string select_package_id {
	    SELECT package_id FROM apm_packages WHERE package_key = 'intranet-core'
	} -default ""]
	
	if {[exists_and_not_null new_parent_id]} {
	    set new_parent_folder_id [db_string select_folder_id {
		SELECT object_id_two FROM acs_rels WHERE object_id_one = :new_parent_id AND rel_type = 'package_folder'
	    } -default ""]
	}
    }

    # Check this out! API content::item::move later
    db_exec_plsql update_folder_parent_id {
	SELECT content_folder__move(:project_folder_id,:new_parent_folder_id)
    }  
}


ad_proc intranet_fs::copy_folder {
    -source_folder_id
    -destination_folder_id
} {
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2010-09-24
    
    Copies the folder to another parent folder
    Makes sure to copy the permissions as well
	It does not work correctly if you have folder_names in the orignal folder which are the same.

    @param destination_folder_id Folder ID of the destination folder below which the folder will be copied
    @param source_folder_id Folder ID of the folder to be copied
} {
    set user_id [ad_conn user_id]
    set peer_addr [ad_conn peeraddr]

    # Make sure we have write permission on the destination folder
    permission::require_permission \
 	-party_id $user_id \
 	-object_id $destination_folder_id \
 	-privilege "write"
    
    permission::require_permission \
 	-party_id $user_id \
 	-object_id $source_folder_id \
 	-privilege "read"
    
    # Make sure both are actually folders
    if {![content::folder::is_folder -item_id $source_folder_id] || ![content::folder::is_folder -item_id $destination_folder_id]} {
	return 0
    }
    
    set new_parent_folder_id [db_string copy_folder {
        select content_folder__copy (
           :source_folder_id,
           :destination_folder_id,
           :user_id,
           :peer_addr
      )}]
    

	# This folder compare does not work if the original folder has folders with the same name!
    db_multirow folders folder_compare {
	select source.item_id as old_folder_id, target.item_id as new_folder_id, security_inherit_p
	from (select children.item_id, children.name, security_inherit_p 
	      from cr_items children, cr_items parent, acs_objects o
	      where children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) 
	      and parent.tree_sortkey <> children.tree_sortkey 
	      and parent.item_id = :source_folder_id
	      and children.item_id = o.object_id
	      order by children.tree_sortkey) source,
	(select children.item_id, children.name 
	 from cr_items children, cr_items parent 
	 where children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) 
	 and parent.tree_sortkey <> children.tree_sortkey 
	 and parent.item_id = :new_parent_folder_id
	 order by children.tree_sortkey) target
	where source.name = target.name
    } {
    }

    template::multirow foreach folders {
		if {$security_inherit_p eq "t"} {
		    permission::copy -from_object_id $old_folder_id -to_object_id $new_folder_id -overwrite
		} else {
		    permission::copy -from_object_id $old_folder_id -to_object_id $new_folder_id -overwrite -clean_inheritance
		}
	}
	
	
    if {[permission::inherit_p -object_id $source_folder_id]} {
		permission::copy -from_object_id [content::item::get_parent_folder -item_id $source_folder_id] -to_object_id $new_parent_folder_id -clean_inheritance -overwrite
    } else {
		permission::copy -from_object_id $source_folder_id -to_object_id $new_parent_folder_id -clean_inheritance -overwrite
    }
}


ad_proc -public -callback intranet_fs::after_project_folder_create {
	{-project_id:required}
	{-folder_id:required}
} {
	After the project folder has been created, you can do additional things like copying a preset of folders from a template directory to the newly created folder. Very useful for translation folders
	
	@param project_id ID of the project in which the project folder resides
	@param folder_id New folder_id of the created folder for the project
} -
# /packages/intranet-filestorage/tcl/intranet-filestorage-procs.tcl
#
# Copyright (C) 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Sencha Ticket Tracker Library
    @author frank.bergmann@project-open.com
}


# Create a new content folder for the specified object
ad_proc -public im_fs_content_folder_for_object { 
    -object_id:required
    {-path ""}
} {
    Returns the folder_id of the specified path for the specified
    object. Creates necessary folders on the fly.
    @parm path Optional path within the object's FS
} {
    return [im_fs_content_folder_for_object_helper -object_id $object_id -path $path]
#    return [util_memoize [list im_fs_content_folder_for_object_helper -object_id $object_id -path $path]]
}


# Create a new content folder for the specified object
ad_proc -public im_fs_content_folder_for_object_helper { 
    -object_id:required
    {-path ""}
} {
    Returns the folder_id of the specified path for the specified
    object. Creates necessary folders on the fly.
    @parm path Optional path within the object's FS
} {
    ns_log Notice "im_fs_content_folder_for_object_helper: object_id=$object_id, path=$path"
    # Check if the folder already exists and return it
    set folder_id [db_string fs_folder "
        select  fs_folder_id
        from    im_biz_objects
        where   object_id = :object_id
    " -default ""]
    if {"" != $folder_id} { return $folder_id }

    # Prepare the variables that we need in order to create a new folder
    ns_log Notice "im_fs_content_folder_for_object_helper: Prepare to create new folder"
    set user_id [ad_maybe_redirect_for_registration]
    set package_id [db_string package "select min(package_id) from apm_packages where package_key = 'file-storage'"]
    db_0or1row object_info "
	select	o.object_type,
		pretty_plural as object_pretty_plural,
		acs_object__name(o.object_id) as object_name_pretty
	from	acs_objects o,
		acs_object_types ot
	where	o.object_id = :object_id and
		o.object_type = ot.object_type
    "
    if {![info exists object_pretty_plural]} {
	ns_log Error "im_fs_content_folder_for_object: didn't find object #$object_id"
	return ""
    }
    
    # Get the root folder for the fs instance
    set root_folder_id [fs::get_root_folder -package_id $package_id]
    if {"" == $root_folder_id} {
	set root_folder_id [fs::new_root_folder -package_id $package_id]
    }
    ns_log Notice "im_fs_content_folder_for_object_helper: root_folder_id=$root_folder_id"

    # Default folder name for the object: Append the object's unique ID
    # to the object's pretty name
    set object_paths [list]
    switch $object_type {
	im_project - im_ticket {
	    db_1row project_info "
	        select	p.project_nr,
	                p.project_path,
	                c.company_path
	        from	im_projects p,
	                im_companies c
	        where	p.project_id = :object_id
	                and p.company_id = c.company_id
	    "
	    set object_paths [list $company_path $project_nr]
	}
	user - person - im_employee {
	    set object_paths [list $object_id]
	}
    }
    if {"" == $object_paths} {
	# By default use a single path based on the object's name and ID
        set object_path [list $object_name_pretty - $object_id]
    }

    # The path we want to create
    set file_paths [split $path "/"]
    set file_paths [concat $object_paths $file_paths]
    set file_paths [linsert $file_paths 0 $object_pretty_plural]

    ns_log Notice "im_fs_content_folder_for_object_helper: file_paths=$file_paths"

    set path ""
    set parent_folder_id $root_folder_id
    foreach p $file_paths {
	append path "/${p}"
	ns_log Notice "im_fs_content_folder_for_object_helper: path='$path'"

	ns_log Notice "im_fs_content_folder_for_object_helper: content::item::get_id -item_path $path -root_folder_id $root_folder_id"
	set folder_id [content::item::get_id -item_path $path -root_folder_id $root_folder_id]
	ns_log Notice "im_fs_content_folder_for_object_helper: folder_id='$folder_id'"

	if {"" == $folder_id} {

	    # create the folder and grant "Admin" to employees
	    ns_log Notice "im_fs_content_folder_for_object_helper: content::folder::new -parent_id $parent_folder_id -name $p -label $p"
	    set folder_id [content::folder::new -parent_id $parent_folder_id -name $p -label $p]

	    # All the folder to contain FS files
	    content::folder::register_content_type -folder_id $folder_id -content_type "file_storage_object"

	    # Allow all employees to admin the new folder
	    permission::grant -party_id [im_profile_employees] -object_id $folder_id -privilege "admin"
	}
	ns_log Notice "im_fs_content_folder_for_object: oid=$object_id: path=$path, parent_id=$parent_folder_id => folder_id=$folder_id"
	set parent_folder_id $folder_id
    }

    # Save the new folder to the biz_object table
    db_dml project_folder_save "
	update im_biz_objects set 
		fs_folder_id = :folder_id,
		fs_folder_path = :path
	where object_id = :object_id
    "

    return $folder_id
}


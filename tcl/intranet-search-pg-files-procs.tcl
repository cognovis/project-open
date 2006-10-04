# /packages/intranet-search-pg-files/tcl/intranet-search-pg-files-procs.tcl
#
# Copyright (C) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    File Search Library
    @author frank.bergmann@project-open.com
}

# -------------------------------------------------------
# PackageID
# -------------------------------------------------------

ad_proc -public im_package_intranet_pg_files_id {} {
    Returns the package id of the intranet-search-pg-files module
} {
    return [util_memoize "im_package_search_pg_files_id_helper"]
}

ad_proc -private im_package_search_pg_files_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-search-pg-files'
    } -default 0]
}



# -------------------------------------------------------
# Search Indexing Functions
# -------------------------------------------------------

ad_proc -public intranet_search_pg_files_index_object {
    -object_id
} {
    Index the files of a single objec such as a project, company or user.
} {
    set object_type [db_string otype "select object_type from acs_objects where object_id = :object_id" -default ""]
    set debug "intranet_search_pg_files_index_object($object_type, $object_id)\n"
    ns_log Notice $debug
    if {"" == $object_type} { return "" }

    set find_cmd [im_filestorage_find_cmd]

    # Delete all files from the DB associated with this object
    db_dml delete_files "
	delete from im_fs_files
	where folder_id in (
		select	folder_id
		from	im_fs_folders
		where	object_id = :object_id
	)
    "

    # Home Filestorage depends on object type...
    switch $object_type {
	im_project { set home_path [im_filestorage_project_path $object_id] }
	im_company { set home_path [im_filestorage_company_path $object_id] }
	user { set home_path [im_filestorage_user_path $object_id] }
	default { ad_return_redirect 1 "Unknown object type: '$object_type'" }
    }

    set home_path_len [expr [string length $home_path] + 1]

    set files [list]
    if {[catch {
	set file_list [exec $find_cmd $home_path -type f]
	set files [lsort [split $file_list "\n"]]
    } errmsg]} {
	set str "Unable to get list of files for '$home_path':\n$errmsg"
	ns_log Notice $str
	append debug "$str\n"
    }

    foreach file_path $files {

	ns_log Notice "intranet_search_pg_files_index_object: $file_path"

	# Remove the "home_path" from the returned value
	set file_path [string range $file_path $home_path_len end]
	
	# ToDo: What happens if there are more then one folder for
	# one object, even thought the path is ""?
	if {"" != $file_path} {
	    set path_sql ":file_path"
	} else {
	    set path_sql "''"
	}

	# Split the remaining path into folder path and file body
	set pieces [split $file_path "/"]
	set body [lindex $pieces [expr [llength $pieces]-1]]
	set folder_path [join [lrange $pieces 0 end-1] "/"]
	
	# Make sure the folder exists...
	set folder_id [db_string folder_exists "
		select	folder_id 
		from	im_fs_folders 
		where	object_id = :object_id
			and path = $path_sql
        " -default 0]

	# Create the folder if it doesn't exist yet
	if {!$folder_id} {
	    set folder_id [db_nextval im_fs_folder_seq]

	    db_dml insert_folder_sql "
		insert into im_fs_folders (
			folder_id, object_id, path
		) values (
			:folder_id, :object_id, $path_sql
		)
	    "
	}

	set user_id 624
	set file_id [db_nextval im_fs_file_seq]
	db_dml insert_file "
		insert into im_fs_files (
			file_id, folder_id,
			owner_id, filename,
			exists_p, last_updated
		) values (
			:file_id, :folder_id,
			:user_id, :body,
			'1', now()
		)
        "

	# ToDo: Optimize: This update seems to be
	# necessary in order to trigger indexing
	db_dml update_file "update im_fs_files set owner_id = :user_id where file_id = :file_id"

    }   

    return $debug
}


ad_proc -public intranet_search_pg_files_index_all {
} {
    Index the entire server
} {
    set debug "intranet_search_pg_files_index_all"
    ns_log Notice $debug

    # What object types should we index?
    set biz_object_types {im_project user im_company}

    foreach otype $biz_object_types {
	db_1row object_type_info "
		select	*
		from	acs_object_types
		where	object_type = :otype
        "

	set objects_sql "
		select	$id_column as object_id
		from	$table_name
        "
	db_foreach object_list $objects_sql {
	    set d [intranet_search_pg_files_index_object -object_id $object_id]
	    append debug $d
	}
    }
    return $debug
}


ad_proc intranet_search_pg_files_search_indexer {} {
    Index the entire server.
    This routine is schedule every 60 seconds or so.
    We use this to determine the "oldest" business object
    to be index and update it.
} {
    set unindexed_projects_sql "
	select	project_id 
	from	im_projects
	where	project_id not in (
			select object_id 
			from im_search_pg_file_biz_objects
	)
    "
    db_foreach unindexed_projects $unindexed_projects_sql {
	db_dml insert_project "
		insert into im_search_pg_file_biz_objects (
			object_id, last_update
		) values (
			:project_id, (now()::date - 365)::timestamptz
		)
        "
    }

    set unindexed_companies_sql "
	select	company_id 
	from	im_companies
	where	company_id not in (
			select object_id 
			from im_search_pg_file_biz_objects
	)
    "
    db_foreach unindexed_companies $unindexed_companies_sql {
	db_dml insert_company "
		insert into im_search_pg_file_biz_objects (
			object_id, last_update
		) values (
			:company_id, (now()::date - 365)::timestamptz
		)
        "
    }

    set unindexed_persons_sql "
	select	person_id 
	from	persons
	where	person_id not in (
			select object_id 
			from im_search_pg_file_biz_objects
	)
    "
    db_foreach unindexed_persons $unindexed_persons_sql {
	db_dml insert_person "
		insert into im_search_pg_file_biz_objects (
			object_id, last_update
		) values (
			:person_id, (now()::date - 365)::timestamptz
		)
        "
    }


    # Index ONLY the oldest biz object
    set oldest_object_sql "
	select	object_id
	from	im_search_pg_file_biz_objects
	order by last_update
	limit 1
    "
    db_foreach oldest_objects $oldest_object_sql {

	intranet_search_pg_files_index_object -object_id $object_id

	# Mark the last object as the last object...
	db_dml update_oldest_object "
		update im_search_pg_file_biz_objects
		set last_update = now()
		where object_id = :object_id
        "
    }
}


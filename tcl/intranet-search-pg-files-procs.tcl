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
    Returns the number of new files.
} {
    set debug 0
    set object_type [db_string otype "
	select object_type 
	from acs_objects 
	where object_id = :object_id
    " -default ""]

    ns_log Notice "im_ftio($object_type, $object_id)"
    if {"" == $object_type} { 
	# It's possible that the object has been deleted,
	# so delete the entry from the queue.
	# The main routine makes sure that all existing objects
	# are queued.
	db_dml del_queue "
		delete from im_search_pg_file_biz_objects 
		where object_id = :object_id
	"
	return 0 
    }

    set admin_user_id [im_sysadmin_user_default]
    set find_cmd [im_filestorage_find_cmd]

    # Home Filestorage depends on object type...
    switch $object_type {
	im_project { set home_path [im_filestorage_project_path $object_id] }
	im_company { set home_path [im_filestorage_company_path $object_id] }
	user { set home_path [im_filestorage_user_path $object_id] }
	default { 
	    ns_log Error "im_ftio($object_id): Unknown object type: '$object_type'" 
	    return 0
	}
    }

    # Read all files associated with the current objects
    # into an array for quick comparison:
    # Filename -> ChangeDate
    set all_files_sql "
	select	ff.path as folder_path,
		f.filename,
		f.last_modified as db_last_modified
	from
		im_fs_folders ff,
		im_fs_files f
	where
		ff.object_id = :object_id
		and ff.folder_id = f.folder_id
    "
    db_foreach all_files $all_files_sql {
	set key "$folder_path/$filename"
	set last_modified($key) $db_last_modified
	ns_log Notice "im_ftio: db_last_modified = $db_last_modified, path='$folder_path/$filename'"
    }


    set home_path_len [expr [string length $home_path] + 1]

    set files [list]
    if {[catch {
	set file_list [exec $find_cmd $home_path -type f -printf "%h/%f\t%T@\n"]
	set files [lsort [split $file_list "\n"]]
    } errmsg]} {
	ns_log Notice "Unable to get list of files for '$home_path':\n$errmsg"
	return 0
    }

    # Go through the list of all files on the hard disk:
    set file_ctr 0
    foreach file_entry $files {

	ns_log Notice "im_ftio: $file_entry"
	# Split the file_entry into file_path and file_last_modified
	# Remove the "home_path" from the returned value
	# Split the remaining path into folder path and file body
	# Retreive the "last_modified" information from the database.
	set file_entries [split $file_entry "\t"]
	set file_path [lindex $file_entries 0]
	set file_last_modified [lindex $file_entries 1]
	set file_path [string range $file_path $home_path_len end]
	set pieces [split $file_path "/"]
	set body [lindex $pieces [expr [llength $pieces]-1]]
	set folder_path [join [lrange $pieces 0 end-1] "/"]
	if {"" != $folder_path} { set path_sql ":folder_path" } else { set path_sql "''" }
	set db_last_modified ""
	set db_last_modified_key "$folder_path/$body"
	if {[info exists last_modified($db_last_modified_key)]} {
	    set db_last_modified $last_modified($db_last_modified_key)
	}
	
	if {$debug} {
	    ns_log Notice "im_ftio: file_path=$file_path"
	    ns_log Notice "im_ftio: pieces=$pieces"
	    ns_log Notice "im_ftio: body=$body"
	    ns_log Notice "im_ftio: folder_path=$folder_path"
	    ns_log Notice "im_ftio: path_sql=$path_sql"
	    ns_log Notice "im_ftio: file_last_modified=$file_last_modified"
	    ns_log Notice "im_ftio: db_last_modified=$db_last_modified"
	}

	# Remember that the file exists, so that we can delete the
	# non-existing files later (after the main loop).
	set file_exists_key "$folder_path/$body"
	set file_exists($file_exists_key) $file_last_modified

	# Skip adding the file to the database if the modified
	# date is still the same...
	if {$db_last_modified == $file_last_modified} { 
	    ns_log Notice "im_ftio: last_modfied not changed: $db_last_modified"
	    continue 
	} 
	
	# ------------------ File has changed - Update DB ----------------------
	ns_log Notice "im_ftio: last_modfied changed: db:$db_last_modified - file:$file_last_modified"

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
	    ns_log Notice "im_ftio: new folder_id=$folder_id"
	    db_dml insert_folder_sql "
		insert into im_fs_folders (
			folder_id, object_id, path
		) values (
			:folder_id, :object_id, $path_sql
		)
	    "
	}
	ns_log Notice "im_ftio: folder_id=$folder_id"

	# Check if file exists
	set file_id [db_string file_id "
		select	file_id
		from	im_fs_files
		where	folder_id = :folder_id
			and filename = :body
	" -default 0]

	if {0 == $file_id} {

	    # Insert a new file
	    set file_id [db_nextval im_fs_file_seq]
	    db_dml insert_file "
		insert into im_fs_files (
			file_id, folder_id,
			owner_id, filename,
			last_updated, last_modified
		) values (
			:file_id, :folder_id,
			:admin_user_id, :body,
			now(), :file_last_modified
		)
            "
	    ns_log Notice "im_ftio: insert: file_id=$file_id"

	} else {

	    # File exists - Update the new modification date
	    db_dml update_file "
		update im_fs_files set 
			ft_indexed_p = '0',
			last_modified = :file_last_modified
		where file_id = :file_id
	    "
	    ns_log Notice "im_ftio: update: file_id=$file_id, file_last_modified=$file_last_modified"

	}

	# ToDo: Optimize: This update seems to be
	# necessary in order to trigger indexing
	db_dml update_file "update im_fs_files set owner_id = :admin_user_id where file_id = :file_id"

	incr file_ctr
    }   


    # ------------------ Check if file have disappreared ----------------------
    # In this case we need to delete the entries from the DB...
#   ns_log Notice "im_ftio: last_modified: '[array get file_exists]'"
    foreach filename [array names last_modified] {

	if {![info exists file_exists($filename)]} {

	    # The filename is present in the DB, but not on disk anymore
	    # => Delete the DB-entry
	    ns_log Notice "im_ftio: del: doesn't exist in the FS: '$filename'"

	    # Split the remaining path into folder path and file body
	    set pieces [split $file_path "/"]
	    set body [lindex $pieces [expr [llength $pieces]-1]]
	    set folder_path [join [lrange $pieces 0 end-1] "/"]

	    # Deal with empty string == "null" in the db-interface.
	    if {"" != $folder_path} {
		set path_sql ":folder_path"
	    } else {
		set path_sql "''"
	    }

	    # Delete all files from the DB associated with this object
	    db_dml delete_files "
		delete	from im_fs_files
		where	folder_id in (
				select	folder_id
				from	im_fs_folders
				where	object_id = :object_id
					and path = $path_sql
			)
			and filename = :body

            "
	}

    }

    return $file_ctr
}


ad_proc -public intranet_search_pg_files_index_all {
} {
    Index the entire server
} {
    set debug "im_fti_index_all"
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


ad_proc intranet_search_pg_files_search_indexer {
    {-max_files 0}
} {
    Index the entire server.
    This routine is schedule every 60 seconds or so.
    We use this to determine the "oldest" business object
    to be index and update it.
} {

    if {0 == $max_files} {
	set max_files [parameter::get_from_package_key -package_key intranet-search-pg-files -parameter IndexerMaxFiles -default 100]
    }

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
	select	object_id as search_object_id
	from	im_search_pg_file_biz_objects
	order by last_update
	limit :max_files
    "
    set ctr 0
    db_foreach oldest_objects $oldest_object_sql {

	set nfiles [intranet_search_pg_files_index_object -object_id $search_object_id]
	
	# Mark the last object as the last object...
	db_dml update_oldest_object "
		update im_search_pg_file_biz_objects
		set last_update = now()
		where object_id = :search_object_id
        "

	set ctr [expr $ctr + $nfiles]
	if {$ctr > $max_files} { break }
    }
}


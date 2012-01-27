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
# Full-Text File Indexing
# -------------------------------------------------------

ad_proc -public intranet_search_pg_files_fti_content {
    {-max_content_length 100000}
    filename
} {
    Extract and normalize the file contents -
    using a best effort attempt using variuos filters
} {
    ns_log Notice "intranet_search_pg_files_fti_content: '$filename'"

    # Skip if not readable
    if {![file readable $filename]} { 
	return "not readable: '$filename'" 
    }
    set lower_filename [string tolower $filename]

    # Determine file type (extension). There can be strange cases where
    # the ending could be ".doc.bz2.LCK"
    set file_ext "unknown"
    if {[regexp {\.([a-z]+)$} $lower_filename match match_file_ext]} {
	set file_ext $match_file_ext
    }

    # Fun with encoding - We may encounter files encoded using
    # "binary", "latin-1", "utf-8" etc. Try binary first


    set catdoc "/usr/local/bin/catdoc"
    set wvtext "/usr/bin/wvText"
    set htmltotext "/usr/bin/html2text"

    # Process the contents depending on file type (extensions)
    switch $file_ext {
	txt - perl - text - php - sql {
	    # Just get the file's content
	    if {[catch {
		set encoding "binary"
		set fl [open $filename]
		fconfigure $fl -encoding $encoding
		set content [read $fl]
		close $fl
	    } err]} {
		ns_log Error "intranet_search_pg_files_fti_content: $filename: Unable to open: $err"
		return "intranet_search_pg_files_fti_content: $filename: Unable to open: $err"
	    }
	}
	doc {
	    # Convert using wvText doc->text converter
	    if {[catch {
		set content [exec $catdoc -s8859-1 -d8859-1 $filename]
	    } err]} {
		ns_log Error "intranet_search_pg_files_fti_content: '$err'"
		return "intranet_search_pg_files_fti_content: '$err'"
	    }
	}
	htm - html - xml - asp {
	    # Convert html to text
	    if {[catch {
		set content [exec $htmltotext -nobs $filename]
	    } err]} {
		ns_log Error "intranet_search_pg_files_fti_content: '$err'"
		return "intranet_search_pg_files_fti_content: '$err'"
	    }
	}
	gif - jpg - pgp - bmp - png - wav - mp3 - ico { set content "" }
	log - bz2 - zip - tar - tgz - rar - gz - js - mso { set content "" }
	xls - rtf - exe { set content "" }
	default { set content "" }
    }

    # Normalize contents
    set content [string tolower $content]
    set content [string map -nocase {"@" " " "\\" " " "." " " "-" " " "_" " " ":" " " ";" " "} $content]
    set content [string map -nocase {"\<" " " "\>" " " "\{" " " "\}" " " "\[" " " "\]" " "} $content]
    set content [string map -nocase {"\(" " " "\)" " " "!" " " "?" " " "=" " "} $content]
    set content [string map -nocase {"\"" " " "\'" " " "/" " " "+" " " "*" " " "," " "} $content]
    set content [string map -nocase {"\$" " " "\#" " "} $content]
    set content [string map -nocase {"\n" " " "\t" " "} $content]
    set content [string map -nocase {"" " " "" " " "" " " "" " " "" " " "" " "} $content]

    # Replace multiple spaces
    regsub -all {\ +} $content " " content


    if {[string length $content] > $max_content_length} {
	set content "file truncated to $max_content_length: [string range $content 0 $max_content_length]"
    } 

    ns_log Notice "intranet_search_pg_files_fti_content: $filename => $content"
    return $content
}


# -------------------------------------------------------
# Search Indexing Functions
# -------------------------------------------------------

ad_proc -public intranet_search_pg_files_index_object {
    -object_id
    {-debug 1}
} {
    Index the files of a single object such as a project, company or user.
    Returns the number of new files + a list of error messages as a list
} {
    # List of errors to be returned
    set error_list [list]
    lappend error_list "intranet_search_pg_files_index_object: starting to index object_id=$object_id"
    lappend error_list "intranet_search_pg_files_index_object: "

    # Should we index the contents of the files?
    set fti_contents_enabled_p [parameter::get_from_package_key -package_key intranet-search-pg-files -parameter IndexFileContentsP -default 0]
    lappend error_list "intranet_search_pg_files_index_object: fti_contents_enabled_p=$fti_contents_enabled_p"

    set object_type [db_string otype "
	select object_type 
	from acs_objects 
	where object_id = :object_id
    " -default ""]

    lappend error_list "im_ftio($object_type, $object_id)"
    if {"" == $object_type} { 
	# It's possible that the object has been deleted,
	# so delete the entry from the queue.
	# The main routine makes sure that all existing objects
	# are queued.
	db_dml del_queue "
		delete from im_search_pg_file_biz_objects 
		where object_id = :object_id
	"
	return [list 0 $error_list]
    }

    set admin_user_id [im_sysadmin_user_default]
    set find_cmd [im_filestorage_find_cmd]

    # Home Filestorage depends on object type...
    switch $object_type {
	im_project { set home_path [im_filestorage_project_path $object_id] }
	im_ticket { set home_path [im_filestorage_ticket_path $object_id] }
	im_timesheet_task { set home_path [im_filestorage_project_path $object_id] }
	im_company { set home_path [im_filestorage_company_path $object_id] }
	im_cost { set home_path [im_filestorage_cost_path $object_id] }
	user { set home_path [im_filestorage_user_path $object_id] }
	default { 
	    lappend error_list "im_ftio($object_id): Unknown object type: '$object_type'" 
	    return [list 0 $error_list]
	}
    }
    lappend error_list "im_ftio: home_path=$home_path"

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
    set ofiles {}
    db_foreach all_files $all_files_sql {
	set key "$folder_path/$filename"
	set last_modified($key) $db_last_modified
	lappend error_list "im_ftio: file=$key, db_last_modified=$db_last_modified"
	lappend ofiles $key
    }
    lappend error_list "im_ftio: existing files: $ofiles"


    set home_path_len [expr [string length $home_path] + 1]

    set files [list]
    if {[catch {
	set file_list [exec $find_cmd $home_path -type f -printf "%h/%f\t%T@\n"]
	set files [lsort [split $file_list "\n"]]
    } errmsg]} {
	lappend error_list "im_ftio: Unable to get list of files for '$home_path':\n$errmsg"
	return [list 0 $error_list]
    }

    lappend error_list "im_ftio: file_list=$file_list"

    # Go through the list of all files on the hard disk:
    set file_ctr 0
    foreach file_entry $files {

	lappend error_list "im_ftio: $file_entry"
	# Split the file_entry into file_path and file_last_modified
	# Remove the "home_path" from the returned value
	# Split the remaining path into folder path and file body
	# Retreive the "last_modified" information from the database.
	set file_entries [split $file_entry "\t"]
	set filename [lindex $file_entries 0]
	set file_last_modified [lindex $file_entries 1]
	set file_path [string range $filename $home_path_len end]
	set pieces [split $file_path "/"]
	set body [lindex $pieces [expr [llength $pieces]-1]]
	set folder_path [join [lrange $pieces 0 end-1] "/"]
	if {"" != $folder_path} { set path_sql ":folder_path" } else { set path_sql "''" }
	set db_last_modified ""
	set db_last_modified_key "$folder_path/$body"
	if {[info exists last_modified($db_last_modified_key)]} {
	    set db_last_modified $last_modified($db_last_modified_key)
	}
	
	if {0 && $debug} {
	    lappend error_list "im_ftio: filename=$filename"
	    lappend error_list "im_ftio: file_path=$file_path"
	    lappend error_list "im_ftio: pieces=$pieces"
	    lappend error_list "im_ftio: body=$body"
	    lappend error_list "im_ftio: folder_path=$folder_path"
	    lappend error_list "im_ftio: path_sql=$path_sql"
	    lappend error_list "im_ftio: file_last_modified=$file_last_modified"
	    lappend error_list "im_ftio: db_last_modified=$db_last_modified"
	}

	# Remember that the file exists, so that we can delete the
	# non-existing files later (after the main loop).
	set file_exists_key "$folder_path/$body"
	set file_exists($file_exists_key) $file_last_modified

	# ------------------ Check if the file has changed ----------------------
	# Skip adding the file to the database if the modified
	# date is still the same...
	if {$db_last_modified == $file_last_modified} { 
	    lappend error_list "im_ftio: last_modfied did not change - skipping: $db_last_modified"
	    continue 
	} 
	
	# ------------------ File has changed - Update DB ----------------------
	lappend error_list "im_ftio: last_modfied changed: db:$db_last_modified - file:$file_last_modified"

	# Determine the file content. Not all companies need the contents
	# indexed. In particular, translation companies only need the file
	# _names_, instead of the file _contents_, because the contents are
	# related to their customers, but not to their business.
	set fti_content ""
	if {$fti_contents_enabled_p} {

	    if {$debug > 0} {

		set fti_content [intranet_search_pg_files_fti_content $filename]

	    } else {

		if {[catch {
		    set fti_content [intranet_search_pg_files_fti_content $filename]
		} errmsg]} {
		    set fti_content "Error parsing '$filename': '$errmsg'"
		}
	    }
	    lappend error_list "im_ftio: fti_content=$fti_content"

	}

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
	    lappend error_list "im_ftio: new folder_id=$folder_id"
	    db_dml insert_folder_sql "
		insert into im_fs_folders (
			folder_id, object_id, path
		) values (
			:folder_id, :object_id, $path_sql
		)
	    "
	}
	lappend error_list "im_ftio: folder_id=$folder_id"

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
			last_updated, last_modified,
			fti_content
		) values (
			:file_id, :folder_id,
			:admin_user_id, :body,
			now(), :file_last_modified,
			:fti_content
		)
            "
	    lappend error_list "im_ftio: insert: file_id=$file_id"

	} else {

	    # File exists - Update the new modification date
	    db_dml update_file "
		update im_fs_files set 
			ft_indexed_p = '0',
			last_modified = :file_last_modified,
			fti_content = :fti_content
		where file_id = :file_id
	    "
	    lappend error_list "im_ftio: update: file_id=$file_id, file_last_modified=$file_last_modified"

	}

	# ToDo: Optimize: This update seems to be
	# necessary in order to trigger indexing
	db_dml update_file "update im_fs_files set owner_id = :admin_user_id where file_id = :file_id"

	incr file_ctr
    }   


    # ------------------ Check if file have disappreared ----------------------
    # In this case we need to delete the entries from the DB...
#   lappend error_list "im_ftio: last_modified: '[array get file_exists]'"
    foreach filename [array names last_modified] {

	if {![info exists file_exists($filename)]} {

	    # The filename is present in the DB, but not on disk anymore
	    # => Delete the DB-entry
	    lappend error_list "im_ftio: del: doesn't exist in the FS: '$filename'"

	    # Split the remaining path into folder path and file body
	    set pieces [split $filename "/"]
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

    return [list $file_ctr $error_list]
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
    This routine is schedule every 600 seconds or so.
    We use this to determine the "oldest" business object
    to be index and update it.
} {
    # Make sure that only one thread is indexing at a time
    if {[nsv_incr intranet_search_pg_files search_indexer_p] > 1} {
	nsv_incr intranet_search_pg_files search_indexer_p -1
	ns_log Notice "intranet_search_pg_files_search_indexer: Aborting. There is another process running"
	return
    }

    set ctr 0
    if {[catch {

	if {0 == $max_files} {
	    set max_files [parameter::get_from_package_key -package_key intranet-search-pg-files -parameter IndexerMaxFiles -default 100]
	}
	
	set unindexed_projects_sql "
		select	project_id 
		from	im_projects
		EXCEPT
		select	object_id
		from	im_search_pg_file_biz_objects
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
		EXCEPT
		select	object_id
		from	im_search_pg_file_biz_objects
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
		EXCEPT
		select	object_id
		from	im_search_pg_file_biz_objects
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
	
	    set result [intranet_search_pg_files_index_object -object_id $search_object_id]
	    set nfiles [lindex $result 0]
	    
	    # Mark the last object as the last object...
	    db_dml update_oldest_object "
			update im_search_pg_file_biz_objects
			set last_update = now()
			where object_id = :search_object_id
	    "
	
	    set ctr [expr $ctr + $nfiles]
	    if {$ctr > $max_files} { break }
	}
	
    } errmsg]} {
	ns_log Error "intranet_search_pg_files_search_indexer: Error: $errmsg"
    }
	
    nsv_incr intranet_search_pg_files search_indexer_p -1

    return $ctr
}


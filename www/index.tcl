ad_page_contract {
    Empty redirection index.tcl file
} {

}

set user_id [ad_get_user_id]


ad_proc -public intranet_search_pg_files_index_object {
    -object_type
    -object_id
} {
    Index the files of a single objec such as a project, company or user.
} {
    ns_log Notice "intranet_search_pg_files_index_object($object_type, $object_id)"

    set find_cmd [im_filestorage_find_cmd]

    # Home Filestorage depends on object type...
    switch $object_type {
	im_project { set home_path [im_filestorage_project_path $object_id] }
	im_company { set home_path [im_filestorage_company_path $object_id] }
	user { set home_path [im_filestorage_user_path $object_id] }
	default { ad_return_redirect 1 "Unknown object type: '$object_type'" }
    }

    set home_path_len [expr [string length $home_path] + 1]
    set dir_list [exec $find_cmd $home_path -type d]
    set dirs [lsort [split $dir_list "\n"]]
    set file_list [exec $find_cmd $home_path -type f]
    set files [lsort [split $file_list "\n"]]

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

	append debug "path='$path' body='$body' folder_id=$folder_id\n"
    }   
}


set debug ""
set biz_object_types {im_project user im_company}
set cnt 0

foreach otype $biz_object_types {
    set otype_sql "
	select	*
	from	acs_object_types
	where	object_type = :otype
    "
    db_1row object_type_info $type_sql

    set objects_sql "
	select	$id_column as object_id
	from	$table_name
    "
    db_foreach object_list $objects_sql {
	intranet_search_pg_files_index_object $otype $object_id
    }
    incr cnt

    if {$cnt > 10} { ad_return_complaint 1 "<pre>\n$debug\n</pre>" }

}

ad_return_complaint 1 "<pre>\n$debug\n</pre>"
return



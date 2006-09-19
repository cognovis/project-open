ad_page_contract {
    Empty redirection index.tcl file
} {

}
 
set user_id [ad_get_user_id]
set object_id 0
set find_cmd [im_filestorage_find_cmd]
set home_path [im_filestorage_home_path]
set home_path_len [expr [string length $home_path] + 1]

set dir_list [exec $find_cmd $home_path -type d]
set dirs [lsort [split $dir_list "\n"]]

foreach folder_path $dirs {

    set path [string range $folder_path $home_path_len end]
    append debug "folder_path='$path'\n"

    if {"" != $path} {
	set path_sql ":path"
    } else {
	set path_sql "''"
    }


    # Make sure the folder exists...
    set folder_id [db_string folder_exists "
	select	folder_id 
	from	im_fs_folders 
	where	object_id = :object_id 
		and path = $path_sql
    " -default 0]
    ns_log Notice "pg-file: folder_id=$folder_id"

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
}

append debug "\n"

set file_list [exec $find_cmd $home_path -type f]
set files [lsort [split $file_list "\n"]]

foreach file_path $files {

    # Remove the "home_path" from the returned value
    set file_path [string range $file_path $home_path_len end]

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

ad_return_complaint 1 "<pre>\n$debug\n</pre>"
return


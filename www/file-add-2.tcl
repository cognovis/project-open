ad_page_contract {
    script to recieve the new file and insert it into the database

    @author Kevin Scaldeferri (kevin@arsdigita.com)
    @creation-date 6 Nov 2000
    @cvs-id $Id$
} {
    folder_id:integer,notnull
    upload_file:notnull,trim
    upload_file.tmpfile:tmpfile
    object_id:integer,notnull
    return_url:notnull
    title:notnull,trim
    description
} -validate {
    valid_folder -requires {folder_id:integer} {
	if ![fs_folder_p $folder_id] {
	    ad_complain "[_ attachments.lt_The_specified_parent_]"
	}
    }

    max_size -requires {upload_file} {
	set n_bytes [file size ${upload_file.tmpfile}]
	set max_bytes [ad_parameter "MaximumFileSize"]
	if { $n_bytes > $max_bytes } {
            # Max number of bytes is used in the error message
            set max_number_of_bytes [util_commify_number $max_bytes]
	    ad_complain "[_ attachments.lt_Your_file_is_larger_t]"
	}
    }
} 

# Check for write permission on this folder
ad_require_permission $folder_id write

# Get the filename part of the upload file
if ![regexp {[^//\\]+$} $upload_file filename] {
    # no match
    set filename $upload_file
}

# Get the user
set user_id [ad_conn user_id]

# Get the ip
set creation_ip [ad_conn peeraddr]

set root_folder [attachments::get_root_folder]
set fs_package_id [db_string get_fs_package_id {}]

#db_transaction {
    set file_id [db_nextval "acs_object_id_seq"]
    fs::add_file \
            -name $upload_file \
            -item_id $file_id \
            -parent_id $folder_id \
            -tmp_filename ${upload_file.tmpfile}\
            -creation_user $user_id \
            -creation_ip $creation_ip \
            -title $title \
            -description $description \
            -package_id $fs_package_id
                                                                                                                          
    # attach the file_id
    attachments::attach -object_id $object_id -attachment_id $file_id

#} on_error {

    # most likely a duplicate name or a double click

#    set folder_url index?folder_id?$folder_id
#    ad_return_complaint 1 "[_ attachments.lt_You_probably_clicked_]"

#       ad_script_abort
#}


ad_returnredirect $return_url

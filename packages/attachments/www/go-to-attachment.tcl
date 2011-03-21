
ad_page_contract {
    Go to an attachment
    
    @author Ben Adida (ben@openforce.net)
} {
    {object_id:integer,notnull}
    {attachment_id:integer,notnull}
}

# We check permissions on the object
permission::require_permission -object_id $object_id -privilege read

# Get information about attachment
set content_type [item::get_type $attachment_id]
if { [string length $content_type] == 0 } {
    ad_return_complaint 1 [_ attachments.lt_No_such_attachment_fo]
    return
}

switch $content_type {
    content_extlink {
        ad_returnredirect [db_string select_url {}]
        ad_script_abort
        return
    }

    file_storage_object {
        db_1row select_attachment_info {}
        if {[parameter::get -package_id $package_id -parameter BehaveLikeFilesystemP -default 0]} {
            set filename $title
        } else {
            set filename $name
        }
	
	# Test if the filename contains the extension, otherwise append it
	# This usually happens if you just rename the title (displayed filename) but forget
	# to append the extension to it.

	#file extension return "." extension without "."
	set file_extension_aux [concat .$file_extension]

	set extension [file extension $filename]
	if {$extension ne $file_extension_aux} {
	    append filename ".${file_extension}"
	}

        ad_returnredirect "download/[ad_urlencode $filename]?object_id=$object_id&attachment_id=$attachment_id"
        ad_script_abort
        return
    }
    
    default {
        ad_return_complaint 1 [_ attachments.lt_dont_know_how_to_deal [list content_type $content_type]]
        return
    }
}

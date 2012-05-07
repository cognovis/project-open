# /packages/intranet-mail-import/www/get-mail-list.tcl
#
# Copyright (C) 2003 - 2012 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {

    return json of object atributes for users & projects 	
		
    @author klaus.hofeditz@project-open.com
    @creation-date May 2012
} {
    { view_mode "json" }
    { callback "" }
    { query "" }
    { email_id }	
    { object_id }	
    { remove_mails_p }
}
	set debug ""
	set mail_dir "/web/projop/Maildir"
	set defered_folder "$mail_dir/defered"
	set processed_folder "$mail_dir/processed"

	# Check if file exists 
	if { ![file exists $email_id] } {
                ns_log Notice "assign-mail-to-object: mail_id not found: $email_id"
		ns_return 500 text/html 0
    	}

        # Get file name
        set msg_paths [split $email_id "/"]
        set email_file_name [lindex $msg_paths [expr [llength $msg_paths] - 1] ]

	if { "-1" != $object_id } {
		catch {
			set cr_item_id [db_exec_plsql im_mail_import_new_message {}]
	                ns_log Notice "assign-mail-to-object: created spam_item $email_id"
        	        append debug "created spam_item \\#$email_id\n"

			set object_type [db_string get_object_type "select object_type from acs_objects where object_id = :object_id" -default 0]		
			if { "user" == $object_type } {
                	    set rel_type "im_mail_from"
	                    set object_id_two $object_id
        	            set object_id_one $cr_item_id
                	    set creation_user $user_id
	                    set creation_ip $peeraddr
			    set rel_id [db_exec_plsql im_mail_import_new_rel {}]
                	    ns_log Notice "assign-mail-to-object: created relationship \\#$rel_id"
	                    append debug "created relationship \\#$rel_id\n"
			} else {
                	    set rel_type "im_mail_related_to"
	                    set object_id_two $object_id
        	            set object_id_one $cr_item_id
                	    set creation_user $user_id
	                    set creation_ip $peeraddr
			    set rel_id [db_exec_plsql im_mail_import_new_rel {}]
                	    ns_log Notice "assign-mail-to-object: created relationship \\#$rel_id"
	                    append debug "created relationship \\#$rel_id\n"
			}
		}

        	# Move to "processed"
		if { "true" != $remove_mails_p } {
			if {[catch {
                		ns_log Notice "assign-mail-to-object: Moving '$email_id' to processed: '$processed_folder/$email_id'"
	                	append debug "Moving '$email_id' to processed: '$processed_folder/$email_id'\n"
	        	        ns_rename $email_id "$processed_folder/$email_file_name"
			} errmsg]} {
        		        ns_log Notice "assign-mail-to-object: Error moving '$email_id' to processed: '$processed_folder/$email_file_name': '$errmsg'"
                		append debug "Error moving '$email_id' to processes: '$processed_folder/$email_file_name': '$errmsg'\n"
			}
		}
	} else {
		if {[catch {
                        ns_rename $email_id "/tmp/$email_file_name"
                   } errmsg]} {
                        ns_log Notice "assign-mail-to-object: Error moving '$email_id' to temp folder: '/tmp/$email_file_name': '$errmsg'"
                        append debug "Error moving '$email_id' to temp folder: '/temp/$email_file_name': '$errmsg'\n"
                   }
	}

ns_return 200 text/html $debug

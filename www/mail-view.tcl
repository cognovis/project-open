# /packages/intranet-mail-import/www/mail-view.tcl
#
# Copyright (C) 2004 - 2013 ]project-open[
#
# All rights reserved.
# Please check http://www.project-open.org/en/project_open_license for licensing
# details.

ad_page_contract {
    View a mail either from the CR (content_item_id != 0) or from FS (msg_id = filename) 
} {
    content_item_id:integer
    { msg_id "" }
    { view_mode "all" }
}

#-- ------------------------------------------
#   Defaults and Security   
#-- ------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

# Check Permission  
if { 0 != $content_item_id } {
    set body_id [db_string get_data "select body_id from acs_mail_bodies where content_item_id= :content_item_id" -default 0]
    if { ![im_is_user_site_wide_or_intranet_admin $current_user_id] && ![im_permission $current_user_id view_mails_all] } {
	# Permission check
	set sql " 
		select 	count(*)	
		from 	acs_rels 
		where 
			object_id_one = :current_user_id and 
			object_id_one in ( 	
				select 	object_id_one 	
				from 	acs_rels 
				where object_id_two in (select object_id_two from acs_rels where object_id_one = :body_id) 
			)
    	"
	    if { 0 == [db_string get_data $sql -default 0] } { 
		ns_return 200 text/html [lang::message::lookup "" intranet-mail.NoPermissionToViewMail "You do not have the permissions to view this email"]
		break
    	    }
     }
} else {
	# User needs to be admin or needs to have the privilege 'view_mails_all' to view a mail from the FS 
	if { ![im_is_user_site_wide_or_intranet_admin $current_user_id] && ![im_permission $current_user_id view_mails_all] } {
		ns_return 200 text/html [lang::message::lookup "" intranet-mail.NoPermissionToViewMail "You do not have the permissions to view this email"]
		break		
	}
}


if { 0 != $content_item_id } {
	
	# Show mail from CR ---------------------------------------------------------------------------	
	
	set title ""
	set context [list]
	set field_list [acs_mail_body_to_output_format -body_id $body_id]

	# Setting Mail headers 
	set to [lindex $field_list 0]
	set from [lindex $field_list 1]
	set subject [mime::field_decode [lindex $field_list 2]]

	# Setting BODY 
	set body [lindex $field_list 3]

	set extraheaders [lindex $field_list 4]
	set send_date [db_string sent "select to_char(creation_date, 'YYYY-MM-DD HH24:MI:SS') from acs_objects where object_id=:body_id" -default ""]
	set object_id [db_string get_view_id "select object_id_two from acs_rels where object_id_one =:body_id and rel_type = 'im_mail_related_to'" -default 0]
	set object_type [db_string get_object_type "select object_type from acs_objects where object_id = :object_id" -default 0]

	set attachment_html ""
	set list_attachments ""

	if { 0 != $object_id } {
	    if { "im_project" == $object_type } {
		set project_path [db_string get_view_id "select project_path from im_projects where project_id =$project_id" -default 0]
		set list_attachments [im_filestorage_find_files $project_id]
		append attachment_html "<div style='width:600px;'>" 

		foreach url $list_attachments {
		    set file_path [im_filestorage_project_path_helper $project_id]
		    set cr_item_id [string range $url [expr [string length $file_path]+7] [expr [string length $file_path] + [string length :body_id] + 3 ] ]
		    if { 0 == [string compare $body_id $cr_item_id] } {
			set file_name [string range $url [expr [string length $file_path] + [string length $body_id] + 8] [string length $url]]
			set file_extension [file extension $url]
			set file_icon [im_filestorage_file_type_icon $file_extension]
			set rel_file_path "/intranet/download/project/$project_id/mails/$body_id/$file_name"
			append attachment_html "<div style='float:left;margin:10px;'><a href='$rel_file_path'>$file_icon</a><br><a href='$rel_file_path'>$file_name</a></div>"
		    }
		}
		append attachment_html "</div>" 
	    } 

	    if { "user" == $object_type } {
		ns_log Notice "mail_view: object_type = 'user'"
		if { [catch {
		    set file_path [im_filestorage_user_path $object_id]
		    set find_cmd [im_filestorage_find_cmd]
		    set file_list [exec $find_cmd $file_path -noleaf -type f]
		    set list_attachments [lsort [split $file_list "\n"]]
		} err_msg] } {
		    # Probably some permission errors - return empty string
		    ns_log Error " mail-view, looking for attachments (user) err_msg=$err_msg\n"
		    set file_list ""
		}
                append attachment_html "<div style='width:600px;'>"
                foreach url $list_attachments {
                    set cr_item_id [string range $url [expr [string length $file_path]+7] [expr [string length $file_path] + [string length :body_id] + 3 ] ]
                    if { 0 == [string compare $body_id $cr_item_id] } {
                        set file_name [string range $url [expr [string length $file_path] + [string length $body_id] + 8] [string length $url]]
                        set file_extension [file extension $url]
                        set file_icon [im_filestorage_file_type_icon $file_extension]
                        set rel_file_path "/intranet/download/user/$object_id/mails/$body_id/$file_name"
                        append attachment_html "<div style='float:left;margin:10px;'><a href='$rel_file_path'>$file_icon</a><br><a href='$rel_file_path'>$file_name</a></div>"
                    }
                }
                append attachment_html "</div>"
	    }
	} 
} else {
	# Show mail from FS ---------------------------------------------------------------------------	
	set send_date ""

	# set mail_dir [parameter::get -package_id [apm_package_id_from_key intranet-mail-import] -parameter "MailDir" -default "/web/projop/Maildir"]
	# if { ![file exists $mail_dir] } {
        	# ad_return_complaint 1 "Configuration problem. Please tell your SysAdmin to set parameter: intranet-mail-import -> MailDir"
    	# }

	if {[catch {
        	# set messages [glob "$mail_dir/defered/$msg_id"]
        	set messages [glob "$msg_id"]
	    } errmsg]} {
	            append debug "No message found: '$errmsg'\n"
        	    return $debug
    	}

	# foreach mail in defered folder
	foreach msg $messages {

	        # Get the last piece of the Msg
        	set msg_paths [split $msg "/"]
	        set msg_body [lindex $msg_paths [expr [llength $msg_paths] - 1] ]

	        # Read the entire mail into memory...
        	if [catch {
	            set f [open $msg r]
        	    set file [read $f]
	            close $f
        	}] {
		    continue
	        }
        	set file_lines [split $file "\n"]

        	set end_of_headers_p 0
	        set i 0
        	set line [lindex $file_lines $i]
	        set headers [list]

        	# walk through the headers and extract each one
	        while ![empty_string_p $line] {
        	    set next_line [lindex $file_lines [expr $i + 1]]
	            if {[regexp {^[ ]*$} $next_line match] && $i > 0} {
        	            set end_of_headers_p 1
            	    }
	            if {[regexp {^([^:]+):[ ]+(.+)$} $line match name value]} {
        	        # concat header lines
                	if { ![regexp {^([^:]+):[ ]+(.+)$} $next_line match] && !$end_of_headers_p} {
	                    append line $next_line
        	            incr i
                	}
	                lappend headers [string tolower $name] $value
	                if {$end_of_headers_p} {
        	            incr i
                	    break
                	}
            	    } else {
	                # The headers and the body are delimited by a null line as specified by RFC822
        	        if {[regexp {^[ ]*$} $line match]} {
                	    	incr i
                    		break
                	}
            	    }
		    incr i
	            set line [lindex $file_lines $i]
        	}
	        set body "\n[join [lrange $file_lines $i end] "\n"]"

	        # Extract headers values
        	array set email_headers $headers

	        set from ""
        	set to ""
	        set subject "No Subject"

        	catch {set from [string map { "\"" "" } $email_headers(from)]}
	        catch {set to [string map { "\"" "" } $email_headers(to)]}
        	catch {set subject [mime::field_decode $email_headers(subject)]}

	        # remove double quotes from 'from' and 'to'
        	regsub -all "\"" $from "" from
        	regsub -all "\"" $to "" to
    	}
	set attachment_html ""
}


# strip html part from html email 
if { [string first "<html>" [string tolower $body]] != -1 } {
    set start_html [string first "<html>" [string tolower $body]]
    set stop_html [string first "</html>" [string tolower $body]]
    set body [string range $body $start_html [expr $stop_html + 7]]
}


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
        ns_log Notice "assign-mail-to-object: check if email exists: $email_id"

	if { ![file exists $email_id] } {
                ns_log Notice "assign-mail-to-object: mail_id not found: $email_id"
		ns_return 500 text/html 0
    	}

        # Get file name
        set msg_paths [split $email_id "/"]
        set email_file_name [lindex $msg_paths [expr [llength $msg_paths] - 1] ]
	
        ns_log Notice "assign-mail-to-object: object_id: $object_id"
	
	if { "-1" != $object_id } {
            if [catch {
		    # Read the entire mail into memory...
		    if [catch {
		       set f [open $email_id r]
		       set file [read $f]
		       close $f
		     }] {
		          continue
	             }
		     set file_lines [split $file "\n"]

		     set new_messages 1
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
		     ns_log Notice "assign-mail-to-object: mail_header='[join $headers "' '"]'"

		     # Extract headers values
		     array set email_headers $headers
		     set from_header ""
		     set to_header ""
		     set subject_header "No Subject"
		     catch {set from_header $email_headers(from)}
		     catch {set to_header $email_headers(to)}
		     catch {set subject_header $email_headers(subject)}

		     # Massage the header a bit
		     regsub {=\?iso-....-.\?.\?} $subject_header "" subject_header

		     set rfc822_message_id ""
		     if {[info exists email_headers(message-id)]} {
		     	set rfc822_message_id $email_headers(message-id)
			# remove the <...> brackets
			if {[regexp {\<([^\>]*)\>} $rfc822_message_id match id]} {
			     	set rfc822_message_id $id
                	}
			ns_log Notice "assign-mail-to-object: message-id=$rfc822_message_id"
		     } else {
		       ns_log Notice "assign-mail-to-object: No message_id found"
                     }

		     ns_log Notice "assign-mail-to-object: from_header=$from_header"
		     ns_log Notice "assign-mail-to-object: to_header=$to_header"
		     ns_log Notice "assign-mail-to-object: subject_header=$subject_header"
		     ns_log Notice "assign-mail-to-object: rfc822_message_id=$rfc822_message_id"

	                set cr_item_id ""
            		set subject $subject_header
			set html ""
			set plain $body
			set context_id ""
	                set user_id [db_string admin "select min(member_id) from group_distinct_member_map where group_id = [im_admin_group_id]"]
			set peeraddr "0.0.0.0"
			set approved_p 1

			set send_date [db_string now "select current_date from dual"]
			set header_from $from_header
			set header_to $to_header
			set rfc822_id $rfc822_message_id

			set object_type [db_string get_object_type "select object_type from acs_objects where object_id = :object_id" -default 0]		
                        ns_log Notice "assign-mail-to-object: object_type $object_type"

			set sql "
			select im_mail_import_new_message (
			        :cr_item_id,    -- cr_item_id
				null,           -- reply_to
				null,           -- sent_date
       				null,           -- sender
       				:rfc822_id,     -- rfc822_id
       				:subject,       -- title
       				:html,          -- html_text
       				:plain,         -- plain_text
       				:context_id,    -- context_id
       				now(),          -- creation_date
     				:user_id,       -- creation_user
       				:peeraddr,      -- creation_ip
       				'im_mail_message', -- object_type
       				:approved_p,    -- approved_p
       				:send_date,     --send_date
       				:header_from,   -- header_from
       				:header_to      -- header_to
				)
			"

			if {[catch {
			   set cr_item_id [db_string get_data $sql -default 0]
		        } err_msg]} {
			   ns_log Notice "assign-mail-to-object: Error creating cr_item: $err_msg"
			   break
			}

	                ns_log Notice "assign-mail-to-object: created spam_item $email_id"
        	        append debug "created spam_item \\#$email_id\n"

			if { "user" == $object_type } {
                	    set rel_type "im_mail_from"
			} else {
                	    set rel_type "im_mail_related_to"
			}

	                set object_id_two $object_id
        	        set object_id_one $cr_item_id
                	set creation_user $user_id
	                set creation_ip $peeraddr

			set sql "
			select acs_rel__new (
			        null,           -- rel_id
				:rel_type,      -- rel_type
        			:object_id_one,
        			:object_id_two,
        			null,           -- context_id
        			:creation_user,
        			:creation_ip
			        )
			"
			if {[catch {
			   set rel_id [db_string get_data $sql -default 0]
		        } err_msg]} {
			   ns_log Notice "assign-mail-to-object: Could not create relationship: $err_msg"
			   break
			}
			ns_log Notice "assign-mail-to-object: created relationship \\#$rel_id"
	                append debug "created relationship \\#$rel_id\n"


		    # ###
		    # store attachments in project folder
		    # ###

		    # get attachments
		    array set email {}
		    acs_mail_lite::parse_email -file $email_id -array email
		    set email_files $email(files)

		    set file_name ""

		    if { "im_project" == $object_type } {
		        ns_log Notice "assign-mail-to-object: Found object type project"
			set project_id $object_id 
			# determine project folder
			set project_path [im_filestorage_project_path $project_id]
			append project_path "/mails"
			
			# Make sure the mail folder in projects exists, if not create it
			if {![file exists $project_path]} {
			    if {[catch { ns_mkdir $project_path } err_msg]} {
				ns_log Notice "assign-mail-to-object: Error creating '$project_path' folder: '$err_msg'"
				append debug "Error creating '$project_path' folder: '$err_msg'\n"
				return $debug
			    }
			}

			# create sub-directory to store attachments for cr_item
			append project_path "/$cr_item_id"

			if {[catch { ns_mkdir $project_path } errmsg]} {
			    ns_log Notice "assign-mail-to-object: Error creating '$project_path' folder: '$errmsg'"
			    append debug "Error creating '$project_path' folder: '$errmsg'\n"
			    return $debug
			}
			foreach attachment $email_files {
			    append file_name $project_path "/" [lindex $attachment 2]
			    set content [lindex $attachment 3]
			    set fp [open $file_name w]
			    fconfigure $fp -translation binary
			    fconfigure $fp -encoding binary
			    puts -nonewline $fp $content
			    close $fp
			    set file_name ""
			}
		}

		# ###
        	# Move to "processed"
		# ###

		if { "true" != $remove_mails_p } {
			if {[catch {
                		ns_log Notice "assign-mail-to-object: Moving '$email_id' to processed: '$processed_folder/$email_id'"
	                	append debug "Moving '$email_id' to processed: '$processed_folder/$email_id'\n"
	        	        ns_rename $email_id "$processed_folder/$email_file_name"
			} errmsg]} {
        		        ns_log Notice "assign-mail-to-object: Error moving '$email_id' to processed: '$processed_folder/$email_file_name': $errmsg"
                		append debug "Error moving '$email_id' to processes: '$processed_folder/$email_file_name': $errmsg \n"
			}
		}
            } err_msg] {
                  ns_log Notice "assign-mail-to-object: Error assigning mail to object: $object_id: $err_msg"
            }
	} else {
		if {[catch {
		    ns_rename $email_id "[fileutil::TempDir]/$email_file_name"
                   } errmsg]} {
		    ns_log Notice "assign-mail-to-object: Error moving '$email_id' to temp folder: '[fileutil::TempDir]/$email_file_name': $errmsg"
		    append debug "Error moving '$email_id' to temp folder: '[fileutil::TempDir]/$email_file_name': $errmsg \n"
                   }
	}

ns_return 200 text/html $debug

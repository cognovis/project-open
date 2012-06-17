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
    { query ""}
}

    ad_proc -private extract_emails__ { line } {
        Extract all emails (asdf@sdfg.dfg) from an email header line

        @option header_line A mail header like such as "from" or "to".
    } {
        ns_log Notice "im_mail_import.extract_emails: line=$line"

        set line [string tolower $line]
        regsub -all {\<} $line " " line
        regsub -all {\>} $line " " line
        regsub -all {\"} $line " " line

        set tokens [split $line " "]
        set emails [list]

        foreach token $tokens {
            if {[regexp {^[a-z0-9_\.\-]+\@[a-z0-9_\.\-]+\.[a-z0-9_\.\-]+$} $token match ]} {
                lappend emails $token
            }
        }

        ns_log Notice "im_mail_import.extract_emails: email=$emails"
        return $emails
    }

    set ctr 0
    set record_list ""
    set mail_dir [parameter::get -package_id [apm_package_id_from_key intranet-mail-import] -parameter "MailDir" -default "/web/projop/Maildir"]

    if { ![file exists $mail_dir] } {
	ad_return_complaint 1 "Configuration problem. Please tell your SysAdmin to set parameter: intranet-mail-import -> MailDir"
    }

    # Make sure the "Maildir/defered" folder exists"
    set defered_folder "$mail_dir/defered"
    if {![file exists $defered_folder]} {
	if {[catch { ns_mkdir $defered_folder } errmsg]} {
	    ns_log Notice "get_mails_from_defered_folder1: Error creating '$defered_folder' folder: '$errmsg'"
	    append debug "Error creating '$defered_folder' folder: '$errmsg'\n"
	    return $debug
	}
    }

    if {[catch {
	set messages [glob "$mail_dir/defered/*"]
    } errmsg]} {
            ns_log Notice "get_mails_from_defered_folder4: No messages: '$errmsg'"
            append debug "No messages: '$errmsg'\n"
            return $debug
    }

    set list_of_bounce_ids [list]
    set new_messages_p 0


    if {0 == [llength $messages]} { append debug "no messages in $mail_dir/defered/\n" }

    set record_list_tmp [list]

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

	ns_log Notice "get_mails_from_defered_folder6: mail_header='[join $headers "' '"]'"

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

	# remove double quotes from 'from' and 'to'
	regsub -all "\"" $from_header "" from_header

	set rfc822_message_id ""
	if {[info exists email_headers(message-id)]} {
	    set rfc822_message_id $email_headers(message-id)
	    # remove the <...> brackets
	    if {[regexp {\<([^\>]*)\>} $rfc822_message_id match id]} {
		        set rfc822_message_id $id
	    }
	    ns_log Notice "get_mails_from_defered_folder9: message-id=$rfc822_message_id"
	} else {
	    ns_log Notice "get_mails_from_defered_folder10: No message_id found"
	}

	# The the list of emails from the To and From fields
	set to_emails [im_mail_import::extract_emails $to_header]
	set from_emails [im_mail_import::extract_emails $from_header]

        set json_record_list ""
	append json_record_list "{\"msg_name\":\"$msg\",\n"
        append json_record_list "\"from_header\":\"$from_header\",\n"
        append json_record_list "\"to_header\":\"$to_header\",\n"
        append json_record_list "\"subject_header\":\"$subject_header\"\n"
	append json_record_list "}\n"
        lappend record_list_tmp $json_record_list
        incr ctr
    }

    set record_list [join $record_list_tmp ", "]

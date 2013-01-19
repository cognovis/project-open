ad_library {

    Reads mail from a Maildir and adds it to OpenACS and ]project-open[
    
    @author Eric Lorenzo (eric@openforce.net)
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 9 August 2005
    @cvs-id $Id$

}

namespace eval im_mail_import {

    ad_proc -public get_package_id {} {
	@returns package_id of this package
    } {
        return [apm_package_id_from_key intranet-mail-import]
    }
    
    ad_proc -private mail_dir {} {
	@returns incoming mail directory to be scanned for bounces
    } {
	set mail_dir [parameter::get -package_id [get_package_id] -parameter "MailDir" -default ""]
	if {"" == $mail_dir} {
	    ns_log Notice "im_mail_import.mail_dir: Didn't find parameter 'MailDir'"
	}
	ns_log Notice "im_mail_import.mail_dir: mail_dir=$mail_dir"
	return $mail_dir
    }
    
    ad_proc -public parse_email_address {
	-email:required
    } {
	Extracts the email address out of a mail address (like Joe User <joe@user.com>)
	@option email mail address to be parsed
	@returns only the email address part of the mail address
    } {
        if {![regexp {<([^>]*)>} $email all clean_email]} {
            return $email
        } else {
            return $clean_email
        }
    }

    ad_proc -public extract_emails { line } {
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

    ad_proc -public extract_project_nrs { line } {
        Extract all project_nrs (2007_xxxx) from an email header line
    } {
	ns_log Notice "im_mail_import.extract_project_nrs: line=$line"
	set line [string tolower $line]
	regsub -all {\<} $line " " line
	regsub -all {\>} $line " " line
	regsub -all {\"} $line " " line
	regsub -all {\]} $line " " line
	regsub -all {\[} $line " " line

        ns_log Notice "im_mail_import.extract_project_nrs - regsubed: line=$line"

	set tokens [split $line " "]
	ns_log Notice "im_mail_import.extract_project_nrs - tokens: $tokens"

	set project_nrs [list]

	foreach token $tokens {

	    ns_log Notice "im_mail_import.extract_project_nrs-loop-token: $token"

	    # Tokens must be built from aphanum plus "_" or "-".
	    if {![regexp {^[a-z0-9_\-]+$} $token match ]} { continue }

	    # Discard tokens purely from alphabetical
	    if {[regexp {^[a-z]+$} $token match ]} { continue }

	    lappend project_nrs $token
	}

	ns_log Notice "im_mail_import.extract_project_nrs: returning project_nrs=$project_nrs"
	return $project_nrs
    }

    ad_proc -public map_emails_to_ids { 
	-email_list:required
	{-subject "" }
    } {
	Maps a list of emails to a list of User-IDs.
	Skips emails that are not present in the system.

        @option email_list A list of email address
    } {
	ns_log Notice "im_mail_import.map_emails_to_ids1: email_list=$email_list"
        set ids [list]

	set sql "
		select	party_id
		from	parties
		where	lower(email) = :email
	"

	# "Notes" support for multiple email addresses per user.
	if {[im_table_exists "im_notes"]} {
	    append sql "
	    UNION
		select	object_id
		from	im_notes
		where	lower(note) = :email
	    "
	}
	
	foreach email $email_list {
	    set email [string trim [string tolower $email]]
	    set party_ids [db_list parties $sql]
	    foreach party_id $party_ids {
		lappend ids $party_id
	    }
	    if {0 == [llength $party_ids]} {
		# Email not found - leave a trace
		catch {
		    db_dml insert_email_stat "
			insert into im_mail_import_email_stats (
				stat_id, stat_email, stat_day, stat_subject
			) values (
				nextval('im_mail_import_email_stats_seq'), :email, now(), :subject
			);
		    "
		} err_msg
	    }
	}

        return $ids
    }

    ad_proc -public map_project_nrs_to_ids { project_nr_list } {
	Maps a list of (potential) project_nrs to a list of project_ids
    } {
        set ids [list]
	set condition "('[join [string tolower $project_nr_list] "', '"]')"

	set sql "
		select	project_id
		from	im_projects
		where	lower(project_nr) in $condition
	"
        return [db_list emails_to_ids $sql]
    }

    ad_proc -public process_mails {
        -mail_dir:required
	{ -max_mails 20 }
    } {
        Processes all emails in MailDir
        @option mail_dir Maildir location
    } {
	set debug "\n"

	# Make sure the "Maildir/spam" folder exists"
	set spam_folder "$mail_dir/spam"
	if {![file exists $spam_folder]} {
	    if {[catch { ns_mkdir $spam_folder } errmsg]} {
		ns_log Notice "im_mail_import.process_mails0: Error creating '$spam_folder' folder: '$errmsg'"
		append debug "Error creating '$spam_folder' folder: '$errmsg'\n"
		return $debug
	    }
	}

	# Make sure the "Maildir/defered" folder exists"
	set defered_folder "$mail_dir/defered"
	if {![file exists $defered_folder]} {
	    if {[catch { ns_mkdir $defered_folder } errmsg]} {
		ns_log Notice "im_mail_import.process_mails1: Error creating '$defered_folder' folder: '$errmsg'"
		append debug "Error creating '$defered_folder' folder: '$errmsg'\n"
		return $debug
	    }
	}

	# Make sure the "Maildir/processed" folder exists"
	set processed_folder "$mail_dir/processed"
	if {![file exists $processed_folder]} {
	    if {[catch { ns_mkdir $processed_folder } errmsg]} {
		ns_log Notice "im_mail_import.process_mails2: Error creating '$processed_folder' folder: '$errmsg'"
		append debug "im_mail_import.process_mails3: Error creating '$processed_folder' folder: '$errmsg'\n"
		return $debug
	    }
	}

        if {[catch {
            set messages [glob "$mail_dir/new/*"]
        } errmsg]} {
            ns_log Notice "im_mail_import.process_mails4: No messages: '$errmsg'"
            append debug "No messages: '$errmsg'\n"
            return $debug
        }

        set list_of_bounce_ids [list]
        set new_messages_p 0
	set ctr 0

	if {0 == [llength $messages]} { append debug "no messages in $mail_dir/new/\n" }

	# foreach incoming mail
        foreach msg $messages {

            ns_log Notice "im_mail_import.process_mails5: mail $msg, ctr=$ctr"
	    if {$ctr >= $max_mails}  { return $debug }
            append debug "mail $msg\n"

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

	    ns_log Notice "im_mail_import.process_mails6: mail_header='[join $headers "' '"]'"

            # Extract headers values
            array set email_headers $headers
	    set from_header ""
	    set to_header ""
	    set subject_header "No Subject"
            catch {set from_header $email_headers(from)}
            catch {set to_header $email_headers(to)}
            catch {set subject_header $email_headers(subject)}

	    # 20130108 KH: Removed - Use mime::field_decode $subject instead
	    # Massage the header a bit
	    # regsub {=\?iso-....-.\?.\?} $subject_header "" subject_header

	    set spam_header ""
	    if {[info exists email_headers(x-spambayes-classification)]} {
		# Temporarily disabled spam - until Spambayes is trained correctly.
		# set spam_header $email_headers(x-spambayes-classification)
		ns_log Notice "im_mail_import.process_mails7: spam_header=$spam_header"
	    } else {
		ns_log Notice "im_mail_import.process_mails8: No spam header found"
	    }

	    set rfc822_message_id ""
	    if {[info exists email_headers(message-id)]} {
		set rfc822_message_id $email_headers(message-id)
		# remove the <...> brackets
		if {[regexp {\<([^\>]*)\>} $rfc822_message_id match id]} {
		    set rfc822_message_id $id
		}
		ns_log Notice "im_mail_import.process_mails9: message-id=$rfc822_message_id"
	    } else {
		ns_log Notice "im_mail_import.process_mails10: No message_id found"
	    }

            ns_log Notice "im_mail_import.process_mails: from_header=$from_header"
            ns_log Notice "im_mail_import.process_mails: to_header=$to_header"
            ns_log Notice "im_mail_import.process_mails: subject_header=$subject_header"
            ns_log Notice "im_mail_import.process_mails: rfc822_message_id=$rfc822_message_id"

	    # Move to "/spam" if there is a Spambayes header...
            if {[string equal "spam" $spam_header] } {
                if {[catch {
                    ns_log Notice "im_mail_import.process_mails11: Moving '$msg' to spam: '$spam_folder/$msg_body'"
                    append debug "Moving '$msg' to spam: '$spam_folder/$msg_body'\n"
                    ns_rename $msg "$spam_folder/$msg_body"
                } errmsg]} {
                    ns_log Notice "im_mail_import.process_mails12: Error moving '$msg' to spam: '$spam_folder/$msg_body': '$errmsg'"
                    append debug "Error moving '$msg' to spam: '$spam_folder/$msg_body': '$errmsg'\n"
                }
		continue
            }

	    # The the list of emails from the To and From fields
	    set to_emails [extract_emails $to_header]
	    set from_emails [extract_emails $from_header]

	    # Map the emails to user IDs. Use zero_ids to make sure
	    # that the list isn't empty.
	    set to_ids [map_emails_to_ids -email_list $to_emails -subject $subject_header]
	    set from_ids [map_emails_to_ids -email_list $from_emails -subject $subject_header]
	    ns_log Notice "im_mail_import.process_mails13: to_ids=$to_ids, from_ids=$from_ids"

	    # Get the list of all associated projects
	    set project_nrs [extract_project_nrs $subject_header]
	    ns_log Notice "im_mail_import.process_mails14: project_nrs=$project_nrs"

	    set project_ids [map_project_nrs_to_ids $project_nrs]
	    ns_log Notice "im_mail_import.process_mails15: project_ids=$project_ids"

	    # List of all ids: set to [list 0] if empty to avoid
	    # syntax errors in SQL
	    set all_ids [set_union $to_ids $from_ids]
	    ns_log Notice "im_mail_import.process_mails15a: all_ids=$all_ids"

	    # Calculate the IDs of non-Employees (=> external persons)
	    set employee_ids [db_list employee_ids "select member_id from group_distinct_member_map where group_id=[im_profile_employees]"]
	    set non_emp_ids [set_difference $all_ids $employee_ids]

	    # set all_object_ids [set_union [set_union $non_emp_ids $project_ids] $all_ids] 
	    set all_object_ids [set_union $non_emp_ids $project_ids]    
	    ns_log Notice "im_mail_import.process_mails15b: all_object_ids=$all_object_ids"

	    ns_log Notice "im_mail_import.process_mails16x: to_ids=$to_ids, from_ids=$from_ids,all_ids=$all_ids, project_ids=$project_ids, all_oids=$all_object_ids, non_emp_ids: $non_emp_ids"

	    # Move to "defered" if there is no object for this email right now...
            if {0 == [llength $all_object_ids]} {
		ns_log Notice "im_mail_import.process_mails16a: Moving mail to defered"
                if {[catch {
                    ns_log Notice "im_mail_import.process_mails17: Moving '$msg' to defered: '$defered_folder/$msg_body'"
                    append debug "Moving '$msg' to defered: '$defered_folder/$msg_body'\n"
                    ns_rename $msg "$defered_folder/$msg_body"
                } errmsg]} {
                    ns_log Notice "im_mail_import.process_mails18: Error moving '$msg' to defered: '$defered_folder/$msg_body': '$errmsg'"
                    append debug "Error moving '$msg' to defered: '$defered_folder/$msg_body': '$errmsg'\n"
                }
		continue
            }

	    ns_log Notice "im_mail_import.process_mails16b: Creating email"

	    # Create an OpenACS object with the mail
	    # 
	    set cr_item_id ""
	    set subject $subject_header
	    set html ""
	    set plain $body
	    set context_id ""
	    ns_log Notice "im_mail_import.process_mails16c: Creating email"
	    set user_id [db_string admin "select min(member_id) from group_distinct_member_map where group_id = [im_admin_group_id]"]
	    set peeraddr "0.0.0.0"
	    set approved_p 1
	    ns_log Notice "im_mail_import.process_mails16d: Creating email"
	    set send_date [db_string now "select current_date from dual"]
	    set header_from $from_header
	    set header_to $to_header
	    set rfc822_id $rfc822_message_id
	    ns_log Notice "im_mail_import.process_mails19: rfc822_id='$rfc822_id'"
	    append debug "rfc822_id='$rfc822_id'\n"

	    ns_log Notice "im_mail_import.process_mails19a: creating spam_item ...."

	    if {[catch {
	 
		# set cr_item_id [db_exec_plsql im_mail_import_new_message {}]
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
       		    );
                "

		set cr_item_id [db_string get_data $sql -default 0]

		ns_log Notice "im_mail_import.process_mails20: created cr_item_id: \#$cr_item_id\n"
	        append debug "created spam_item \#$cr_item_id\n"

		# Assigning to NON-Employees
		ns_log Notice "im_mail_import.process_mails21: Now assigning non_emp_ids: $non_emp_ids"		
		foreach non_emp_id $non_emp_ids {
		    set rel_type "im_mail_from"
		    set object_id_two $non_emp_id
		    set object_id_one $cr_item_id
		    set creation_user $user_id
		    set creation_ip $peeraddr

		    # set rel_id [db_exec_plsql im_mail_import_new_rel {}]
		    set sql "
		      select acs_rel__new (
		              null,           -- rel_id
			      :rel_type,      -- rel_type
			      :object_id_one,
			      :object_id_two,
			      null,           -- context_id
			      :creation_user,
			      :creation_ip
		      );
		    "

		    set rel_id [db_string get_data $sql -default 0]
		    ns_log Notice "im_mail_import.process_mails21a: created relationship \#$rel_id"
		    append debug "created relationship \#$rel_id\n"
		}

		# Assigning to projects 
		ns_log Notice "im_mail_import.process_mails22: No assigning project_ids: $project_ids"		
		foreach project_id $project_ids {
		    set rel_type "im_mail_related_to"
		    set object_id_two $project_id
		    set object_id_one $cr_item_id
		    set creation_user $user_id
		    set creation_ip $peeraddr

		    # set rel_id [db_exec_plsql im_mail_import_new_rel {}]
                    set sql "
                      select acs_rel__new (
                              null,           -- rel_id
                              :rel_type,      -- rel_type
                              :object_id_one,
                              :object_id_two,
                              null,           -- context_id
                              :creation_user,
                              :creation_ip
                      );
                    "
                    set rel_id [db_string get_data $sql -default 0]

		    ns_log Notice "im_mail_import.process_mails22a: created relationship \#$rel_id"
		    append debug "created relationship \#$rel_id\n"
		}
	    } err_msg]} {
                    ns_log Notice "im_mail_import.process_mails19b: err creating spam item / building rel.ships: $err_msg"
	    }

	    # ###
            # store attachments in project folder
	    # ###

            # get attachments
            array set email {}
            acs_mail_lite::parse_email -file $msg -array email
            set email_files $email(files)

            set file_name ""

            foreach project_id $project_ids {
                # determine project folder
                set project_path [im_filestorage_project_path $project_id]
                append project_path "/mails"

                # Make sure the mail folder in projects exists, if not create it
                if {![file exists $project_path]} {
                    if {[catch { ns_mkdir $project_path } errmsg]} {
                        ns_log Notice "im_mail_import.process_mails0: Error creating '$project_path' folder: '$errmsg'"
                        append debug "Error creating '$project_path' folder: '$errmsg'\n"
                        return $debug
                    }
                }

                # create sub-directory to store attachments for cr_item
                append project_path "/$cr_item_id"


                if {[catch { ns_mkdir $project_path } errmsg]} {
                        ns_log Notice "im_mail_import.process_mails0: Error creating '$project_path' folder: '$errmsg'"
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

	    if {[catch {
		ns_log Notice "im_mail_import.process_mails23: Moving '$msg' to processed: '$processed_folder/$msg_body'"
		append debug "Moving '$msg' to processed: '$processed_folder/$msg_body'\n"
		ns_rename $msg "$processed_folder/$msg_body"
	    } errmsg]} {
		ns_log Notice "im_mail_import.process_mails24: Error moving '$msg' to processed: '$processed_folder/$msg_body': '$errmsg'"
		append debug "Error moving '$msg' to processes: '$processed_folder/$msg_body': '$errmsg'\n"
	    }

	    incr ctr

	}
	return $debug
    }
    
    ad_proc -public scan_mails {} {
        Scheduled procedure that will scan for bounced mails
    } {
	# SemP: Only allow one process to process...
	if {[nsv_incr im_mail_import check_mails_p] > 1} {
	    nsv_incr im_mail_import check_mails_p -1
	    return
	}
	
	catch {
	    ns_log Notice "im_mail_import.scan_mails: about to load qmail queue"
	    process_mails -mail_dir [mail_dir]
	} err_msg

	# SemV: Release Semaphore
	nsv_incr im_mail_import check_mails_p -1
    }


    ad_proc -private after_install {} {
        Callback to be called after package installation.
    } {
	# nothing
    }

    ad_proc -private before_uninstall {} {
        Callback to be called before package uninstallation.
    } {
	# nothing
    }
}


ad_proc im_mail_import_user_component {
    {-view_name ""}
    {-rel_user_id 0}
    {-yui_support_p 0}
} {
    Show a list of imported mails
} {
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"

    if {0 == $rel_user_id} {
        set rel_user_id [ad_get_user_id]
    }

    # Other users than the user himself need to be admins or have the privilege view_mails_all
    if { $rel_user_id != [ad_get_user_id]  } {
        if { ![im_is_user_site_wide_or_intranet_admin [ad_get_user_id]] && ![im_permission [ad_get_user_id] view_mails_all] } {
	    return "No Permission"
            break
        }
    }

    # HTML Overlay
    if { $yui_support_p } {
        set js_include [template::adp_include /packages/intranet-mail-import/www/js/overlay ""]
        append js_include [template::adp_include /packages/intranet-mail-import/www/js/client-pagination [list object_id $rel_user_id] ]
    }

    set html "<div id=\"ctx\"></div>"

    if { $yui_support_p } {
        append html "<div class=\"yui-skin-sam\">"
        append html "<div id=\"paginated\"></div>"
    }

    set sql "
        select
                amb.*,
                to_char(ao.creation_date, 'YYYY-MM-DD') as date_formatted
        from
                acs_rels ar,
                acs_mail_bodies amb,
                acs_objects ao
        where
                ar.object_id_one = amb.body_id
                and amb.body_id = ao.object_id
                and ar.object_id_two = :rel_user_id
        order by
                ao.creation_date DESC
    "
    set ctr 0

    set html_lines ""
    db_foreach mail_list $sql {
        if { !$yui_support_p } {
            append html_lines "
                <tr $bgcolor([expr $ctr%2])>
                        <td>$date_formatted</td>
                        <td><a href=\"/intranet-mail-import/mail-view?body_id=$body_id\" id=\"$body_id\">[string_truncate -len 50 $header_subject]</a></td>
                        <td>[string_truncate -len 25 $header_from]</td>
                        <td>[string_truncate -len 25 $header_to]</td>
                </tr>
            "
        }
        incr ctr
    }

    if {0 == $ctr && !$yui_support_p} {
        append html "<tr> <td colspan='99' align='center'>No entries found</td></tr>"
    }

    if { !$yui_support_p && 0 != $ctr} {
        append html "
                <table>
                        <tr class=rowtitle>
                           <td class=rowtitle align=center colspan=99>Associated Emails</td>
                        </tr>
                        <tr class=rowtitle>
                           <td class=rowtitle align=center>Date</td>
                           <td class=rowtitle align=center>Subject</td>
                           <td class=rowtitle align=center>From</td>
                           <td class=rowtitle align=center>To</td>
                        </tr>
                        $html_lines
                </table>
        "
    }

    if { $yui_support_p } {

        # Version 2.7.0 (ajaxhelper) and Version 3.4.1 would not work
        # Get Sources from Yahoo until switch/refactoring to ExtJS

        template::head::add_javascript -src "http://yui.yahooapis.com/2.8.1/build/yahoo-dom-event/yahoo-dom-event.js" -order "100"
        template::head::add_javascript -src "http://yui.yahooapis.com/2.8.1/build/container/container-min.js" -order "101"
        template::head::add_javascript -src "http://yui.yahooapis.com/2.8.1/build/connection/connection-min.js" -order "102"
        template::head::add_javascript -src "http://yui.yahooapis.com/2.8.1/build/element/element-min.js" -order "102"
        template::head::add_javascript -src "http://yui.yahooapis.com/2.8.1/build/paginator/paginator-min.js" -order "102"
        template::head::add_javascript -src "http://yui.yahooapis.com/2.8.1/build/datasource/datasource-min.js" -order "102"
        template::head::add_javascript -src "http://yui.yahooapis.com/2.8.1/build/datatable/datatable-min.js" -order "102"
        template::head::add_javascript -src "http://yui.yahooapis.com/2.8.1/build/json/json-min.js" -order "102"

        template::head::add_css -href "http://yui.yahooapis.com/2.8.1/build/container/assets/skins/sam/container.css" -media "screen" -order "103"
        template::head::add_css -href "http://yui.yahooapis.com/2.8.1/build/paginator/assets/skins/sam/paginator.css" -media "screen" -order "104"
        template::head::add_css -href "http://yui.yahooapis.com/2.8.1/build/datatable/assets/skins/sam/datatable.css" -media "screen" -order "105"

        append html $js_include
        append html "</div>"
    }
    return $html
}

ad_proc im_mail_import_project_component {
    {-project_id 0}
    {-yui_support_p 0}
} {
    Show a list of imported mails
} {
    return [im_mail_import_user_component -rel_user_id $project_id -yui_support_p $yui_support_p]
}

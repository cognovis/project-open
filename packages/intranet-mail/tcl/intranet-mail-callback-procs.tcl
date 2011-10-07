# packages/intranet-mail/tcl/intranet-mail-callback-procs.tcl

## Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
# 

ad_library {
    
    Callback procs
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-04-21
    @cvs-id $Id$
}


ad_proc -public -callback intranet-mail::logged_email {
    -log_id:required
} {
    Callback that is executed once an E-Mail is successfully imported (read: we have a log_id)
} -

ad_proc -public -callback imap::incoming_email -impl intranet-mail-link_mails {
    -session_id:required
    -array:required
} {
    Link mails to the project and users 

    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-04-22
    
    @param array        An array with all headers, files and bodies. To access the array you need to use upvar.
    @return             nothing
    @error
} {
    # get a reference to the email array
    upvar $array email

    set from_addr [lindex $email(from) 1]
    set from_party_id [lindex $email(from) 0]
    if {$from_party_id ne ""} {
        # We don't need to log the sender twice
        set from_addr ""
    }

    # By default, assume you can deal with the mail
    set unprocessed_p 0

    # Figure out the object_id from the subject
    set object_ids [intranet-mail::extract_object_ids -subject $email(subject)]
    ns_log Notice "Loading imap mails:: $object_ids"
    if {$object_ids eq ""} {
        # We did not find an object_id in the subject. 
        # Check if the from_addr has a valid SLA
        if {$from_party_id eq ""} {
            # We don't have an object_id and we can't link the mail to
            # a sender, keep it unprocessed.
            set unprocessed_p 1
        } else {

	    # Check if the sender is an employee. If he is, move to unprocessed directly.
	    if {[im_user_is_employee_p $from_party_id]} {
		set unprocessed_p 1
	    } else {

		# Find out the company
		set company_id [db_string get_company_id "select object_id_one from acs_rels ar, registered_users ru, im_companies ic where ar.object_id_one = ic.company_id and ar.object_id_two = ru.user_id and ru.user_id = :from_party_id" -default ""]
		if {$company_id ne ""} {
		    # Find the SLA
		    set object_ids [db_string get_sla_project_id "select project_id from im_projects where company_id = :company_id and project_type_id = [im_project_type_sla] order by project_id asc limit 1" -default ""]
		} else {
		    set object_ids ""
		}
		if {$object_ids eq ""} {
		    set unprocessed_p 1
		}
	    }
	}
    }

    # Get some defaults
    set sequence_nr $email(sequence_nr)
    set unprocessed_folder [parameter::get_from_package_key -package_key "intranet-mail" -parameter "UnprocessedFolder"]


    # Now we know if we can process the message
    if {$unprocessed_p eq 1} {
        imap::move_mail -session_id $session_id -destination_mailbox $unprocessed_folder -sequence_nr $sequence_nr

        return
    }

    set html_body ""
    set plain_body ""
    foreach email_body $email(bodies) {
        set mime_type [lindex $email_body 0]
        set body_content [lindex $email_body 1]
        if {$mime_type eq "text/html"} {
            append html_body $body_content
        } else {
            append plain_body $body_content
        }
    }

    # Save HTML by default
    if {$html_body ne ""} {
        set body $html_body
    } else {
        set body $plain_body
    }

    # We only get the first object_id, might be expanded in the future
    set object_id [lindex $object_ids 0]

    # find the imap folder. This should be a project
    if {[acs_object_type $object_id] ne "im_project"} {
        # Get the parent, which should be a project
        set project_id [db_string parent_id "select parent_id from im_projects where project_id = :object_id"]
    } else {
        set project_id $object_id
    }

    set imap_folder [intranet-mail::project_imap_folder -project_id $project_id -check_imap]
    if {$imap_folder eq ""} {
        # Throw an error
        ns_log error "No IMAP Folder for object $object_id"
        imap::move_mail -session_id $session_id -destination_mailbox $unprocessed_folder -sequence_nr $sequence_nr
        return
    }

    # Find the folder for the project, but only if we deal with files
    if {$email(files) ne ""} {
    
        # Find out the folder_id.    
        # It is either directly linked to the project or to it's parent.
        
        # We only deal with projects at the moment, in case this get's
        # expanded we definitely need some reworking here as well as
        # intranet-fs
        set package_id [im_package_core_id]

        set project_folder_id [intranet_fs::get_project_folder_id -project_id $project_id -try_parent]
        set mail_folder_name [parameter::get_from_package_key -package_key "intranet-mail" -parameter "MailFolderName" -default "mail"]
        set folder_id [fs::get_folder -name $mail_folder_name -parent_id $project_folder_id]
        if {$folder_id eq ""} {
            # No folder found, throw an error and put the files into
            # the root folder
            ns_log error "No Mail Folder for the attachments..."
            set folder_id [intranet_fs::get_projects_root_folder_id -package_id $package_id]
        }
    }

    # Deal with the files
    set files ""
    set file_ids ""
    # As this is a connection less callback, set the IP Address to
    # local
    set peeraddr "127.0.0.1"

    foreach file $email(files) {
        set mime_type [lindex $file 0]
        set file_title [lindex $file 1]
        set file_path [lindex $file 2]

        # We need a creation user for the content item, so use the
        # sender or the sysadmin.
        if {$from_party_id ne ""} {
            set creation_user $from_party_id
        } else {
            set creation_user [im_sysadmin_user_default]
        }

        set existing_item_id [content::item::get_id_by_name -name $file_title -parent_id $folder_id]
        if {$existing_item_id ne ""} {
            set item_id $existing_item_id
         } else {
            set item_id [db_nextval "acs_object_id_seq"]
            content::item::new -name $file_title \
                -parent_id $folder_id \
                -item_id $item_id \
                -package_id $package_id \
                -creation_ip 127.0.0.1 \
                -creation_user $creation_user \
                -title $file_title
        }
        
        set revision_id [content::revision::new \
                             -item_id $item_id \
                             -tmp_filename $file_path\
                             -creation_user $creation_user \
                             -creation_ip 127.0.0.1 \
                             -package_id $package_id \
                             -title $file_title \
                             -description "File send by e-mail from $email(from) to $email(to) on subject $email(subject)" \
                             -mime_type $mime_type]
        
        file delete $file_path
        lappend file_ids $revision_id
    }
        
    # Check if we already logged this mail for this object_id
    set message_id $email(message-id)
    if {![db_string logged_p "select 1 from acs_mail_log where object_id = :object_id and message_id = :message_id" -default 0]} {
        	
        set package_id [apm_package_id_from_key "intranet-mail"]
        set log_id [intranet-mail::log_add -package_id $package_id \
                        -sender_id $from_party_id \
                        -from_addr $from_addr \
                        -recipient_ids [lindex $email(to) 0] \
                        -cc_ids [lindex $email(cc) 0] \
                        -bcc_ids [lindex $email(bcc) 0] \
                        -to_addr [lindex $email(to) 1] \
                        -cc_addr [lindex $email(cc) 1] \
                        -bcc_addr [lindex $email(bcc) 1] \
                        -body $body \
                        -message_id $message_id \
                        -subject $email(subject) \
                        -file_ids $file_ids \
                        -context_id $object_id]

        # Execute the callback for logged E-Mails. This is great for
        # custom callbacks triggering workflows etc.
        callback intranet-mail::logged_email -log_id $log_id
    }

    # Move the mail to the correct imap folder
    imap::move_mail -session_id $session_id -destination_mailbox $imap_folder -sequence_nr $sequence_nr

}


# Callback for creating the IMAP folder as well as the Mail file
# folder

ad_proc -public -callback im_project_after_create -impl intranet-mail_create_folders {
    {-object_id:required}
	{-status_id ""}
	{-type_id ""}
} {
    Create the IMAP folder as well as mail folder in intranet-fs for this project.
    
} {
    set project_id $object_id

    # Check if the IMAP folder exists (how ever this is possible)
    set imap_folder [intranet-mail::project_imap_folder -project_id $project_id -check_imap]
    if {$imap_folder eq ""} {
        intranet-mail::project_imap_folder_create -project_id $project_id
    }

    # Check that the folder for intranet-fs exists. Create if not
    set folder_id [intranet_fs::get_project_folder_id -project_id $project_id]
    if {$folder_id eq ""} {
        set folder_id [intranet_fs::create_project_folder -project_id $project_id]
    }
    
    set mail_folder_name [parameter::get_from_package_key -package_key "intranet-mail" -parameter "MailFolderName" -default "mail"]
    
    # Create the mail folder beneath it
    set mail_folder_id [fs::get_folder -name $mail_folder_name -parent_id $folder_id]
    if {$mail_folder_id eq ""} {
        fs::new_folder -name "$mail_folder_name" -pretty_name "$mail_folder_name" -parent_id $folder_id
    }
}


# Callback to move the IMAP Folder around if we change the parent
# project_id

ad_proc -public -callback im_project_after_update -impl intranet-mail_rename_imap {
    {-object_id:required}
	{-status_id ""}
	{-type_id ""}
} {
    Move the imap folder to the new parent project
    
} {
    set project_id $object_id
    set project_nr [db_string parent_id "select project_nr from im_projects where project_id=:project_id" -default ""]

    # Check if the IMAP folder exists (how ever this is possible)
    set imap_folder [intranet-mail::project_imap_folder -project_id $project_id -check_imap]
    if {$imap_folder eq ""} {
        # We need to move the folder.... yikes ....
        # First find out the old folder
        set old_imap_folder [imap::full_mbox_name -mailbox [imap::mailboxes -pattern $project_nr]]

        # Set the new folder
        set new_folder [intranet-mail::project_imap_folder -project_id $project_id]
        set new_imap_folder [imap::full_mbox_name -mailbox $new_folder]
        ns_log Notice "From $old_imap_folder to $new_imap_folder :: $new_folder"
        set session_id [imap::start_session]
        ns_imap m_rename $session_id $old_imap_folder $new_imap_folder
        imap::end_session -session_id $session_id
    } else {
	ns_log Error "ERROR... $imap_folder already exists so we can't move the old folder over. Fix this manually !!!"
    }
}


ad_proc -public -callback acs_mail_lite::send -impl intranet-mail_tracking {
    -package_id:required
    -message_id:required
    -from_addr:required
    -to_addr:required
    -body:required
    {-mime_type "text/plain"}
    {-subject}
    {-cc_addr}
    {-bcc_addr}
    {-file_ids}
    {-object_id}
} {
    create a new entry in the mail tracking table
} {
    # Don't log if we don't have an object_id
    if {$object_id eq ""} {
        return
    }

    set sender_id [party::get_by_email -email $from_addr]

    # Deal with the recipients and find out the ids, so we can
    # correctly map them
    set recipients [concat $to_addr $cc_addr $bcc_addr]
    db_foreach party "select party_id, email from parties where email in ([template::util::tcl_to_sql_list $recipients])" {
        set party($email) $party_id
    }
    
    # First the to_addr
    set to_addr_list [list]
    set recipient_ids [list]
    foreach email $to_addr {
        # If we have a party_id we should link it up and not put it in
        # the to_addr list
        if {[info exists party($email)]} {
            lappend recipient_ids $party($email)
        } else {
            lappend to_addr_list $email
        }
    }
    
    # cc_addr
    set cc_addr_list [list]
    set cc_ids [list]
    foreach email $cc_addr {
        if {[info exists party($email)]} {
            lappend cc_ids $party($email)
        } else {
            lappend cc_addr_list $email
        }
    }

    set bcc_addr_list [list]
    set bcc_ids [list]
    foreach email $bcc_addr {
        # If we have a party_id we should link it up and not put it in
        # the to_addr list
        if {[info exists party($email)]} {
            lappend bcc_ids $party($email)
        } else {
            lappend bcc_addr_list $email
        }
    }
    
    set log_id [intranet-mail::log_add -package_id $package_id \
                    -sender_id $sender_id \
                    -from_addr $from_addr \
                    -recipient_ids $recipient_ids \
                    -cc_ids $cc_ids \
                    -bcc_ids $bcc_ids \
                    -to_addr $to_addr_list \
                    -cc_addr $cc_addr_list \
                    -bcc_addr $bcc_addr_list \
                    -body $body \
                    -subject $subject \
                    -context_id $object_id \
                    -message_id $message_id \
                    -file_ids $file_ids
                   ]
}

ad_proc -public -callback fs::file_delete -impl intranet-mail_tracking {
    {-package_id:required}
    {-file_id:required}
} {
    Create a copy of the file and attach it to the mail-tracking entry, if the file is referenced
} {

    if {[db_string file_attached_p "select 1 from acs_mail_log_attachment_map where file_id = :file_id" -default 0]} {
	set package_id [apm_package_id_from_key intranet-mail]
	set new_file_id [fs::file_copy -file_id $file_id -target_folder_id $package_id]
	db_dml update_file "update acs_mail_log_attachment_map set file_id = :new_file_id where file_id = :file_id"
    }
}
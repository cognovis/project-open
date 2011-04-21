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


ad_proc -public -callback imap::incoming_email -impl intranet-mail-link_mails {
    -session_id:required
    -array:required
} {
    Link mails to the project and users using mail-tracking package

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
    
    if {$object_ids eq ""} {
        # We did not find an object_id in the subject. 
        # Check if the from_addr has a valid SLA
        if {$from_party_id eq ""} {
            # We don't have an object_id and we can't link the mail to
            # a sender, keep it unprocessed.
            set unprocessed_p 1
        } else {
            # Find out the company
            set company_id [db_string get_company_id "select object_id_one from acs_rels ar., registered_users ru where ar.object_id_two = ru.user_id and ru.user_id = :from_party_id" -default ""]
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

    set imap_folder [imap::mailboxes -session_id $session_id -pattern $project_id]
    if {$imap_folder eq ""} {
        # Throw an error
        ns_log error "No IMAP Folder for object $object_id"
        imap::move_mail -session_id $session_id -destination_mailbox $unprocessed_folder -sequence_nr $sequence_nr

        return
    }

    ds_comment "$imap_folder :: $project_id"
    # Find the folder for the project, but only if we deal with files
    if {$email(files) ne ""} {
        set folder_id [intranet_fs::get_project_folder -project_id $project_id -try_parent]
        if {$folder_id eq ""} {
            # No folder found, throw an error and put the message into
            # unprocessed
        }
    }

    set super_project_id $project_id
    set loop 1
    set ctr 0
    while {$loop} {
        set loop 0
        set parent_id [db_string parent_id "select parent_id from im_projects where project_id=:super_project_id" -default ""]
        
        if {"" != $parent_id} {
                set super_project_id $parent_id
                set loop 1
        }
        
        # Check for recursive loop
        if {$ctr > 20} {
                set loop 0
        }
        incr ctr
    }
 
    return $super_project_id

    # Deal with the files
    set files ""
    set file_ids ""
    # As this is a connection less callback, set the IP Address to
    # local
    set peeraddr "127.0.0.1"
    
    # Find out the folder_id.    
    # It is either directly linked to the project or to it's parent.
    
    # We only deal with projects at the moment, in case this get's
    # expanded we definitely need some reworking here as well as
    # intranet-fs

        
            set loop 1
            set super_project_id [db_string parent_id "select parent_id from im_projects where project_id = :super_project_id"]
        }
        if {"" != folder_id
    set 
    set intranet_fs
    


    foreach file $email(files) {
        set mime_type [lindex $file 0]
        set file_title [lindex $file 1]
        set file_path [lindex $file 2]

        # Shall we import the file into the content repository ?
        set sender_id [party::get_by_email -email $from_addr]
        set package_id [acs_object::package_id -object_id $sender_id]
        if {$import_p && $sender_id ne ""} {
            set existing_item_id [content::item::get_id_by_name -name $file_title -parent_id $sender_id]
            if {$existing_item_id ne ""} {
                set item_id $existing_item_id
            } else {
                set item_id [db_nextval "acs_object_id_seq"]
                content::item::new -name $file_title \
                    -parent_id $sender_id \
                    -item_id $item_id \
                                -package_id $package_id \
                    -creation_ip 127.0.0.1 \
                    -creation_user $sender_id \
                    -title $file_title
            }
            
            set revision_id [content::revision::new \
                                 -item_id $item_id \
                                 -tmp_filename $file_path\
                                 -creation_user $sender_id \
                                 -creation_ip 127.0.0.1 \
                                 -package_id $package_id \
                                 -title $file_title \
                                 -description "File send by e-mail from $email(from) to $email(to) on subject $email(subject)" \
                                 -mime_type $mime_type]
            
            file delete $file_path
            lappend file_ids $revision_id
        } else {
            lappend files [list $file_title $mime_type $file_path]
            lappend filenames $file_path
        }
    }

    }


    # Check if we already logged this mail for this object_id
    set message_id $email(message-id)
    if {![db_string logged_p "select 1 from acs_mail_log where object_id = :object_id and message_id = :message_id" -default 0]} {
        
        set package_id [apm_package_id_from_key "intranet-mail"]
        set log_id [mail_tracking::new -package_id $package_id \
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
                        -object_id $object_id]
    }

    if {0} {    



    
    
}
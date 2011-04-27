# packages/intranet-mail/tcl/intranet-mail-procs.tcl

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
    
    Procedures for intranet mail
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-04-21
    @cvs-id $Id$
}

namespace eval intranet-mail {}

ad_proc -public intranet-mail::extract_project_nrs { 
    {-subject:required}
} {
    Extract all project_nrs (2007_xxxx) from the subject of an E-Mail
    
    Returns a list of project_ids (object_ids), if any are found
} {
	set line [string tolower $subject]
	regsub -all {\<} $line " " line
	regsub -all {\>} $line " " line
	regsub -all {\"} $line " " line

	set tokens [split $line " "]
	set project_nrs [list]
    
	foreach token $tokens {
	    # Tokens must be built from aphanum plus "_" or "-".
	    if {![regexp {^[a-z0-9_\-]+$} $token match ]} { continue }
        
	    # Discard tokens purely from alphabetical
	    if {[regexp {^[a-z]+$} $token match ]} { continue }

	    lappend project_nrs $token
	}

    set ids [list]
	set condition "('[join [string tolower $project_nrs] "', '"]')"
    
	set sql "
		select	project_id
		from	im_projects
		where	lower(project_nr) in $condition
	"
    return [db_list emails_to_ids $sql]
    
}

ad_proc -public intranet-mail::extract_object_ids {
    {-subject:required}
} {
    Extract all possible object_ids
    
    An Object_id can either be given by "#object_id" or with a project_nr
} {
    
    set object_ids [intranet-mail::extract_project_nrs -subject $subject]

	set line [string tolower $subject]
	regsub -all {\<} $line " " line
	regsub -all {\>} $line " " line
	regsub -all {\"} $line " " line

	set tokens [split $line " "]
    
    foreach token $tokens {
        # Figure our if this is a valid object_id
        set number [string trimleft $token "#"]
        set number [string trimright $number ":"]

	    if {![regexp {^[0-9]+$} $number match ]} { continue }        
        
        # Check if this is a valid object_id
        if {[db_string object_id_p "select 1 from acs_objects where object_id = :number and object_type in ([template::util::tcl_to_sql_list [intranet-mail::valid_object_types]])" -default 0]} {
            lappend object_ids $number
        }
        
    }
    return $object_ids
}

ad_proc -public intranet-mail::valid_object_types {
} {
    return a list of valid object_types
} {
    return [list im_project im_timesheet_task im_ticket]
}


ad_proc -public intranet-mail::project_imap_folder {
    {-project_id:required}
} {
    returns the IMAP Project folder, relative to IMAPRootFolder
    
    @param project_id ProjectID of the Project
} {

    set super_project_id $project_id 
    set loop 1
    set ctr 0
    set project_imap_root_folder [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPProjectRootFolder"]
    set project_folder "$project_id"
    while {$loop} {
        set loop 0
        set parent_id [db_string parent_id "select parent_id from im_projects where project_id=:super_project_id" -default ""]
        if {$parent_id ne ""} {
            set project_folder "$parent_id.$project_folder"
            set super_project_id $parent_id
            set loop 1
        }
        
        # Check for recursive loop
        if {$ctr > 20} {
                set loop 0
        }
        incr ctr
    }
    set project_folder "${project_imap_root_folder}.$project_folder"
    return $project_folder
}

ad_proc -public intranet-mail::project_imap_folder_create {
    {-project_id:required}
} {
    Creates the IMAP Project folder. Returns 1 if all went well

    @param project_id ProjectID of the Project
} {

    set project_imap_folder [intranet-mail::project_imap_folder -project_id $project_id]

    # Start the IMAP Session
    set session_id [imap::start_session]

    # Don't create if it already exists....
    if {![imap::mailbox_exists_p -mailbox $project_imap_folder -session_id $session_id]} {   
        set project_folder ""
        # Go through the folder components and check if this folder
        # exists. If not, create it
        foreach project_id [split $project_imap_folder "."] {
            
            if {$project_folder eq ""} {
                set project_folder $project_id
            } else {
                set project_folder "${project_folder}.$project_id"
            }
            if {![imap::mailbox_exists_p -mailbox $project_folder -session_id $session_id]} {
                ns_log Notice "Project_folder $project_folder"
                ns_imap m_create $session_id [imap::full_mbox_name -mailbox $project_folder]
            }
        }
        imap::end_session -session_id $session_id
    }
    return 1
}

ad_proc -public im_mail_project_component { 
    -project_id
    {-return_url ""}
} { 
    Return the mail component for a Project (also Task / Ticket)
} {

    if {$return_url eq ""} {
        set return_url [im_biz_object_url $project_id]
    }
    
    set object [ns_queryget object]
    set page [ns_queryget page]
    set messages_orderby [ns_queryget messages_orderby]
    set params [list  [list return_url $return_url] [list project_id $project_id] [list pass_through_vars [list project_id]] [list page $page] [list messages_orderby $messages_orderby]]
    if {$object eq ""} {
        lappend params [list object $project_id] 
    }
    set result [ad_parse_template -params $params "/packages/intranet-mail/lib/messages"]
    return [string trim $result]
    
}


ad_proc -public intranet-mail::package_key {} {
    The package key
} {
    return "intranet-mail"
}

ad_proc -public intranet-mail::log_add {
    {-log_id ""}
    {-package_id:required}
    {-sender_id ""}
    {-from_addr ""}
    {-recipient_ids:required}
    {-cc_ids ""}
    {-bcc_ids ""}
    {-to_addr ""}
    {-cc_addr ""}
    {-bcc_addr ""}
    {-body ""}
    {-message_id:required}
    {-subject ""}
    {-object_id ""}
    {-context_id ""}
    {-file_ids ""}
} {
    Insert new log entry

    @param sender_id party_id of the sender
    @param from_addr e-mail address of the sender. At least party_id or from_addr should be given
    @param recipient_ids List of party_ids of recipients
    @param cc_ids List of party_ids for recipients in the "CC" field
    @param bcc_ids List of party_ids for recipients in the "BCC" field
    @param to_addr List of email addresses seperated by "," who recieved the email in the "to" field but got no party_id
    @param cc_addr List of email addresses seperated by "," who recieved the email in the "cc" field but got no party_id
    @param bcc_addr List of email addresses seperated by "," who recieved the email in the "bcc" field but got no party_id
    @param body Text of the message
    @param message_id Message_id of the email
    @param subject Subject of the email
    @param object_id Object for which this message was sent
    @param context_id Context in which this message was send. Will replace object_id
    @param file_ids Files send with this e-mail
} {
    set creation_ip "127.0.0.1"
    if {![string eq "" $context_id]} {
	set object_id $context_id
    }
    
    set log_id [db_nextval "acs_object_id_seq"]
    # First create the message entry 
    db_dml insert_mail_log {
	insert into acs_mail_log
	(log_id, message_id, sender_id, package_id, subject, body, sent_date, object_id, cc, bcc, to_addr, from_addr)
	values
	(:log_id, :message_id, :sender_id, :package_id, :subject, :body, now(), :object_id, :cc_addr, :bcc_addr, :to_addr, :from_addr)
    }

    ns_log Debug "Mail Traking OBJECT $object_id  CONTEXT $context_id FILES $file_ids LOGS $log_id"
    foreach file_id $file_ids {
	set item_id [content::revision::item_id -revision_id $file_id]
	if {$item_id eq ""} {
	    set item_id $file_id
	}
	db_dml insert_file_map "insert into acs_mail_log_attachment_map (log_id,file_id) values (:log_id,:file_id)"
    }

    # Now add the recipients to the log_id
    
    foreach recipient_id $recipient_ids {
	db_dml insert_recipient {insert into acs_mail_log_recipient_map (recipient_id,log_id,type) values (:recipient_id,:log_id,'to')}
    } 

    foreach recipient_id $cc_ids {
	db_dml insert_recipient {insert into acs_mail_log_recipient_map (recipient_id,log_id,type) values (:recipient_id,:log_id,'cc')}
    } 

    foreach recipient_id $bcc_ids {
	db_dml insert_recipient {insert into acs_mail_log_recipient_map (recipient_id,log_id,type) values (:recipient_id,:log_id,'bcc')}
    } 

    return $log_id
}	       

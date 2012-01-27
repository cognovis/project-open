# packages/intranet-mail/tcl/imap-procs.tcl

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
    
    IMAP Wrapper Procedures
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-04-21
    @cvs-id $Id$
}

#package require nsimap 3.2.3

namespace eval imap {}


ad_proc -public imap::start_session {
} {
    Returns a session_id for the Mailbox on the server

    @param mailbox Name of the mailbox, defaults to INBOX
} {
    # Get the IMAP Information
    set imap_server [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPServer"]
    set imap_user [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPUser"]
    set imap_password [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPPassword"]
    set imap_ssl_p [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPSSLP" -default 1]
    
    # Open a session
    if {$imap_ssl_p} {
        set session [ns_imap open -mailbox "\{$imap_server/ssl\}" -user $imap_user -password $imap_password -expunge]
    } else {
        set session [ns_imap open -mailbox "\{$imap_server\}" -user $imap_user -password $imap_password -expunge]
    }

    return $session
}    

ad_proc -public imap::start_channel {
} {
    Returns a channel to the server using the IMAP4 pure TCL implementation
} {
    set delimiter [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPDelimiter"]
    set root_mailbox [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPRootFolder"]
    if {$mailbox ne ""} {
        set root_mailbox "${root_mailbox}${delimiter}${mailbox}"
    }

    # Get the IMAP Information
    set imap_server [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPServer"]
    set imap_user [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPUser"]
    set imap_password [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPPassword"]
    set imap_ssl_p [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPSSLP" -default 1]
    
    # Open a session
    if {$imap_ssl_p} {
        set session [ns_imap open -mailbox "\{$imap_server/ssl\}$root_mailbox" -user $imap_user -password $imap_password -expunge]
    } else {
        set session [ns_imap open -mailbox "\{$imap_server\}$root_mailbox" -user $imap_user -password $imap_password -expunge]
    }

    return $session
}    

ad_proc -public imap::full_mbox_name {
    {-mailbox}
} {
    Returns the fully qualified mailbox name

    @param mailbox Mailbox relative to the root_mailbox
} {
    set delimiter [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPDelimiter"]
    set root_mailbox [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPRootFolder"]
    if {$mailbox ne ""} {
        set root_mailbox "${root_mailbox}${delimiter}${mailbox}"
    }

    # Get the IMAP Information
    set imap_server [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPServer"]
    set imap_ssl_p [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPSSLP" -default 1]
    
    # Open a session
    if {$imap_ssl_p} {
        return "\{$imap_server/ssl\}$root_mailbox"
    } else {
        return "\{$imap_server\}$root_mailbox"
    }
}

ad_proc -public imap::end_session {
    {-session_id:required}
} {
    End an IMAP session
} {
    ns_imap close $session_id
}

ad_proc -public imap::mailboxes {
    {-session_id ""}
    {-parent_mailbox ""}
    {-pattern ""}
} {
    Return a list of mailboxes available in the current session
    
    @param session_id Session_id if you have already started a session for which you want to get the mailboxes
    @param parent_mailbox Name of parent mailbox for which to display the mailboxes, relative to IMAPRootFolder.
    @param pattern Pattern for which we should search. May contain a wildcard * at the end to search for subfolders or incomplete patterns. May contain % for a single character wildcard
} {
    set delimiter [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPDelimiter"]
    set root_mailbox [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPRootFolder"]
    if {$parent_mailbox ne ""} {
        set root_mailbox "${root_mailbox}${delimiter}$parent_mailbox"
    } 
    set end_p 0
    if {$session_id eq ""} {
        set session_id [imap::start_session]
        
        # End the session if we created it here
        set end_p 1
    }
    set imap_server [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPServer"]    
    if {$pattern eq ""} {
        set mailbox_list [ns_imap list $session_id \{$imap_server\} ${root_mailbox}*]
    } else {
        set mailbox_list [ns_imap list $session_id \{$imap_server\} ${root_mailbox}*${pattern}]
    }    
    set mailboxes [list]

    # ns_imap list returns key value pairs, hence we filter this out.
    foreach mailbox $mailbox_list {
        set mailbox [string trim $mailbox $root_mailbox]
        set mailbox [string trimleft $mailbox "$delimiter"]
        if {$mailbox ne "" && $mailbox ne "noselect"} {
            lappend mailboxes $mailbox
        }
    }

    if {$end_p} {
        imap::end_session -session_id $session_id
    }
    return $mailboxes
}

ad_proc -public imap::mailbox_exists_p {
    {-parent_mailbox ""}
    {-mailbox:required}
    {-session_id ""}
} {
    Check that a Mailbox exists
    
    @param parent_mailbox If a parent mailbox is given, check relative to this parent mailbox, otherwise start from IMAPRootFolder. The parent_mailbox is relative to IMAPRootFolder
    @param mailbox Mailbox to be searched for
} {
    return [util_memoize [list imap::mailbox_exists_p_not_cached -parent_mailbox $parent_mailbox -mailbox $mailbox -session_id $session_id] 60]
}

ad_proc -public imap::mailbox_exists_p_not_cached {
    {-parent_mailbox ""}
    {-mailbox:required}
    {-session_id ""}
} {
    Check that a Mailbox exists
    @see imap::mailbox_exists_p
} {
    set mailboxes [imap::mailboxes -parent_mailbox $parent_mailbox -session_id $session_id]
    ds_comment "Mailboxes:: $mailboxes :: mailbox $mailbox" 
    if {[lsearch $mailboxes $mailbox] <0} {
        return 0
    } else {
        return 1
    }
}


ad_proc -public imap::copy_mail {
    {-session_id:required}
    {-destination_mailbox:required}
    {-sequence_nr:required}
} { 
    Copy the mail defined by the sequence_nr in the current session
    
    @destination_mailbox Mailbox relative to the IMAPRootFolder
} {
    set delimiter [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPDelimiter"]
    #check the destination_mailbox exists
    if {[imap::mailbox_exists_p -session_id $session_id -mailbox $destination_mailbox]} {
        ns_imap copy $session_id $sequence_nr "[parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPRootFolder"]${delimiter}$destination_mailbox"
    } else {
        ns_log Error "Folder $destination_mailbox does not exist"
    }
}

ad_proc -public imap::move_mail {
    {-session_id:required}
    {-destination_mailbox:required}
    {-sequence_nr:required}
} { 
    Move the mail defined by the sequence_nr in the current session
} {
    set delimiter [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPDelimiter"]
    #check the destination_mailbox exists
    if {[imap::mailbox_exists_p -session_id $session_id -mailbox $destination_mailbox]} {
        ns_imap move $session_id $sequence_nr "[parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPRootFolder"]${delimiter}$destination_mailbox"
        ns_imap expunge $session_id
    } else {
        ns_log Error "Folder $destination_mailbox does not exist"
    }
}

ad_proc -public imap::parse_email_addresses {
    {-email_string:required}
} {
    Parses a string of email(s) which may contain the Full Name and be compromised of 
    multiple e-mails separated by ,
    
    @param email_string string which contains one of more email addresses

    @return a tcl list of two list, the first one with a list of found party_ids, the second with the email_addresses not found
} {
    set emails [split $email_string ","]
    
    set email_list [list]
    foreach email $emails {
        lappend email_list [acs_mail_lite::parse_email_address -email $email]
    }
    
    set party_ids [list]
    set party_emails [list]
    # Now go through the cleaned emails and try to get the party_id
    db_foreach parties "select party_id, email from parties where email in ([template::util::tcl_to_sql_list $email_list])" {
        lappend party_ids $party_id
        lappend party_emails $email
    }
    
    # Check if the email in email_list is contained in party_emails
    set remaining_emails [list]
    foreach email $email_list {
        if {[lsearch $party_emails $email]<0} {
            lappend remaining_emails $email
        }
    }

    return [list $party_ids $remaining_emails]
}

ad_proc -public imap::load_mails {
    {-mailbox ""}
} {
    Scans for incoming email. 
    
    @param mailbox Name of the folder to scan, relative to IMAPRootFolder
    
} {
    set session_id [imap::start_session]
    set delimiter [parameter::get_from_package_key -package_key "intranet-mail" -parameter "IMAPDelimiter"]

    # Get all the E-Mails, oldest first (hence the 0)
    
    set message_list [ns_imap sort $session_id date 0]
    foreach sequence_nr $message_list {
        # Parse the HEADER information
        ns_imap headers $session_id $sequence_nr -array email
        
        # Sadly mime puts the header information in lowercase
        # vs. ns_imap which has it all upper case. So we need to
        # transform this.

        foreach key [array names email] {
            set value $email($key)
            set key [string tolower $key]
            set email($key) $value
        }
        set email(sequence_nr) $sequence_nr 

        # Transform the emails variables into lists
        foreach type [list from to cc bcc] {
            if {[info exists email($type)]} {
                set email($type) [imap::parse_email_addresses -email_string $email($type)]
            } else {
                set email($type) ""
            }
        }
            
        set subject $email(subject)

        # Now deal with the bodies
        ns_imap struct $session_id $sequence_nr -array email_struct
        set parts [list]
        
        if {[info exists email_struct(part.count)]} {
            set max_parts $email_struct(part.count)
        } else {
            set max_parts 1
        }
        # Count the structparts
        set counter 1
        set structparts [list]
        while {$counter <= $max_parts} {
            lappend structparts $counter
            incr counter
        }
        
        # First find all the parts            
        set parts [list]
        foreach structpart $structparts {
            
            ns_imap bodystruct $session_id $sequence_nr $structpart -array email_body
            set content_type [string tolower "$email_body(type)/$email_body(subtype)"]
            if {$email_body(type) eq "multipart"} {
                set max_parts $email_body(part.count)
                set counter 1
                while {$counter <= $max_parts} {
                    lappend parts "${structpart}${delimiter}$counter"
                    incr counter
                }
            } else {
                lappend parts $structpart
            }
            
        }
        
        # now we should have all the parts
        #ds_comment "my parts:: $parts"
        #ds_comment "Struct $sequence_nr [ns_imap struct $session_id $sequence_nr]"                                        
        #now extract all parts (bodies/files) and fill the email
        #array
        set bodies [list]
        set files [list]
        
        foreach part $parts {
            #ds_comment "BODYStruct $sequence_nr $part [ns_imap bodystruct $session_id $sequence_nr $part]"                                
            ns_imap bodystruct $session_id $sequence_nr $part -array email_body
            set content_type [string tolower "$email_body(type)/$email_body(subtype)"]                

            switch $content_type {
                "text/plain" {
                    lappend bodies [list "text/plain" [ns_imap body $session_id $sequence_nr $part -decode]]
                }
                "text/html" {
                    lappend bodies [list "text/html" [ns_imap body $session_id $sequence_nr $part -decode]]
                }
                default {
                    # Check if we have a file
                    if {[info exists email_body(disposition.filename)]} {
                        set filename $email_body(disposition.filename)
                    } 
                    if {[info exists email_body(disposition.filename\*)]} {
                        # We seem to have a file with encoding....
                        set file_list [split $email_body(disposition.filename\*) "''"]
                        set filename [ns_urldecode -charset [lindex $file_list 0] [lindex $file_list 2]]
                    }
                    if {[info exists filename]} {
                        # We have a file
                        set file_path [ns_tmpnam]
                        ns_imap body $session_id $sequence_nr $part -file $file_path
                        lappend files [list $content_type $filename $file_path]
                    }
                }
            }
            array unset email_body
        }
        set email(bodies) $bodies
        set email(files) $files
	    if {$email(bodies) eq ""} {
            ad_script_abort
            ns_log Notice "E-Mail without body"
	    }

	    # Do no execute any callbacks if the email is an autoreply.
	    # Thanks to Vinod for the idea and the code
	    set callback_executed_p [acs_mail_lite::autoreply_p -subject $subject -from $email(from)]
        
	    if {!$callback_executed_p} {
            # We execute all callbacks now
            callback imap::incoming_email -array email -session_id $session_id
	    }

        # Clean Up
        array unset email
        array unset email_struct
        foreach file $files {
            file delete [lindex $file 2]
        }
    }
    imap::end_session -session_id $session_id
}


ad_proc -public -callback imap::incoming_email {
    -array:required
    -session_id:required
} {
    Callback that is executed for incoming e-mails if the email is *NOT* like $object_id@servername
} -

ad_proc -public -callback imap::incoming_object_email {
    -array:required
    -object_id:required
} {
    Callback that is executed for incoming e-mails if the email is like $object_id@servername
} - 


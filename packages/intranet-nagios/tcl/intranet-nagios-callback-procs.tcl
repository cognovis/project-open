ad_library {

    Library for Nagios interface callback implementations

    @creation-date March 27, 2008
    @author frank.bergmann@project-open.com
    @cvs-id $Id: intranet-nagios-callback-procs.tcl,v 1.5 2010/04/25 16:41:42 moravia Exp $
}

# ----------------------------------------------------------------------
# Callback for OpenACS 5.1 acs_mail_lite
# ----------------------------------------------------------------------

ad_proc -public im_nagios_acs_mail_lite_callback {
    {-to ""}
    {-from ""}
    {-subject ""}
    {-body ""}
} {
    This procedure is called from the callback acs_mail_lite::load_mails
    every time there is an email with a suitable Nagios header.
} {
    ns_log Notice "im_nagios_acs_mail_lite_callback: from=$from, to=$to, subject=$subject"

    set subject_lower [string tolower $subject]

    if {"" == $to} { return }
    if {"" == $from} { return }
    if {"" == $subject} { return }

    # Parse the subject.
    # Examples:
    # subject="** PROBLEM alert - 85.214.41.40/PING is CRITICAL **"
    # subject="** PROBLEM Service Alert: Athens/NSClient++ Version is CRITICAL  **"
    # subject="** RECOVERY Service Alert: berlin2/Current Load is OK **"
    # subject={** RECOVERY Service Alert: Berlin 2/HTTP PoDesign is OK **}

    # Some "*" + (alert_type) + ":" or "-" + (host)/(service) + is + (status)
    set regexp {[\*]+[\ ]+(.*)[\:\-][\ ]*([^\:\-]+)\/(.+)[\ ]+is[\ ]+([a-z]+)[\ ]+[\*]+}

    if {[regexp $regexp $subject_lower match alert_type host service status]} {
        set alert_type [string trim $alert_type]
        set host [string trim $host]
        set service [string trim $service]
        set status [string trim $status]
    } else {
        set alert_type ""
        set host ""
        set service ""
        set status ""
    }

    if {"" != $alert_type} {
	im_nagios_process_alert \
	    -from $from \
	    -to $to \
	    -alert_type $alert_type \
	    -host $host \
	    -service $service \
	    -status $status \
	    -bodies $body
    }
}


# ----------------------------------------------------------------------

set openacs54_p [im_openacs54_p]
if {$openacs54_p} {


ad_proc -public -callback acs_mail_lite::incoming_email -impl nagios {
    -array:required
    -package_id
} {
    Implementation of the interface acs_mail_lite::incoming_email for Nagios events.
    This procedure is called every time that acs_mail_lite receives a new message.
    
    First, we check if this mail is a Nagios mail and skip otherwise.
    Second, we try to determine the related ConfItem in our database.
    Third, we check if there is already an open ticket for the ConfItem.
    Fourth, we create a new ticket (if there wasn't one before) and append the new message to the ticket.

    @author frank.bergmann@project-open.com
    @creation-date 2008-03-27

    @param array        An array with mail headers, files and bodies.
    @param package_id   Package instance that registered the prefix
    @return             nothing
    @error
} {
    # For some reason necessary to access the contents of the array
    upvar $array email

    set from [notification::email::parse_email_address $email(from)]
    set to [notification::email::parse_email_address $email(to)]
    set subject ""
    if {[info exists email(subject)]} { set subject $email(subject) }
    set subject_lower [string tolower $subject]
    set bodies ""
    if {[info exists email(bodies)]} { set bodies $email(bodies) }

    if {"" == $to} { return }
    if {"" == $from} { return }
    if {"" == $subject} { return }

    # Parse the subject. 
    # Examples:
    # subject="** PROBLEM alert - 85.214.41.40/PING is CRITICAL **"
    # subject="** PROBLEM Service Alert: Athens/NSClient++ Version is CRITICAL  **"
    # subject="** RECOVERY Service Alert: berlin2/Current Load is OK **"
    # subject={** RECOVERY Service Alert: Berlin 2/HTTP PoDesign is OK **}

    # Some "*" + (alert_type) + ":" or "-" + (host)/(service) + is + (status)
    set regexp {[\*]+[\ ]+(.*)[\:\-][\ ]*([^\:\-]+)\/(.+)[\ ]+is[\ ]+([a-z]+)[\ ]+[\*]+}

    if {[regexp $regexp $subject_lower match alert_type host service status]} {
	set alert_type [string trim $alert_type]
	set host [string trim $host]
	set service [string trim $service]
	set status [string trim $status]
    } else {
	set alert_type ""
	set host ""
	set service ""
	set status ""
    }
    
    ns_log Notice "acs_mail_lite::incoming_email -impl nagios:\nfrom=$from\nto=$to\nalert_type=$alert_type\nhost=$host\nservice=$service\nstatus=$status\nsubject=$subject\nregexp=$regexp\n"

    if {"" != $alert_type} {
	im_nagios_process_alert \
	    -from $from \
	    -to $to \
	    -alert_type $alert_type \
	    -host $host \
	    -service $service \
	    -status $status \
	    -bodies $bodies
    }
}

}
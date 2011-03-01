# /packages/intranet-nagios/tcl/intranet-nagios-procs.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_nagios_conf_item_type_linux_server {} { return 23001 }
ad_proc -public im_nagios_conf_item_type_generic_router {} { return 23003 }
ad_proc -public im_nagios_conf_item_type_http_service {} { return 23005 }


# ----------------------------------------------------------------------
# Process Nagios alert emails
# ----------------------------------------------------------------------

ad_proc -public im_nagios_process_alert {
    -from:required
    -to:required
    -alert_type:required
    -host:required
    -service:required
    -status:required
    -bodies:required
} {
    This procedure is called from the callback acs_mail_lite::incoming_email
    every time there is an email with a suitable Nagios header.

    - Determine the related ConfItem in our database.
    - Check if there is already an open ticket for the ConfItem.
    - Create a new ticket if there wasn't one before
    - Append the new message to the ticket.
} {
    ns_log Notice "im_nagios_process_alert: from=$from, to=$to, host=$host, service=$service"

    # Check or create the server ("host") Conf ITem of the ticket
    set host_conf_item_id [im_nagios_get_host_by_name -host_name $host]
    ns_log Notice "im_nagios_process_alert: Found host_id='$host_conf_item_id' for host '$host'";

    # Check of create the Nagios service for the ticket, below the host.
    set service_conf_item_id [im_nagios_get_service_by_name -host_name $host -service_name $service]
    ns_log Notice "im_nagios_process_alert: Found service_id='$service_conf_item_id' for host_id='$host' and service='$service'"

    # Check if there is already an open ticket for the same service:
    set open_nagios_ticket_id [im_nagios_find_open_ticket -host_name $host -service_name $service]
    ns_log Notice "im_nagios_process_alert: Found open ticket_id='$open_nagios_ticket_id' for host_id=$host_conf_item_id, service_id=$service_conf_item_id, host=$host, service=$service"

    # Create a suitable name for the ticket.
    set ticket_name "Nagios $alert_type $host/$service is $status"
    
    # Create a new ticket object if there isn't an open ticket already
    if {"" == $open_nagios_ticket_id} {

	# Transaction: Avoid partial object creation if something fails.
	ns_log Notice "im_nagios_process_alert: Creating a new ticket"
	db_transaction {

	    # Take a new ticket_id from the global object sequence
	    set ticket_id [db_nextval "acs_object_id_seq"]
	    
	    # Take a new ticket_nr from sequence.
	    set ticket_nr [db_nextval im_ticket_seq]
	    
	    # Assign the "internal customer" (check the docu) as the customer
	    set ticket_customer_id [im_company_internal]
	    
	    # Don't set any specific contact person for the ticket.
	    set ticket_customer_contact_id 0
	    
	    # Ticket type and status: Nagios Alert/Open
	    set ticket_type_id [im_ticket_type_nagios_alert]
	    set ticket_status_id [im_ticket_status_open]
	    
	    # Set start and end date to today (required for the im_project super-type)
	    # in database-friendly format:
	    set start_date [db_string now "select now()::date from dual"]
	    set end_date [db_string now "select (now()::date) from dual"]
	    set start_date_sql [template::util::date get_property sql_date $start_date]
	    set end_date_sql [template::util::date get_property sql_timestamp $end_date]
	    
	    # Create a new ticket and update the im_tickets and im_projects tables.
	    # The SQL for these commands is found in intranet-nagios-procs-postgresql.xql
	    set open_nagios_ticket_id [db_string ticket_insert {}]
	    db_dml ticket_update {}
	    db_dml project_update {}
	    
	    # Write audit trail to track changes in the ticket.
	    im_project_audit -project_id $ticket_id
	    
	} on_error {
	    ns_log Error "im_nagios_process_alert: Error creating ticket: $errmsg"
	}
    }
    # At this point open_nagios_ticket_id contains a valid ticket_id, either with
    # a new or an existing ticket.

    # Add the body of the Nagios alert to the "forum" of the open ticket.
    # Retreive ALL forum topics related to the ticket and...
    set forum_ids [db_list forum_ids "
	select	ft.topic_id
	from	im_forum_topics ft
	where	ft.object_id = :open_nagios_ticket_id
	order by 
		ft.topic_id
    "]

    # ...get the first forum topic. Use the first ticket as the parent for this one.
    set parent_id [lindex $forum_ids 0]
    ns_log Notice "im_nagios_process_alert: Found parent topic_id='$parent_id'"

    # Create a new forum topic of type "Note"
    set topic_id [db_nextval im_forum_topics_seq]
    set topic_type_id [im_topic_type_id_task]
    set topic_status_id [im_topic_status_id_open]
    set owner_id 0
    set subject $ticket_name

    # The "bodies" variable contains a hash consisting of (Mime-Type - Content) pairs:
    set message ""
    foreach {mime_type body} $bodies { 
	append message $body 
    }

    # Create a new forum topics. Forum topics are not ]po[ objects so an insert is OK.
    db_dml topic_insert {
		insert into im_forum_topics (
			topic_id, object_id, parent_id,
			topic_type_id, topic_status_id, owner_id, 
			subject, message
		) values (
			:topic_id, :open_nagios_ticket_id, :parent_id,
			:topic_type_id,	:topic_status_id, :owner_id, 
			:subject, :message
		)
    }

    # Take action on open_nagios_ticket_id, depending on the nagios status:
    ns_log Notice "im_nagios_process_alert: Processing Nagios alert status='$status'"
    switch [string tolower $status] {
	ok {
	    ns_log Notice "im_nagios_process_alert: Set the ticket to 'resolved'"
	    db_dml update_closed "
		update	im_tickets set 
			ticket_status_id = [im_ticket_status_closed]
		where ticket_id = :open_nagios_ticket_id
	    "
	}
	critical { 
	    ns_log Notice "im_nagios_process_alert: Nothing to do - ticket status='$status'"
	    # nothing - keep the ticket open
	}
	default - unknown {
	    ns_log Notice "im_nagios_process_alert: Unkown ticket status='$status'"
	    # nothing - keep the ticket open
	}
    }
   

}

# ----------------------------------------------------------------------
# Parse a single Nagios configuration file
# and return the definitions
# ----------------------------------------------------------------------


ad_proc -public im_nagios_parse_config_file {
    -lines:required
} {
    The Nagios parser. Accepts a list of (cleaned up) lines
    from a Nagios configuration file and returns a list of service 
    definitions in a format suitable for "array set":
    {
	1 {{type host} {use template} {host_name router123} {pretty_name {Disk Service 123}} ...}
	2 {{type host} {use template} {host_name router234} {pretty_name {Disk Service 345}} ...}
	...
    }
    The numeration is arbitrary and kept just for convenience reasons.
} {
    array unset services_hash
    array set services_hash [list]
    set service_cnt 1
    set cur_service 0

    # Go through all lines of the file and sort the lines into a "service_list".
    foreach line $lines {
	
	# ---------------------------------------------------------
	# Preprocess the lines and filter out comments

	# Remove ";" comments
	if {[regexp {^(.*)\;} $line match payload]} { set line $payload }

	# Remove leading and trailing spaces
	set line [string trim $line]

	# Discard empty lines
	if {"" == $line} { continue }
	
	# Discard comment lines
	if {[regexp {^\#} $line]} { continue }
	
	# Put spaces around "{" and "}"
	regsub -all {\{} $line " \{ " line
	regsub -all {\}} $line " \} " line
	
	# Replace multiple white spaces by a single space
	regsub -all {[ \t]+} $line " " line

	# Cleanup too many white spaces
	set line [string trim $line]

	# ---------------------------------------------------------
	# Start a new service definitioin everytime we find a line
	# that starts with "define".
	if {[regexp {^define ([a-zA-Z0-9_]+)} $line match service]} {

	    # Start a new service definition
	    incr service_cnt
	    set cur_service $service_cnt

	    # Set the "type" of the new service.
	    set service_def [list [list type $service]]

	    set services_hash($service_cnt) $service_def
	    continue
	}

	# ---------------------------------------------------------
	# We've found the end of a definition. 
	if {[regexp {^\}} $line match]} {

	    # Reset the cur_service to 0 for non-valid lines
	    set cur_service 0
	    continue
	}
  
	# ---------------------------------------------------------
	# Parse one of the definition lines. Treat the line as a list...
	set key [lindex $line 0]
	set values [lrange $line 1 end]

	set service_def $services_hash($cur_service)
	lappend service_def [list $key $values]
	set services_hash($cur_service) $service_def

    }

    return [array get services_hash]
}



# ----------------------------------------------------------------------
# Read a Nagios configuration (multiple files)
# and convert them into a "hosts" hash.
# ----------------------------------------------------------------------


ad_proc -public im_nagios_read_config {
    -main_config_file:required
    { -debug 0 }
} {
    Read multiple configuration files and return a "hosts" hash structure.
    Write out debug lines to the HTTP session via ns_write.
} {

    # ------------------------------------------------------------
    # Read the main config file
    #
    
    set encoding "utf-8"
    
    if {[catch {
	set fl [open $main_config_file]
	fconfigure $fl -encoding $encoding
	set content [read $fl]
	close $fl
    } err]} {
	ns_write "<li>Unable to open file $main_config_file:<br><pre>\n$err</pre>"
	ns_write [im_footer]
	return {}
    }
    
    set config_files [list]
    foreach line [split $content "\n"] {
	set line [string trim $line]
	if {"" == $line} { continue}
	if {[regexp {^\#} $line]} { continue}
	if {[regexp {cfg_file=(.*)} $line match config_file]} { lappend config_files $config_file }
    }


    # ------------------------------------------------------------
    # Read and parse the object files
    #
    
    set lines [list]
    foreach config_file $config_files {
	
	if {$debug} { ns_write "<h3>Parsing file: $config_file</h3>\n" }
	if {[catch {
	    set fl [open $config_file]
	    fconfigure $fl -encoding $encoding
	    set content [read $fl]
	    close $fl
	} err]} {
	    ns_write "<li>Unable to open file $config_file:<br><pre>\n$err</pre>"
	    ns_write [im_footer]
	    return {}
	}

	set lines [split $content "\n"]
	set defs [im_nagios_parse_config_file -lines $lines]
	
	array unset file_defs
	array set file_defs $defs
	foreach def_id [array names file_defs] {
	    
	    # Read the definition into a hash in order to make processing easier.
	    # "defs" come in the form: {{type host} {use template} {host_name router123} {pretty_name {Disk Service 123}} ...}
	    set defs $file_defs($def_id)
	    array unset def_hash
	    foreach def $defs {
		set key [lindex $def 0]
		set value [lindex $def 1]
		set def_hash($key) $value
	    }
	    
	    # Get the type of definition and extract values
	    if {![info exists def_hash(type)]} { continue }
	    set def_type $def_hash(type)
	    switch $def_type {
		command - timeperiod - contact - contactgroup - hostgroup {
		    # No action required.
		}
		host {
		    # define host {use linux-server host_name storage02 alias {Storage 02} address 172.26.2.7}
		    if {[catch {
			
			# Pull out the hostname. 
			set name "unknown"
			if {[info exists def_hash(name)]} { set host_name $def_hash(name) }
			if {[info exists def_hash(host_name)]} { set host_name $def_hash(host_name) }
			
			# Store the host definition in hosts hash
			set hosts_def [list]
			if {[info exists hosts($host_name)]} { set hosts_def $hosts($host_name) }
			lappend hosts_def "host"
			lappend hosts_def [array get def_hash]
			set hosts($host_name) $hosts_def
			
			# Write out log line
			if {$debug} { ns_write "<li>Found host=$host_name\n" }
			
		    } err_msg]} {
			ns_write "<p class=error>
			Error parsing '$def_type' definition in file '$config_file':
			<pre>$err_msg</pre><br>[array get def_hash]</p>\n
		    "
		    }
		}
		service {
		    # define service {use generic-service host_name storage02 service_description {Current Load} ...}
		    if {[catch {
			
			# Pull out the service name
			set host_name "unknown"
			if {[info exists def_hash(host_name)]} { set host_name $def_hash(host_name) }
			set service_description "unknown"
			if {[info exists def_hash(service_description)]} { set service_description $def_hash(service_description) }
			
			# Store the service definition in hosts hash
			set hosts_def [list]
			if {[info exists hosts($host_name)]} { set hosts_def $hosts($host_name) }
			lappend hosts_def $service_description
			lappend hosts_def [array get def_hash]
			set hosts($host_name) $hosts_def
			
			# Write out log line
			if {$debug} { ns_write "<li>Found service=$name\n" }
			
		    } err_msg]} {
			ns_write "<p class=error>
			Error parsing '$def_type' definition in file '$config_file':
			<pre>$err_msg</pre><br>[array get def_hash]</p>\n
		    "
		    }
		}
		default {
		    if {$debug} { ns_write "<p class=error>Unknown definition '$def_type'</p>\n" }
		}
	    }
	}
	
    }
    return [array get hosts]
}




# ----------------------------------------------------------------------
# Display a Nagios configuration
# ----------------------------------------------------------------------

ad_proc -public im_nagios_display_config {
    -hosts_hash:required
} {
    Creates a UL-LI list structure from a nagios config.
    hosts_hash -> List of Host entries
    Host Entries -> List of Host Services
    Host Services -> {host_info service1 service2 ...}
    host_info -> List of host key-value pairs
    serviceX -> List of service key-value pairs
} {
    array unset hosts
    array set hosts $hosts_hash
    set html ""
    foreach host_name [array names hosts] {
	
	# Get the list of all services defined for host.
	# The special "host" service contains the host definition
	array unset host_services_hash
	array set host_services_hash $hosts($host_name)

	# An "unknown" host may not hava a "host" info section...
	if {![info exists host_services_hash(host)]} { continue }

	# Get the definition of the host
	set host_def $host_services_hash(host)
	array unset host_def_hash
	array set host_def_hash $host_def
	
	append html "<ul class=mktree>\n"
	append html "<li>Host: $host_name"
	append html "<ul>\n"
	
	# Show Host information
	append html "<li>Host Info\n"
	append html "<ul>\n"
	foreach host_def_key [array names host_def_hash] {
	    append html  "<li>$host_def_key: $host_def_hash($host_def_key)\n"
	}
	append html "</ul>\n"
	
	# Show services
	foreach service_name [array names host_services_hash] {
	    if {"unknown" == $service_name} { continue }
	    if {"host" == $service_name} { continue }
	    append html "<li>Service: $service_name\n"

	    array unset services_def_hash
	    array set services_def_hash $host_services_hash($service_name)
	    append html "<ul>\n"
	    foreach service_def_key [array names services_def_hash] {
		append html  "<li>$service_def_key: $services_def_hash($service_def_key)\n"
	    }
	    append html "</ul>\n"

	}
	
	# Finish up the host definition
	append html "</ul>\n"
	
	# Finish the list of all hosts
	append html "</ul>\n"
	
    }
    return $html
}



# ----------------------------------------------------------------------
# Determine a suitable type of the item, depending on the host info
# ----------------------------------------------------------------------

ad_proc -public im_nagios_get_type_id_from_host_info {
    -host_info_hash:required
} {
    Tries to determine a suitable "Intranet Conf Item Type" for the
    given Nagios host.
} {
    array unset host_info
    array set host_info $host_info_hash

    # The Nagios "use" statement refers to a type of template
    # that we can use to classify the conf item.
    set host_template "unknown"
    if {[info exists host_info(use)]} { set host_template $host_info(use) }

    if {"unknown" == $host_template} { return [im_conf_item_type_server] }
    if {"" == $host_template} { return [im_conf_item_type_server] }
    
    # Check for a category with the same name
    set type_ids [db_list conf_item_type_from_nagios_template "
		select	category_id
		from	im_categories
		where	category_type = 'Intranet Conf Item Type' and
			lower(category) = lower(:host_template)
    "]

    if {[llength $type_ids] > 0} { return [lindex $type_ids 0] }
 
    # Check for a matching aux_string1 in categories
    set type_ids [db_list conf_item_type_from_nagios_template_aux1 "
		select	category_id
		from	im_categories
		where	category_type = 'Intranet Conf Item Type' and
			lower(aux_string1) = lower(:host_template)
    "]
    if {[llength $type_ids] > 0} { return [lindex $type_ids 0] }

    # Default type for confitem - hardware.
    return [im_conf_item_type_hardware]
}



# ----------------------------------------------------------------------
# Find a toplevel host
# ----------------------------------------------------------------------

ad_proc -public im_nagios_get_host_by_name {
    -host_name:required
} {
    Returns the conf_id of the host with the given name
} {
    set host_ids [db_list hosts "
	select	conf_item_id
	from	im_conf_items
	where	conf_item_parent_id is null and
		conf_item_nr = :host_name
    "]

    # There may be more then one host_id, so just return the first.
    return [lindex $host_ids 0]
}


ad_proc -public im_nagios_get_service_by_name {
    -host_name:required
    -service_name:required
} {
    Returns the conf_id of the service with the given name
} {
    set host_id [im_nagios_get_host_by_name -host_name $host_name]

    set service_ids [db_list hosts "
	select	conf_item_id
	from	im_conf_items
	where	conf_item_parent_id = :host_id and
		conf_item_nr = :service_name
	order by conf_item_id
    "]

    # There may be more then one service_id, so just return the first.
    return [lindex $service_ids 0]
}

ad_proc -public im_nagios_find_open_ticket {
    -host_name:required
    -service_name:required
} {
    Checks whether there is a ticket open for the given host+service
    and returns 0 otherwise.
} {
    set host_id [im_nagios_get_host_by_name -host_name $host_name]
    if {"" == $host_id} {
	# Create a new host based on name only...
	array unset host_vars
	set host_vars(conf_item_name) $host_name
	set host_vars(conf_item_type_id) [im_conf_item_type_hardware]
	set host_id [im_conf_item::new -var_hash [array get host_vars]]
    }

    set service_id [im_nagios_get_service_by_name -host_name $host_name -service_name $service_name]
    if {"" == $service_id} {
	# Create a new service based on name only...
	array unset service_vars
	set service_vars(conf_item_name) $service_name
	set service_vars(conf_item_parent_id) $host_id
	set host_vars(conf_item_type_id) [im_conf_item_type_service]
	set service_id [im_conf_item::new -var_hash [array get service_vars]]
    }

    set ticket_ids [db_list tickets "
	select	ticket_id
	from	im_tickets t
	where	t.ticket_conf_item_id = :service_id
		and t.ticket_status_id in ([join [im_sub_categories [im_ticket_status_open]] ","])
    "]

    return [lindex $ticket_ids 0]
}



# ----------------------------------------------------------------------
# Write Nagios configuration into the configuration database
# ----------------------------------------------------------------------

ad_proc -public im_nagios_create_confdb {
    -hosts_hash:required
    { -debug 1 }
} {
    Creates configuration items from a Nagios configuration
} {
    array unset hosts
    array set hosts $hosts_hash

    set peeraddr "0.0.0.0"
    set current_user_id 0

    foreach host_name [array names hosts] {
	
	# ignore "unknown"
	if {"unknown" == $host_name} { continue }

	# Get the list of all services defined for host.
	# The special "host" service contains the host definition
	array unset host_services_hash
	array set host_services_hash $hosts($host_name)

	# Get the definition of the host
	set host_info $host_services_hash(host)
	array unset host_info_hash
	array set host_info_hash $host_info

	# Check "register=0" for generic type declarations
	# that are not real hardware
	set host_register 1
	if {[info exists host_info_hash(register)]} { set host_register $host_info_hash(register) }
	if {0 == $host_register} { continue }

	set conf_item_new_sql "
		select im_conf_item__new(
			null,
			'im_conf_item',
			now(),
			:current_user_id,
			:peeraddr,
			null,
			:conf_item_name,
			:conf_item_nr,
			:conf_item_parent_id,
			:conf_item_type_id,
			:conf_item_status_id
		)
	"

	set conf_item_name $host_name
	set conf_item_nr $host_name
	set conf_item_code $host_name
	set conf_item_parent_id ""
	set conf_item_status_id [im_conf_item_status_active]
	set conf_item_type_id [im_nagios_get_type_id_from_host_info -host_info_hash $host_info]
	set conf_item_version ""
	set conf_item_owner_id $current_user_id
	set description ""
	set note ""

        set conf_item_id [db_string exists "select conf_item_id from im_conf_items where conf_item_nr = :conf_item_nr" -default 0]
        if {!$conf_item_id} { set conf_item_id [db_string new $conf_item_new_sql] }
        db_dml update [im_conf_item_update_sql -include_dynfields_p 1]       

	# Store the host for the services section below.
	set host_conf_item_id $conf_item_id


	# Update IP-Address
	set ip_address ""
	if {[info exists host_info_hash(address)]} { set ip_address $host_info_hash(address) }
	db_dml ip_address "update im_conf_items set ip_address = :ip_address where conf_item_id = :conf_item_id"

	# Deal with services
	foreach service_name [array names host_services_hash] {

	    if {"host" == $service_name} { continue }
	    if {"unknown" == $service_name} { continue }
	    set service_list $host_services_hash($service_name)
	    array unset service_hash
	    array set service_hash $service_list

	    set service_description ""
	    set check_command ""
	    if {[info exists service_hash(service_description)]} { set service_description $service_hash(service_description) }
	    if {[info exists service_hash(check_command)]} { set check_command $service_hash(check_command) }

	    # Try to determine a suitable ]po[ service type.
	    # Example:
	    #	service_description {HTTP PcDemo} check_command {check_http!-p 30028} use local-service
	    set service_type ""
	    if {[regexp {check_http} $check_command match]} { set service_type "http" }

	    switch $service_type {
		http_xxxx {
			set conf_item_new_sql "
				select im_conf_item__new(
					null,
					'im_conf_item',
					now(),
					:current_user_id,
				        :peeraddr,
					null,
					:conf_item_name,
					:conf_item_nr,
					:conf_item_parent_id,
					:conf_item_type_id,
					:conf_item_status_id
				)
			"
		
			set conf_item_name "$host_name - $service_name"
			set conf_item_nr $conf_item_name
			set conf_item_code $conf_item_name
			set conf_item_parent_id $host_conf_item_id
			set conf_item_status_id [im_conf_item_status_active]
			set conf_item_type_id [im_nagios_conf_item_type_http_service]
			set conf_item_version ""
			set conf_item_owner_id $current_user_id
			set description $service_name
			set note ""
		
		        set conf_item_id [db_string exists "
				select	conf_item_id
				from	im_conf_items
				where	conf_item_parent_id = :host_conf_item_id and
					conf_item_nr = :conf_item_nr
			" -default 0]
		        if {!$conf_item_id} { set conf_item_id [db_string new $conf_item_new_sql] }
		        db_dml update [im_conf_item_update_sql -include_dynfields_p 1]       
		
			
		}
		default {
#		    ad_return_complaint 1 "$service_type - service_name=$service_name - check_command=$check_command"
		}
	    }

	    
	}
    }
}


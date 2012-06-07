# /packages/intranet-helpdesk/tcl/intranet-helpdesk-procs.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_ticket_status_open {} { return 30000 }
ad_proc -public im_ticket_status_closed {} { return 30001 }

ad_proc -public im_ticket_status_internal_review {} { return 30010 }
ad_proc -public im_ticket_status_assigned {} { return 30011 }
ad_proc -public im_ticket_status_customer_review {} { return 30012 }
ad_proc -public im_ticket_status_waiting_for_other {} { return 30026 }
ad_proc -public im_ticket_status_frozen {} { return 30028 }
ad_proc -public im_ticket_status_duplicate {} { return 30090 }
ad_proc -public im_ticket_status_invalid {} { return 30091 }
ad_proc -public im_ticket_status_outdated {} { return 30092 }
ad_proc -public im_ticket_status_rejected {} { return 30093 }
ad_proc -public im_ticket_status_wontfix {} { return 30094 }
ad_proc -public im_ticket_status_cantreproduce {} { return 30095 }
ad_proc -public im_ticket_status_resolved {} { return 30096 }
ad_proc -public im_ticket_status_deleted {} { return 30097 }
ad_proc -public im_ticket_status_canceled {} { return 30098 }
ad_proc -public im_ticket_type_purchase_request {} { return 30102 }
ad_proc -public im_ticket_type_workplace_move_request {} { return 30104 }
ad_proc -public im_ticket_type_telephony_request {} { return 30106 }
ad_proc -public im_ticket_type_project_request {} { return 30108 }
ad_proc -public im_ticket_type_bug_request {} { return 30110 }
ad_proc -public im_ticket_type_report_request {} { return 30112 }
ad_proc -public im_ticket_type_permission_request {} { return 30114 }
ad_proc -public im_ticket_type_feature_request {} { return 30116 }
ad_proc -public im_ticket_type_training_request {} { return 30118 }
ad_proc -public im_ticket_type_sla_request {} { return 30120 }
ad_proc -public im_ticket_type_nagios_alert {} { return 30122 }

ad_proc -public im_ticket_type_generic_problem_ticket {} { return 30130 }


ad_proc -public im_ticket_type_incident_ticket {} { return 30150 }
ad_proc -public im_ticket_type_problem_ticket {} { return 30152 }
ad_proc -public im_ticket_type_change_ticket {} { return 30154 }

ad_proc -public im_ticket_type_idea {} { return 30180 }

ad_proc -public im_ticket_action_close {} { return 30500 }
ad_proc -public im_ticket_action_close_notify {} { return 30510 }
ad_proc -public im_ticket_action_duplicated {} { return 30520 }
ad_proc -public im_ticket_action_close_delete {} { return 30590 }


# ----------------------------------------------------------------------
# PackageID
# ----------------------------------------------------------------------

ad_proc -public im_package_helpdesk_id {} {
    Returns the package id of the intranet-helpdesk module
} {
    return [util_memoize "im_package_helpdesk_id_helper"]
}

ad_proc -private im_package_helpdesk_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-helpdesk'
    } -default 0]
}


# ----------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------

ad_proc -public im_ticket_permissions {
    user_id 
    ticket_id 
    view_var 
    read_var 
    write_var 
    admin_var
} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $ticket_id
} {
    ns_log Notice "im_ticket_permissions: user_id=$user_id, ticket_id=$ticket_id"
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 0
    set read 0
    set write 0
    set admin 0

    set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set edit_ticket_status_p [im_permission $user_id edit_ticket_status]
    set add_tickets_for_customers_p [im_permission $user_id add_tickets_for_customers]
    set add_tickets_p [im_permission $user_id "add_tickets"]
    set view_tickets_all_p [im_permission $user_id "view_tickets_all"]

    # Determine the list of all groups in which the current user is a member
    set user_parties [im_profile::profiles_for_user -user_id $user_id]
    lappend user_parties $user_id

    if {![db_0or1row ticket_info "
	select	coalesce(t.ticket_assignee_id, 0) as ticket_assignee_id,
		coalesce(t.ticket_customer_contact_id,0) as ticket_customer_contact_id,
		coalesce(o.creation_user,0) as creation_user_id,
		(select count(*) from (
			-- member of an explicitely assigned ticket_queue
			select	distinct g.group_id
			from	acs_rels r, groups g 
			where	r.object_id_one = g.group_id and
				r.object_id_two = :user_id and
				g.group_id = t.ticket_queue_id
		) t) as queue_member_p,
		(select count(*) from (
			-- member of the ticket - any role_id will do.
			select	distinct r.object_id_one
			from	acs_rels r,
				im_biz_object_members bom
			where	r.rel_id = bom.rel_id and
				r.object_id_two in ([join $user_parties ","])
		) t) as ticket_member_p,
		(select count(*) from (
			-- admin of the ticket
			select	distinct r.object_id_one
			from	acs_rels r,
				im_biz_object_members bom
			where	r.rel_id = bom.rel_id and
				r.object_id_two in ([join $user_parties ","]) and
				bom.object_role_id in (1301, 1302)
		) t) as ticket_admin_p,
		(select count(*) from (
			-- cases with user as task_assignee
			select distinct wfc.object_id
			from	wf_task_assignments wfta,
				wf_tasks wft,
				wf_cases wfc
			where	t.ticket_id = wfc.object_id and
				wft.state in ('enabled', 'started') and
				wft.case_id = wfc.case_id and
				wfta.task_id = wft.task_id and
				wfta.party_id in (
					select	group_id
					from	group_distinct_member_map
					where	member_id = :user_id
				    UNION
					select	:user_id
				)
		) t) as case_assignee_p,
		(select count(*) from (
			-- cases with user as task holding_user
			select	distinct wfc.object_id
			from	wf_tasks wft,
				wf_cases wfc
			where	t.ticket_id = wfc.object_id and
				wft.holding_user = :user_id and
				wft.state in ('enabled', 'started') and
				wft.case_id = wfc.case_id
		) t) as holding_user_p
	from	im_tickets t,
		im_projects p,
		acs_objects o
	where	t.ticket_id = :ticket_id and
		t.ticket_id = p.project_id and
		t.ticket_id = o.object_id
    "]} {
	# Didn't find ticket - just return with permissions set to 0...
	return 0
    }

    set owner_p [expr $user_id == $creation_user_id]
    set assignee_p [expr $user_id == $ticket_assignee_id]
    set customer_p [expr $user_id == $ticket_customer_contact_id]

    set read [expr $admin_p || $owner_p || $assignee_p || $customer_p || $ticket_member_p || $holding_user_p || $case_assignee_p || $queue_member_p || $view_tickets_all_p || $add_tickets_for_customers_p || $edit_ticket_status_p]
    set write [expr ($read && $edit_ticket_status_p) || $ticket_admin_p]

    set view $read
    set admin $write

}




ad_proc -public im_ticket_permission_read_sql {
    { -user_id "" }
} {
    Returns a SQL statement that returns the list of ticket_ids
    that are readable for the user
} {
    if {"" == $user_id} { set user_id [ad_get_user_id] }
    ns_log Notice "im_ticket_permissions_read_sql: user_id=$user_id"

    # The SQL for admins and users who can read everything
    set read_all_sql "select ticket_id from im_tickets"

    # Admins can do everything
    set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    if {$admin_p} { return $read_all_sql }

    # Users with permissions to read any tickets
    set view_tickets_all_p [im_permission $user_id "view_tickets_all"]
    if {$view_tickets_all_p} { return $read_all_sql }

    # Determine the list of all groups in which the current user is a member
    set user_parties [im_profile::profiles_for_user -user_id $user_id]
    lappend user_parties $user_id

    set read_sql "
	select	t.ticket_id
	from	im_tickets t,
		im_projects p,
		acs_objects o
	where	t.ticket_id = p.project_id and
		t.ticket_id = o.object_id and
		(t.ticket_assignee_id = :user_id OR
		t.ticket_customer_contact_id = :user_id OR
		o.creation_user = :user_id OR
		exists(
			-- member of an explicitely assigned ticket_queue
			select	g.group_id
			from	acs_rels r, 
				groups g 
			where	r.object_id_one = g.group_id and
				r.object_id_two = :user_id and
				g.group_id = t.ticket_queue_id			
		) OR exists (
			-- member of the ticket - any role_id will do.
			select	r.object_id_one
			from	acs_rels r,
				im_biz_object_members bom
			where	r.rel_id = bom.rel_id and
				r.object_id_two in ([join $user_parties ","])
		) OR exists (
			-- admin of the ticket
			select	distinct r.object_id_one
			from	acs_rels r,
				im_biz_object_members bom
			where	r.rel_id = bom.rel_id and
				r.object_id_two in ([join $user_parties ","]) and
				bom.object_role_id in (1301, 1302)
		) OR exists (
			-- cases with user as task_assignee
			select	wfc.object_id
			from	wf_task_assignments wfta,
				wf_tasks wft,
				wf_cases wfc
			where	t.ticket_id = wfc.object_id and
				wft.state in ('enabled', 'started') and
				wft.case_id = wfc.case_id and
				wfta.task_id = wft.task_id and
				wfta.party_id in (
					select	group_id
					from	group_distinct_member_map
					where	member_id = :user_id
				    UNION
					select	:user_id
				)
		) OR exists (
			-- cases with user as task holding_user
			select	wfc.object_id
			from	wf_tasks wft,
				wf_cases wfc
			where	t.ticket_id = wfc.object_id and
				wft.holding_user = :user_id and
				wft.state in ('enabled', 'started') and
				wft.case_id = wfc.case_id
		))
    "
    return $read_sql
}




# ----------------------------------------------------------------------
# Navigation Bar
# ---------------------------------------------------------------------

ad_proc -public im_ticket_navbar { 
    {-navbar_menu_label "tickets"}
    default_letter 
    base_url 
    next_page_url 
    prev_page_url 
    export_var_list 
    {select_label ""} 
} {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/projects/.
    The lower part of the navbar also includes an Alpha bar.

    @param default_letter none marks a special behavious, hiding the alpha-bar.
    @navbar_menu_label Determines the "parent menu" for the menu tabs for 
		       search shortcuts, defaults to "projects".
} {
    # -------- Defaults -----------------------------
    set user_id [ad_get_user_id]
    set url_stub [ns_urldecode [im_url_with_query]]

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    # -------- Calculate Alpha Bar with Pass-Through params -------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	}
    }
    set alpha_bar [im_alpha_bar -prev_page_url $prev_page_url -next_page_url $next_page_url $base_url $default_letter $bind_vars]

    # Get the Subnavbar
    set parent_menu_sql "select menu_id from im_menus where label = '$navbar_menu_label'"
    set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default 0]]
    
    ns_set put $bind_vars letter $default_letter
    ns_set delkey $bind_vars project_status_id

    set navbar [im_sub_navbar $parent_menu_id $bind_vars $alpha_bar "tabnotsel" $select_label]

    return $navbar
}











# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_ticket_project_component {
    -object_id
} {
    Returns a HTML component to show all project tickets related to a project
} {
    set params [list \
		    [list base_url "/intranet-helpdesk/"] \
		    [list object_id $object_id] \
		    [list return_url [im_url_with_query]] \
		    ]

    set result [ad_parse_template -params $params "/packages/intranet-helpdesk/www/tickets-list-component"]
    return [string trim $result]
}


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

namespace eval im_ticket {

    ad_proc -public next_ticket_nr {
    } {
        Create a new ticket_nr. Calculates the max() of current
	ticket_nrs and add +1, or just use a sequence for the next value.

        @author frank.bergmann@project-open.com
	@return next ticket_nr
    } {
	set next_ticket_nr_method [parameter::get_from_package_key -package_key "intranet-helpdesk" -parameter "NextTicketNrMethod" -default "sequence"]

	switch $next_ticket_nr_method {
	    sequence {
		# Make sure everybody _really_ gets a different NR!
		return [db_nextval im_ticket_seq]
	    }
	    default {
		# Try to avoid any "holes" in the list of ticket NRs
		set last_ticket_nr [db_string last_pnr "
		select	max(project_nr::integer)
		from	im_projects
		where	project_type_id = [im_project_type_ticket]
			and project_nr ~ '^\[0-9\]+$'
	        " -default 0]

		# Make sure the counter is not behind the current value
		while {[db_string lv "select im_ticket_seq.last_value"] < $last_ticket_nr} {
		    set ttt [db_string update "select nextval('im_ticket_seq')"]
		}
		return [expr $last_ticket_nr + 1]
		
	    }
	}
    }


    ad_proc -public new_from_hash {
        { -var_hash "" }
    } {
        Create a new ticket. There are only few required field.
	Primary key is ticket_nr which defaults to ticket_name.

        @author frank.bergmann@project-open.com
	@return The object_id of the new (or existing) ticket
    } {
	array set vars $var_hash
	set ticket_new_sql "
		SELECT im_ticket__new (
			:ticket_id,		-- p_ticket_id
			'im_ticket',		-- object_type
			now(),			-- creation_date
			0,			-- creation_user
			'0.0.0.0',		-- creation_ip
			null,			-- context_id	
			:ticket_name,
			:ticket_customer_id,
			:ticket_type_id,
			:ticket_status_id
		)
	"

	# Set defaults.
	set ticket_name $vars(ticket_name)
	set ticket_nr $ticket_name
	set ticket_parent_id ""
	set ticket_status_id [im_ticket_status_active]
	set ticket_type_id [im_ticket_type_hardware]
	set ticket_version ""
	set ticket_owner_id [ad_get_user_id]
	set description ""
	set note ""

	# Override defaults
	if {[info exists vars(ticket_nr)]} { set ticket_nr $vars(ticket_nr) }
	if {[info exists vars(ticket_code)]} { set ticket_code $vars(ticket_nr) }
	if {[info exists vars(ticket_parent_id)]} { set ticket_parent_id $vars(ticket_parent_id) }
	if {[info exists vars(ticket_status_id)]} { set ticket_status_id $vars(ticket_status_id) }
	if {[info exists vars(ticket_type_id)]} { set ticket_type_id $vars(ticket_type_id) }
	if {[info exists vars(ticket_version)]} { set ticket_version $vars(ticket_version) }
	if {[info exists vars(ticket_owner_id)]} { set ticket_owner_id $vars(ticket_owner_id) }
	if {[info exists vars(description)]} { set description $vars(description) }
	if {[info exists vars(note)]} { set note $vars(note) }

	# Check if the item already exists
        set ticket_id [db_string exists "
		select	ticket_id
		from	im_tickets
		where	ticket_parent_id = :ticket_parent_id and
			ticket_nr = :ticket_nr
	" -default 0]

	# Create a new item if necessary
        if {!$ticket_id} { set ticket_id [db_string new $ticket_new_sql] }

	# Update the item with additional variables from the vars array
	set sql_list [list]
	foreach var [array names vars] {
	    if {$var == "ticket_id"} { continue }
	    lappend sql_list "$var = :$var"
	}
	set sql "
		update im_tickets set
		[join $sql_list ",\n"]
		where ticket_id = :ticket_id
	"
        db_dml update_ticket $sql

	# Write Audit Trail
	im_project_audit -project_id $ticket_id -action after_create

	return $ticket_id
    }


    ad_proc -public new {
        -ticket_sla_id:required
        { -ticket_name "" }
        { -ticket_nr "" }
	{ -ticket_customer_contact_id "" }
	{ -ticket_type_id "" }
	{ -ticket_status_id "" }
	{ -ticket_start_date "" }
	{ -ticket_end_date "" }
	{ -ticket_note "" }
	{ -creation_date "" }
	{ -creation_user "" }
	{ -creation_ip "" }
	{ -context_id "" }
    } {
	Create a new ticket.
	This procedure deals with the base ticket creation.
	DynField values need to be stored extract.

	@author frank.bergmann@project-open.com
	@return <code>ticket_id</code> of the newly created project or "" in case of an error.
    } {
	set ticket_id ""
	set current_user_id $creation_user
	if {"" == $current_user_id} { set current_user_id [ad_get_user_id] }

	db_transaction {

	    # Set default input values
	    if {"" == $ticket_nr} { set ticket_nr [db_nextval im_ticket_seq] }
	    if {"" == $ticket_name} { set ticket_name $ticket_nr }    
	    if {"" == $ticket_start_date} { set ticket_start_date [db_string now "select now()::date from dual"] }
	    if {"" == $ticket_end_date} { set ticket_end_date [db_string now "select (now()::date)+1 from dual"] }
	    set start_date_sql [template::util::date get_property sql_date $ticket_start_date]
	    set end_date_sql [template::util::date get_property sql_timestamp $ticket_end_date]
	
	    # Create a new forum topic of type "Note"
	    set topic_id [db_nextval im_forum_topics_seq]

	    # Get customer from SLA
	    set ticket_customer_id [db_string cid "select company_id from im_projects where project_id = :ticket_sla_id" -default ""]
	    if {"" == $ticket_customer_id} { ad_return_complaint 1 "<b>Unable to create ticket:</b><br>No customer was specified for ticket" }

	    set ticket_name_exists_p [db_string pex "select count(*) from im_projects where project_name = :ticket_name"]
	    if {$ticket_name_exists_p} { ad_return_complaint 1 "<b>Unable to create ticket:</b><br>Ticket Name '$ticket_name' already exists." }

	    set ticket_nr_exists_p [db_string pnex "select count(*) from im_projects where project_nr = :ticket_nr"]
	    if {$ticket_nr_exists_p} { ad_return_complaint 1 "<b>Unable to create ticket:</b><br>Ticket Nr '$ticket_nr' already exists." }

	    set ticket_id [db_string exists "select min(project_id) from im_projects where project_type_id = [im_project_type_ticket] and lower(project_nr) = lower(:ticket_nr)" -default ""]
	    if {"" == $ticket_id} {
		set ticket_id [db_string ticket_insert {}]
	    }
	    db_dml ticket_update {}
	    db_dml project_update {}


	    # Deal with OpenACS 5.4 "title" static title columm which is wrong:
	    if {[im_column_exists acs_objects title]} {
		db_dml object_update "update acs_objects set title = null where object_id = :ticket_id"
	    }

	    # Add the current user to the project
	    im_biz_object_add_role $current_user_id $ticket_id [im_biz_object_role_project_manager]
	
	    # Start a new workflow case
	    im_workflow_start_wf -object_id $ticket_id -object_type_id $ticket_type_id -skip_first_transition_p 1

	
	    # Write Audit Trail
	    im_project_audit -project_id $ticket_id -action after_create

	    # Create a new forum topic of type "Note"
	    set topic_type_id [im_topic_type_id_discussion]
	    set topic_status_id [im_topic_status_id_open]
	    set message ""


	    # Frank: The owner of a topic can edit its content.
	    #        But we don't want customers to edit their stuff here...

	    set topic_owner_id $current_user_id

	    # Klaus: If a customer creates a ticket, he would need to be the owner of the 
            #        of the forum item created since other rules cause confusion and mess up 
            #        notifications when thread will be extended.    
	    #        There should be no problem if a customer changes the ticket that had been 
            #        created automatically based on the input he did when creating the ticket. 

	    # if {[im_user_is_customer_p $current_user_id]} { 
	    #	set topic_owner_id [db_string admin "select min(user_id) from users where user_id > 0" -default 0]
	    # }

	    if {"" == $ticket_note} { set ticket_note [lang::message::lookup "" intranet-helpdesk.Empty_Forum_Message "No message specified"]}

	    db_dml topic_insert {
                insert into im_forum_topics (
                        topic_id, object_id, parent_id,
                        topic_type_id, topic_status_id, owner_id,
                        subject, message
                ) values (
                        :topic_id, :ticket_id, null,
                        :topic_type_id, :topic_status_id, :topic_owner_id,
                        :ticket_name, :ticket_note
                )
	    }

	    # Subscribe owner to Notifications	    
	    im_ticket::notification_subscribe -ticket_id $ticket_id -user_id $current_user_id

	} on_error {
	    ad_return_complaint 1 "<b>Error inserting new ticket</b>:<br>&nbsp;<br>
	    <pre>$errmsg</pre>"
	}

	return $ticket_id 
    }



    ad_proc -public internal_sla_id { } {
	Determines the "internal" SLA: This SLA is used for handling
	meta-tickets, such as a request to create an SLA for a user.
	This SLA might also be used as a default if no other SLAs
	are available.

        @author frank.bergmann@project-open.com
	@return sla_id related to "internal company"
    } {
	# This company represents the "owner" of this ]po[ instance
	set internal_company_id [im_company_internal]

	set sla_id [db_string internal_sla "
		select	project_id
		from	im_projects
		where	company_id = :internal_company_id and
			project_type_id = [im_project_type_sla] and
			project_nr = 'internal_sla'
        " -default ""]

	if {"" == $sla_id} {
	    ad_return_complaint 1 "<b>Didn't find the 'Internal SLA'</b>:<br>
		We didn't find the 'internal' Service Level Agreement (SLA)
		in the system. <br>
		This SLA is used for service requests from
		users such as creating a new SLA.<br>
		Please Contact your System Administrator to setup this SLA.
		It needs to fulfill <br>
		the following conditions:<p>&nbsp;</p>
		<ul>
		<li>Customer: the 'Internal Company'<br>
		    (the company with the path 'internal' that represents
		    the organization running this system)</li>
		<li>Project Type: 'Service Level Agreement'</li>
		<li>Project Nr: 'internal_sla' (in lower case)
		</ul>
	    "
	}
	return $sla_id
    }


    ad_proc -public notification_subscribe {
        -ticket_id:required
	{ -user_id "" }
    } {
	Subscribe a user to notifications on a specific	ticket.
        @author frank.bergmann@project-open.com
    } {
	if {"" == $user_id} { set user_id [ad_get_user_id] }
	set type_id [notification::type::get_type_id -short_name "ticket_notif"]
	set interval_id [notification::get_interval_id -name "instant"]
	set delivery_method_id [notification::get_delivery_method_id -name "email"]

	notification::request::new \
	    -type_id $type_id \
	    -user_id $user_id \
	    -object_id $ticket_id \
	    -interval_id $interval_id \
	    -delivery_method_id $delivery_method_id
    }

    ad_proc -public notification_unsubscribe {
        -ticket_id:required
	{ -user_id "" }
    } {
	Unsubscribe a user to notifications on a specific ticket.
        @author frank.bergmann@project-open.com
    } {
	if {"" == $user_id} { set user_id [ad_get_user_id] }

	# Get list of requests. We don't want to use a db_foreach
	# because we don't know how many database connections the unsubscribe
	# action needs...
	set request_ids [db_list requests "
		select	request_id
		from	notification_requests
		where	object_id = :ticket_id and
			user_id = :user_id
	"]

	foreach request_id $request_ids {
	    # Security Check
	    notification::security::require_admin_request -request_id $request_id

	    # Actually Delete
	    notification::request::delete -request_id $request_id
	}
    }

    ad_proc -public add_reply {
        -ticket_id:required
	-subject:required
	{-message "" }
    } {
	Add a comment to the ticket as forum topic of type "reply".
    } {
	# Create a new forum topic of type "Reply"
	set current_user_id [ad_get_user_id]
	set topic_id [db_nextval im_forum_topics_seq]
	set parent_topic_id [db_string topic_id "select min(topic_id) from im_forum_topics where object_id = :ticket_id" -default ""]
	set topic_type_id [im_topic_type_id_reply]
	set topic_status_id [im_topic_status_id_open]

	# The owner of a topic can edit its content.
	# But we don't want customers to edit their stuff here...
	set topic_owner_id $current_user_id
	if {[im_user_is_customer_p $current_user_id]} { 
	    set topic_owner_id [db_string admin "select min(user_id) from users where user_id > 0" -default 0]
	}

	db_dml topic_insert "
	    insert into im_forum_topics (
                        topic_id, object_id, parent_id,
                        topic_type_id, topic_status_id, owner_id,
                        subject, message
                ) values (
                        :topic_id, :ticket_id, :parent_topic_id,
                        :topic_type_id, :topic_status_id, :current_user_id,
                        :subject, :message
                )
        "

	# Write Audit Trail
	im_project_audit -project_id $ticket_id -action after_create
    }

    ad_proc -public check_permissions {
	{-check_only_p 0}
	-ticket_id:required
        -operation:required
    } {
	Check if the user can perform view, read, write or admin the ticket
    } {
	set user_id [ad_get_user_id]
	set user_name [im_name_from_user_id $user_id]
	im_ticket_permissions $user_id $ticket_id view read write admin
	if {[lsearch {view read write admin} $operation] < 0} { 
	    ad_return_complaint 1 "Invalid operation '$operation':<br>Expected view, read, write or admin"
	    ad_script_abort
	}
	set perm [set $operation]

	# Just return the result check_only_p is set
	if {$check_only_p} { return $perm }

	if {!$perm} { 
	    set action_forbidden_msg [lang::message::lookup "" intranet-helpdesk.Forbidden_operation on ticket "
	    <b>Unable to perform operation '%operation%'</b>:<br>You don't have the necessary permissions for ticket #%ticket_id%."]
	    ad_return_complaint 1 $action_forbidden_msg 
	    ad_script_abort
	}
	return $perm
    }

    ad_proc -public set_status_id {
	-ticket_id:required
        -ticket_status_id:required
    } {
        Set the ticket to the specified status.
	The procedure deals with some special cases
    } {
	set user_id [ad_get_user_id]
	set user_name [im_name_from_user_id $user_id]
	im_ticket_permissions $user_id $ticket_id view read write admin
	if {!$write} { 
	    set action_forbidden_msg [lang::message::lookup "" intranet-helpdesk.Forbidden_to_change_ticket_status_msg "
	    <b>Unable to change the status of the ticket</b>:<br>You don't have the permissions to modify ticket #%ticket_id%."]
	    ad_return_complaint 1 $action_forbidden_msg 
	    ad_script_abort
	}
	db_dml update_ticket_status "
		update im_tickets set 
			ticket_status_id = :ticket_status_id
		where ticket_id = :ticket_id
	"

	# Add a message to the forum
	set ticket_status [im_category_from_id $ticket_status_id]
	im_ticket::add_reply -ticket_id $ticket_id -subject \
	    [lang::message::lookup "" intranet-helpdesk.Set_to_status_by_user "Set to status '%ticket_status%' by %user_name%"]


	# Set the status of the underlying project depending on the ticket status
	set project_status_id ""
	if {[im_category_is_a $ticket_status_id [im_ticket_status_open]]} { set project_status_id [im_project_status_open] }
	if {[im_category_is_a $ticket_status_id [im_ticket_status_closed]]} { set project_status_id [im_project_status_closed] }
	if {"" != $project_status_id} {
	    db_dml update_ticket_project_status "
		update im_projects set 
			project_status_id = [im_project_status_closed]
		where project_id = :ticket_id
	    "
	} else {
	    ad_return_complaint 1 "Internal Error: Found invalid ticket_status_id=$ticket_status_id"
	    ad_script_abort
	}

	im_audit -object_id $ticket_id

    }


    ad_proc -public close_workflow {
	-ticket_id:required
    } {
        Stop the ticket workflow.
    } {
	# Cancel associated workflow
	im_workflow_cancel_workflow -object_id $ticket_id
    }

    ad_proc -public audit {
	-ticket_id:required
	-action:required
    } {
        Write the audit trail
    } {
	# Write Audit Trail
	im_project_audit -project_id $ticket_id -action $action
    }

    ad_proc -public close_forum {
	-ticket_id:required
    } {
        Set the ticket forum to "deleted"
    } {
	# Mark the topic as closed
	db_dml mark_as_closed "
			update im_forum_topics
        	        set topic_status_id = [im_topic_status_id_closed]
			where	parent_id is null and
				object_id = :ticket_id
	"

	# Close associated forum by moving to "deleted" folder
	db_dml move_to_deleted "
			update im_forum_topic_user_map
        	        set folder_id = 1
                	where topic_id in (
				select	t.topic_id
				from	im_forum_topics t
				where	t.parent_id is null and
					t.object_id = :ticket_id
			)
	"
    }

    ad_proc -public update_timestamp {
	-timestamp:required
	-ticket_id:required
    } {
        Set the specified timestamp(s) to now()
    } {
	foreach ts $timestamp {
	    switch $ts {
		done		{ set column "ticket_done_date" }
		default 	{ set column "" }
	    }
	    if {"" != $column} {
	        db_dml update_ticket_timestamp "
			update im_tickets set 
				ticket_done_date = now()
			where ticket_id = :ticket_id
	        "
	    }
	}
    }

}



# ----------------------------------------------------------------------
# Ticket - Project Relationship
# ---------------------------------------------------------------------

ad_proc -public im_helpdesk_new_ticket_ticket_rel {
    -ticket_id_from_search:required
    -ticket_id:required
    {-sort_order 0}
} {
    Marks ticket_id as a duplicate of ticket_id_from_search
} {
    if {"" == $ticket_id_from_search} { ad_return_complaint 1 "Internal Error - ticket_id_from_search is NULL" }
    if {"" == $ticket_id} { ad_return_complaint 1 "Internal Error - ticket_id is NULL" }

    set rel_id [db_string rel_exists "
	select	rel_id
	from	acs_rels
	where	object_id_one = :ticket_id_from_search
		and object_id_two = :ticket_id
    " -default 0]
    if {0 != $rel_id} { return $rel_id }

    return [db_string new_ticket_ticket_rel "
		select im_ticket_ticket_rel__new (
			null,			-- rel_id
			'im_ticket_ticket_rel',	-- rel_type
			:ticket_id,		-- object_id_one
			:ticket_id_from_search,	-- object_id_two
			null,			-- context_id
			[ad_get_user_id],	-- creation_user
			'[ns_conn peeraddr]',	-- creation_ip
			:sort_order		-- sort_order
		)
    "]
}


# ----------------------------------------------------------------------
# Selects & Options
# ---------------------------------------------------------------------

ad_proc -public im_ticket_options {
    {-include_empty_p 1}
    {-include_empty_name "" }
    {-maxlen_name 50 }
} {
    Returns a list of Tickets suitable for ad_form
} {
    set user_id [ad_get_user_id]

    set ticket_sql "
	select	child.*,
		t.*
	from	im_projects child,
		im_projects parent,
		im_tickets t
	where	parent.parent_id is null and
		child.project_id = t.ticket_id and
		child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
	order by
		child.project_nr,
		child.project_name
    "

    set options [list]
    db_foreach tickets $ticket_sql {
	lappend options [list "$project_nr - [string range $project_name 0 $maxlen_name]" $ticket_id]
    }

    if {$include_empty_p} { set options [linsert $options 0 "$include_empty_name {}"] }

    return $options
}



ad_proc -public im_helpdesk_ticket_queue_options {
    {-mine_p 0}
    {-include_empty_p 1}
} {
    Returns a list of Ticket Queue tuples suitable for ad_form
} {
    set user_id [ad_get_user_id]

    set sql "
	select
		g.group_name,
		g.group_id
	from
		groups g,
		im_ticket_queue_ext q
	where
		g.group_id = q.group_id
	order by
		g.group_name
    "

    set options [list]
    db_foreach groups $sql {
	regsub -all " " $group_name "_" group_key
	set name [lang::message::lookup "" intranet-helpdesk.group_key $group_name]
	lappend options [list $name $group_id]
    }

    set options [db_list_of_lists company_options $sql]
    if {$include_empty_p} { set options [linsert $options 0 { "" "" }] }

    return $options
}


ad_proc -public im_helpdesk_ticket_sla_options {
    {-user_id 0 }
    {-mine_p 0}
    {-customer_id 0}
    {-include_empty_p 1}
    {-include_create_sla_p 0}
} {
    Returns a list of SLA tuples suitable for ad_form
} {
    if {0 == $user_id} { set user_id [ad_get_user_id] }

    # Can the user see all projects?
    set permission_sql ""
    if {![im_permission $user_id "view_projects_all"]} {
	set include_create_sla_p 0
	set permission_sql "and p.project_id in (
		select object_id_one from acs_rels where object_id_two = :user_id UNION 
		select project_id from im_projects where company_id = :customer_id UNION
		select project_id from im_projects where company_id in (
			select	object_id_one
			from	acs_rels
			where	object_id_two = :user_id
		)
	)"
    }

    set sql "
	select
		c.company_name || ' (' || p.project_name || ')' as sla_name,
		p.project_id
	from
		im_projects p,
		im_companies c
	where
		p.company_id = c.company_id and
		p.project_type_id = [im_project_type_sla]
		$permission_sql
	order by
		sla_name
    "

    set options [list]
    db_foreach slas $sql {
	lappend options [list $sla_name $project_id]
    }

    if {$include_create_sla_p} { set options [linsert $options 0 [list [lang::message::lookup "" intranet-helpdesk.New_SLA "New SLA"] "new"]] }
    if {$include_empty_p} { set options [linsert $options 0 { "" "" }] }

    return $options
}




# ----------------------------------------------------------------------
# Portlets
# ---------------------------------------------------------------------

ad_proc -public im_helpdesk_home_component {
    {-show_empty_ticket_list_p 1}
    {-view_name "ticket_personal_list" }
    {-order_by_clause ""}
    {-ticket_type_id 0}
    {-ticket_status_id 0}
} {
    Returns a HTML table with the list of tickets of the
    current user. Don't do any fancy sorting and pagination, 
    because a single user won't be a member of many active tickets.

    @param show_empty_ticket_list_p Should we show an empty ticket list?
           Setting this parameter to 0 the component will just disappear
           if there are no tickets.
} {
    set current_user_id [ad_get_user_id]

    if {"" == $order_by_clause} {
	set order_by_clause  [parameter::get_from_package_key -package_key "intranet-helpdesk" -parameter "HomeTicketListSortClause" -default "p.project_nr DESC"]
    }
    set org_order_by_clause $order_by_clause


    # ---------------------------------------------------------------
    # Columns to show:

    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
    set column_headers [list]
    set column_vars [list]
    set extra_selects [list]
    set extra_froms [list]
    set extra_wheres [list]

    set column_sql "
	select	*
	from	im_view_columns
	where	view_id = :view_id and group_id is null
	order by sort_order
    "

    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
	if {"" != $extra_select} { lappend extra_selects $extra_select }
	if {"" != $extra_from} { lappend extra_froms $extra_from }
	if {"" != $extra_where} { lappend extra_wheres $extra_where }
    }

    # ---------------------------------------------------------------
    # Generate SQL Query

    set extra_select [join $extra_selects ",\n\t"]
    set extra_from [join $extra_froms ",\n\t"]
    set extra_where [join $extra_wheres "and\n\t"]
    if { ![empty_string_p $extra_select] } { set extra_select ",\n\t$extra_select" }
    if { ![empty_string_p $extra_from] } { set extra_from ",\n\t$extra_from" }
    if { ![empty_string_p $extra_where] } { set extra_where "and\n\t$extra_where" }

    if {0 == $ticket_status_id} { set ticket_status_id [im_ticket_status_open] }


    set ticket_status_restriction ""
    if {0 != $ticket_status_id} { set ticket_status_restriction "and t.ticket_status_id in ([join [im_sub_categories $ticket_status_id] ","])" }

    set ticket_type_restriction ""
    if {0 != $ticket_type_id} { set ticket_type_restriction "and t.ticket_type_id in ([join [im_sub_categories $ticket_type_id] ","])" }

    set perm_sql "
	(select
		p.*
	from
	        im_tickets t,
		im_projects p
	where
		t.ticket_id = p.project_id
		and (
			t.ticket_assignee_id = :current_user_id 
			OR t.ticket_customer_contact_id = :current_user_id
			OR t.ticket_queue_id in (
				select distinct
					g.group_id
				from	acs_rels r, groups g 
				where	r.object_id_one = g.group_id and
					r.object_id_two = :current_user_id
			)
			OR p.project_id in (	
				-- cases with user as task holding_user
				select distinct wfc.object_id
				from	wf_tasks wft,
					wf_cases wfc
				where	wft.state in ('enabled', 'started') and
					wft.case_id = wfc.case_id and
					wft.holding_user = :current_user_id
			) OR p.project_id in (
				-- cases with user as task_assignee
				select distinct wfc.object_id
				from	wf_task_assignments wfta,
					wf_tasks wft,
					wf_cases wfc
				where	wft.state in ('enabled', 'started') and
					wft.case_id = wfc.case_id and
					wfta.task_id = wft.task_id and
					wfta.party_id in (
						select	group_id
						from	group_distinct_member_map
						where	member_id = :current_user_id
					    UNION
						select	:current_user_id
					)
			)
		)
		and t.ticket_status_id not in ([im_ticket_status_deleted], [im_ticket_status_closed])
		$ticket_status_restriction
		$ticket_type_restriction
	)"

    set personal_ticket_query "
	SELECT
		p.*,
		t.*,
		to_char(p.end_date, 'YYYY-MM-DD HH24:MI') as end_date_formatted,
	        c.company_name,
	        im_category_from_id(t.ticket_type_id) as ticket_type,
	        im_category_from_id(t.ticket_status_id) as ticket_status,
	        im_category_from_id(t.ticket_prio_id) as ticket_prio,
	        to_char(end_date, 'HH24:MI') as end_date_time
                $extra_select
	FROM
		$perm_sql p,
		im_tickets t,
		im_companies c
                $extra_from
	WHERE
		p.project_id = t.ticket_id and
		p.company_id = c.company_id
		$ticket_status_restriction
		$ticket_type_restriction
                $extra_where
	order by $org_order_by_clause
    "

    
    # ---------------------------------------------------------------
    # Format the List Table Header

    # Set up colspan to be the number of headers + 1 for the # column
    set colspan [expr [llength $column_headers] + 1]

    set table_header_html "<tr>\n"
    foreach col $column_headers {
	regsub -all " " $col "_" col_txt
	set col_txt [lang::message::lookup "" intranet-core.$col_txt $col]
	append table_header_html "  <td class=\"rowtitle\">$col_txt</td>\n"
    }
    append table_header_html "</tr>\n"

    # ---------------------------------------------------------------
    # Format the Result Data

    set url "index?"
    set table_body_html ""
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set ctr 0
    db_foreach personal_ticket_query $personal_ticket_query {

	set url [im_maybe_prepend_http $url]
	if { [empty_string_p $url] } {
	    set url_string "&nbsp;"
	} else {
	    set url_string "<a href=\"$url\">$url</a>"
	}
	
	# Append together a line of data based on the "column_vars" parameter list
	set row_html "<tr$bgcolor([expr $ctr % 2])>\n"
	foreach column_var $column_vars {
	    append row_html "\t<td class=\"list\">"
	    set cmd "append row_html $column_var"
	    eval "$cmd"
	    append row_html "</td>\n"
	}
	append row_html "</tr>\n"
	append table_body_html $row_html
	
	incr ctr
    }

    # Show a reasonable message when there are no result rows:
    if { [empty_string_p $table_body_html] } {

	# Let the component disappear if there are no tickets...
	if {!$show_empty_ticket_list_p} { return "" }

	set table_body_html "
	    <tr><td colspan=\"$colspan\"><ul><li><b> 
	    [lang::message::lookup "" intranet-core.lt_There_are_currently_n "There are currently no entries matching the selected criteria"]
	    </b></ul></td></tr>
	"
    }
    return "
	<table class=\"table_component\" width=\"100%\">
	<thead>$table_header_html</thead>
	<tbody>$table_body_html</tbody>
	</table>
    "
}



# ----------------------------------------------------------------------
# Navigation Bar Tree
# ---------------------------------------------------------------------

ad_proc -public im_navbar_tree_helpdesk { 
    -user_id:required
    { -locale "" }
} {
    Creates an <ul> ...</ul> collapsable menu for the
    system's main NavBar.
} {
    set current_user_id [ad_get_user_id]
    set wiki [im_navbar_doc_wiki]

    set html "
	<li><a href=/intranet-helpdesk/index>[lang::message::lookup "" intranet-helpdesk.Service_Mgmt "IT Service Management"]</a>
	<ul>
	<li><a href=$wiki/module_itsm>[lang::message::lookup "" intranet-core.ITSM_Help "ITSM Help"]</a>
    "

    # --------------------------------------------------------------
    # Tickets
    # --------------------------------------------------------------

    # Create new Ticket
    if {[im_permission $current_user_id "add_tickets"]} {
	append html "<li><a href=\"/intranet-helpdesk/new\">[lang::message::lookup "" intranet-helpdesk.New_Ticket "New Ticket"]</a>\n"
    }

    if {[im_permission $current_user_id "view_tickets_all"]} {
	# Add sub-menu with types of tickets
	append html "
		<li><a href=/intranet-helpdesk/index>[lang::message::lookup "" intranet-helpdesk.Ticket_Types "Ticket Types"]</a>
		<ul>
        "
	set ticket_type_sql "select * from im_ticket_types order by ticket_type"
	db_foreach ticket_types $ticket_type_sql {
	    set url [export_vars -base "/intranet-helpdesk/index" {ticket_type_id}]
	    regsub -all " " $ticket_type "_" ticket_type_subst
	    set name [lang::message::lookup "" intranet-helpdesk.Ticket_type_$ticket_type_subst "${ticket_type}s"]
	    append html "<li><a href=\"$url\">$name</a></li>\n"
	}
	append html "
		</ul>
		</li>
        "
    }

    append html "
	[if {![catch {set ttt [im_navbar_tree_confdb]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_release_mgmt]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_bug_tracker]}]} {set ttt} else {set ttt ""}]
	[im_navbar_tree_helpdesk_ticket_type -base_ticket_type_id [im_ticket_type_incident_ticket] -base_ticket_type [lang::message::lookup "" intranet-helpdesk.Incident_ticket_type "Incident"]]
	[im_navbar_tree_helpdesk_ticket_type -base_ticket_type_id [im_ticket_type_problem_ticket] -base_ticket_type [lang::message::lookup "" intranet-helpdesk.Problem_ticket_type "Problem"]]
	[im_navbar_tree_helpdesk_ticket_type -base_ticket_type_id [im_ticket_type_change_ticket] -base_ticket_type [lang::message::lookup "" intranet-helpdesk.Change_ticket_type "Change"]]
    "



    # --------------------------------------------------------------
    # SLAs
    # --------------------------------------------------------------

    set sla_url [export_vars -base "/intranet/projects/index" {{project_type_id [im_project_type_sla]}}]
    append html "
	<li><a href=$sla_url>[lang::message::lookup "" intranet-helpdesk.SLA_Management "SLA Management"]</a>
	<ul>
    "

    # Add list of SLAs
    if {[im_permission $current_user_id "add_projects"]} {
	set url [export_vars -base "/intranet/projects/new" {{project_type_id [im_project_type_sla]}}]
	set name [lang::message::lookup "" intranet-helpdesk.New_SLA "New SLA"]
	append html "<li><a href=\"$url\">$name</a></li>\n"
    }

    if {$current_user_id > 0} {
	set url [export_vars -base "/intranet/projects/index" {{project_type_id [im_project_type_sla]}}]
	set name [lang::message::lookup "" intranet-helpdesk.SLA_List "SLAs"]
	append html "<li><a href=\"$url\">$name</a></li>\n"
    }

    append html "
	</ul>
	</li>
    "

    # --------------------------------------------------------------
    # End of ITSM
    # --------------------------------------------------------------

    append html "
	</ul>
	</li>
    "
    return $html
}


ad_proc -public im_navbar_tree_helpdesk_ticket_type { 
    -base_ticket_type_id:required
    -base_ticket_type:required
} { 
    Show one of {Issue|Incident|Problem|Change} Management
} {
    set current_user_id [ad_get_user_id]
    set wiki [im_navbar_doc_wiki]

    set html "
	<li><a href=/intranet-helpdesk/index>[lang::message::lookup "" intranet-helpdesk.${base_ticket_type}_Management "$base_ticket_type Management"]</a>
	<ul>
    "

    if {0 == $current_user_id} { return "$html</ul>\n" }

    # Create a new Ticket
    set url [export_vars -base "/intranet-helpdesk/new" {base_ticket_type_id}]
    set name [lang::message::lookup "" intranet-helpdesk.New_${base_ticket_type}_Ticket "New $base_ticket_type Ticket"]
    append html "<li><a href=\"$url\">$name</a>\n"

    # Add sub-menu with types of tickets
    append html "
	<li><a href=[export_vars -base "/intranet-helpdesk/index" {base_ticket_type_id}]>$base_ticket_type Ticket Types</a>
	<ul>
    "
    set ticket_type_sql "
	select	*
	from	im_ticket_types
	where	ticket_type_id in ([join [im_sub_categories $base_ticket_type_id] ","])
	order by ticket_type
    "
    db_foreach ticket_types $ticket_type_sql {
	set url [export_vars -base "/intranet-helpdesk/index" {ticket_type_id}]
        regsub -all " " $ticket_type "_" ticket_type_subst
	set name [lang::message::lookup "" intranet-helpdesk.Ticket_type_$ticket_type_subst "${ticket_type}s"]
	append html "<li><a href=\"$url\">$name</a></li>\n"
    }
    append html "
	</ul>
	</li>
    "

    append html "
	</ul>
	</li>
    "
    return $html
}


# ---------------------------------------------------------------
# Component showing related objects
# ---------------------------------------------------------------

ad_proc -public im_helpdesk_related_objects_component {
    -ticket_id:required
} {
    Returns a HTML component with the list of related tickets.
} {
    set params [list \
                    [list base_url "/intranet-helpdesk/"] \
                    [list ticket_id $ticket_id] \
                    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-helpdesk/www/related-objects-component"]
    return [string trim $result]
}

ad_proc -public im_helpdesk_related_tickets_component {
    -ticket_id:required
} {
    Replaced by im_helpdesk_related_objects_component
} {
    return ""
}





# ---------------------------------------------------------------
# Nuke
# ---------------------------------------------------------------

ad_proc im_ticket_nuke {
    {-current_user_id 0}
    ticket_id
} {
    Nuke (complete delete from the database) a ticket.
    Returns an empty string if everything was OK or an error
    string otherwise.
} {
    ns_log Notice "im_ticket_nuke ticket_id=$ticket_id"
    return [im_project_nuke -current_user_id $current_user_id $ticket_id]
}


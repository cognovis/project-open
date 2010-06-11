# /packages/intranet-rest/tcl/intranet-rest-create-procs.tcl
#
# Copyright (C) 2009-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    REST Web Service Component Library
    @author frank.bergmann@project-open.com

    This file contains object creation scripts for a number
    of object types.
}

# -------------------------------------------------------
# Index
#
#	Project
#	Ticket
#	Translation Task
#	Company
#	User
#	Invoice
#	Invoice Item (fake object)
#	Hour (fake object, create + update)
# -------------------------------------------------------


# -------------------------------------------------------
# Project
# -------------------------------------------------------

ad_proc -private im_rest_post_object_type_im_project {
    { -format "xml" }
    { -user_id 0 }
    { -content "" }
} {
    Create a new project and returns the project_id.
} {
    ns_log Notice "im_rest_post_object_type_im_project: user_id=$user_id"

    # store the key-value pairs into a hash array
    if {[catch {set doc [dom parse $content]} err_msg]} {
	return [im_rest_error -http_status 406 -message "Unable to parse XML: '$err_msg'."]
    }

    set root_node [$doc documentElement]
    foreach child [$root_node childNodes] {
	# Store the values
	set nodeName [$child nodeName]
	set nodeText [$child text]
	set hash($nodeName) $nodeText
	set $nodeName $nodeText
    }

    # Check that all required variables are there
    foreach var {project_name project_nr project_path company_id parent_id project_status_id project_type_id} {
	if {![info exists $var]} { 
	    return [im_rest_error -http_status 406 -message "Field '$var' not specified"] 
	}
    }

    # Check for duplicate
    set parent_sql "parent_id = :parent_id"
    if {"" == $parent_id} { set parent_sql "parent_id is NULL" }

    set dup_sql "
		select  count(*)
		from    im_projects
		where   $parent_sql and
			(       upper(trim(project_name)) = upper(trim(:project_name)) OR
				upper(trim(project_nr)) = upper(trim(:project_nr)) OR
				upper(trim(project_path)) = upper(trim(:project_path))
			)
    "
    if {[db_string duplicates $dup_sql]} {
	return [im_rest_error -http_status 406 -message "Duplicate Project: Your project name or project path already exists for the specified parent_id."]
    }

    if {[catch {
	set rest_oid [project::new \
			-creation_user		$user_id \
			-context_id		"" \
			-project_name		$hash(project_name) \
			-project_nr		$hash(project_nr) \
			-project_path       	$hash(project_path) \
			-company_id	 	$hash(company_id) \
			-parent_id	  	$hash(parent_id) \
			-project_type_id    	$hash(project_type_id) \
			-project_status_id  	$hash(project_status_id) \
	]
    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error creating project: '$err_msg'."]
    }

    if {[catch {
	im_rest_object_type_update_sql \
	    -rest_otype "im_project" \
	    -rest_oid $rest_oid \
	    -hash_array [array get hash]

    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error updating project: '$err_msg'."]
    }
    
    return $rest_oid
}


# -------------------------------------------------------
# Ticket
# -------------------------------------------------------

ad_proc -private im_rest_post_object_type_im_ticket {
    { -format "xml" }
    { -user_id 0 }
    { -content "" }
} {
    Create a new ticket and returns the ticket_id.
} {
    ns_log Notice "im_rest_post_object_type_im_ticket: user_id=$user_id"

    # store the key-value pairs into a hash array
    if {[catch {set doc [dom parse $content]} err_msg]} {
	return [im_rest_error -http_status 406 -message "Unable to parse XML: '$err_msg'."]
    }

    set root_node [$doc documentElement]
    foreach child [$root_node childNodes] {
	# Store the values
	set nodeName [$child nodeName]
	set nodeText [$child text]
	set hash($nodeName) $nodeText
	set $nodeName $nodeText
	ns_log Notice "im_rest_post_object_type_im_ticket: $nodeName = $nodeText"
    }

    if {![info exists ticket_nr]} { set ticket_nr [db_nextval "im_ticket_seq"] }
    if {![info exists ticket_customer_contact_id]} { set ticket_customer_contact_id "" }
    if {![info exists ticket_start_date]} { set ticket_start_date "" }
    if {![info exists ticket_end_date]} { set ticket_end_date "" }
    if {![info exists ticket_note]} { set ticket_note "" }

    # Check that all required variables are there
    foreach var {project_name parent_id ticket_status_id ticket_type_id} {
	if {![info exists $var]} { 
	    ns_log Notice "im_rest_post_object_type_im_ticket: Missing variable: $var"
	    return [im_rest_error -http_status 406 -message "Field '$var' not specified"] 
	}
    }

    set parent_sql "p.parent_id = :parent_id"
    if {"" == $parent_id} { set parent_sql "p.parent_id is NULL" }

    set dup_sql "
		select	count(*)
		from	im_tickets t,
			im_projects p
		where	t.ticket_id = p.project_id and
			$parent_sql and
			(       upper(trim(p.project_name)) = upper(trim(:project_name)) OR
				upper(trim(p.project_nr)) = upper(trim(:ticket_nr))
			)
    "
    if {[db_string duplicates $dup_sql]} {
	return [im_rest_error -http_status 406 -message "Duplicate Ticket: Your ticket name already exists."]
    }

    # Check for valid parent_id
    set company_id [db_string ticket_company "select company_id from im_projects where project_id = :parent_id" -default ""]
    if {"" == $company_id} {
	return [im_rest_error -http_status 406 -message "Invalid 'parent_id': parent_id should represent an 'open' project of type 'Service Level Agreement'."]
    }

    if {[catch {
	db_transaction {

	    set rest_oid [im_ticket::new \
			      -ticket_sla_id $parent_id \
			      -ticket_name $project_name \
			      -ticket_nr $ticket_nr \
			      -ticket_customer_contact_id $ticket_customer_contact_id \
			      -ticket_type_id $ticket_type_id \
			      -ticket_status_id $ticket_status_id \
			      -ticket_start_date $ticket_start_date \
			      -ticket_end_date $ticket_end_date \
			      -ticket_note $ticket_note \
			     ]

	}
    } err_msg]} {
	ns_log Notice "im_rest_post_object_type_im_ticket: Error creating ticket: '$err_msg'"
	return [im_rest_error -http_status 406 -message "Error creating ticket: '$err_msg'."]
    }


    if {[catch {
	im_rest_object_type_update_sql \
	    -rest_otype "im_ticket" \
	    -rest_oid $rest_oid \
	    -hash_array [array get hash]

    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error updating ticket: '$err_msg'."]
    }
    
    return $rest_oid
}



# --------------------------------------------------------
# Translation Task
# --------------------------------------------------------

ad_proc -private im_rest_post_object_type_im_trans_task {
    { -format "xml" }
    { -user_id 0 }
    { -content "" }
} {
    Create a new Translation Task and return the task_id.
} {
    ns_log Notice "im_rest_post_object_type_im_trans_task: user_id=$user_id"

    # store the key-value pairs into a hash array
    if {[catch {set doc [dom parse $content]} err_msg]} {
	return [im_rest_error -http_status 406 -message "Unable to parse XML: '$err_msg'."]
    }

    set root_node [$doc documentElement]
    foreach child [$root_node childNodes] {
	set nodeName [$child nodeName]
	set nodeText [$child text]
	
	# Store the values
	set hash($nodeName) $nodeText
	set $nodeName $nodeText
    }

    # Check for duplicate
    set dup_sql "
		select  count(*)
		from    im_trans_tasks
		where   project_id = :project_id and
			task_name = :task_name and
			target_language_id = :target_language_id
    "
    if {[db_string duplicates $dup_sql]} {
	return [im_rest_error -http_status 406 -message "Duplicate Translation Task: Your translation task name already exists for the specified parent_id."]
    }

    if {[catch {
	set rest_oid [db_string new_trans_task "
		select im_trans_task__new (
			null,			-- task_id
			'im_trans_task',	-- object_type
			now(),			-- creation_date
			:user_id,		-- creation_user
			'[ns_conn peeraddr]',	-- creation_ip	
			null,			-- context_id	

			:project_id,		-- project_id	
			:task_type_id,		-- task_type_id	
			:task_status_id,	-- task_status_id
			:source_language_id,	-- source_language_id
			:target_language_id,	-- target_language_id
			:task_uom_id		-- task_uom_id
		)
	"]
    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error creating translation task: '$err_msg'."]
    }

    if {[catch {
	im_rest_object_type_update_sql \
	    -rest_otype "im_trans_task" \
	    -rest_oid $rest_oid \
	    -hash_array [array get hash]

    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error updating translation task: '$err_msg'."]
    }
    
    return $rest_oid
}


# --------------------------------------------------------
# Company
# --------------------------------------------------------

ad_proc -private im_rest_post_object_type_im_company {
    { -format "xml" }
    { -user_id 0 }
    { -content "" }
} {
    Create a new Company and return the company_id.
} {
    ns_log Notice "im_rest_post_object_type_im_company: user_id=$user_id"

    # store the key-value pairs into a hash array
    if {[catch {set doc [dom parse $content]} err_msg]} {
	return [im_rest_error -http_status 406 -message "Unable to parse XML: '$err_msg'."]
    }

    set root_node [$doc documentElement]
    foreach child [$root_node childNodes] {
	set nodeName [$child nodeName]
	set nodeText [$child text]
	
	# Store the values
	set hash($nodeName) $nodeText
	set $nodeName $nodeText
    }

    # Check for duplicate
    set dup_sql "
		select  count(*)
		from    im_companys
		where   project_id = :project_id and
			task_name = :task_name and
			target_language_id = :target_language_id
    "
    if {[db_string duplicates $dup_sql]} {
	return [im_rest_error -http_status 406 -message "Duplicate Translation Task: Your translation task name already exists for the specified parent_id."]
    }

    if {[catch {
	set rest_oid [db_string new_company "
		select im_company__new (
			null,			-- task_id
			'im_company',	-- object_type
			now(),			-- creation_date
			:user_id,		-- creation_user
			'[ns_conn peeraddr]',	-- creation_ip	
			null,			-- context_id	

			:project_id,		-- project_id	
			:task_type_id,		-- task_type_id	
			:task_status_id,	-- task_status_id
			:source_language_id,	-- source_language_id
			:target_language_id,	-- target_language_id
			:task_uom_id		-- task_uom_id
		)
	"]
    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error creating translation task: '$err_msg'."]
    }

    if {[catch {
	im_rest_object_type_update_sql \
	    -rest_otype "im_company" \
	    -rest_oid $rest_oid \
	    -hash_array [array get hash]

    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error updating translation task: '$err_msg'."]
    }
    
    return $rest_oid
}

# --------------------------------------------------------
# User
# --------------------------------------------------------

ad_proc -private im_rest_post_object_type_user {
    { -format "xml" }
    { -user_id 0 }
    { -content "" }
} {
    Create a new User object return the user_id.
} {
    ns_log Notice "im_rest_post_object_type_user: Started"
    set current_user_id $user_id

    # Make sure we don't get confused with the generic user_id
    # We will call the ID of the new user new_user_id
    unset user_id

    # store the key-value pairs into a hash array
    if {[catch {set doc [dom parse $content]} err_msg]} {
	return [im_rest_error -http_status 406 -message "Unable to parse XML: '$err_msg'."]
    }

    set root_node [$doc documentElement]
    foreach child [$root_node childNodes] {
	set nodeName [$child nodeName]
	set nodeText [$child text]
	
	# Store the values
	set hash($nodeName) $nodeText
	set $nodeName $nodeText
    }

    # Check for duplicate
    set dup_sql "
		select  count(*)
		from    users u,
			persons pe,
			parties pa
		where	u.user_id = pe.person_id and
			u.user_id = pa.party_id and
			(	lower(u.username) = lower(:username) OR
				lower(pa.email) = lower(:email)
			)
    "
    if {[db_string duplicates $dup_sql]} {
	return [im_rest_error -http_status 406 -message "Duplicate User: Username or Email already exist."]
    }

    if {[catch {

	ns_log Notice "im_rest_post_object_type_user: about to create user"
	array set creation_info [auth::create_user \
				     -username $username \
				     -email $email \
				     -first_names $first_names \
				     -last_name $last_name \
				     -screen_name $screen_name \
				     -password $password \
				     -url $url \
				    ]

    
	if { "ok" != $creation_info(creation_status) || "ok" != $creation_info(account_status)} {
	    return [im_rest_error -http_status 406 -message "User creation unsuccessfull: [array get creation_status]"]
	}
	set new_user_id $creation_info(user_id)
	
	# Update creation user to allow the creator to admin the user
	db_dml update_creation_user_id "
		update acs_objects
		set creation_user = :current_user_id
		where object_id = :new_user_id
	"
    
	ns_log Notice "im_rest_post_object_type_user: person::update -person_id=$new_user_id -first_names=$first_names -last_name=$last_name"
	person::update \
		-person_id $new_user_id \
		-first_names $first_names \
		-last_name $last_name
	    
	    ns_log Notice "im_rest_post_object_type_user: party::update -party_id=$new_user_id -url=$url -email=$email"
	    party::update \
		-party_id $new_user_id \
		-url $url \
		-email $email
	    
	    ns_log Notice "im_rest_post_object_type_user: acs_user::update -user_id=$new_user_id -screen_name=$screen_name"
	    acs_user::update \
		-user_id $new_user_id \
		-screen_name $screen_name \
		-username $username


        # Add the user to the "Registered Users" group, because
        # (s)he would get strange problems otherwise
        # Use a non-cached version here to avoid issues!
        set registered_users [im_registered_users_group_id]
        set reg_users_rel_exists_p [db_string member_of_reg_users "
		select	count(*) 
		from	group_member_map m, membership_rels mr
		where	m.member_id = :new_user_id
			and m.group_id = :registered_users
			and m.rel_id = mr.rel_id 
			and m.container_id = m.group_id 
			and m.rel_type::text = 'membership_rel'::text
	"]
	if {!$reg_users_rel_exists_p} {
	    relation_add -member_state "approved" "membership_rel" $registered_users $new_user_id
	}

    
	# Add a im_employees record to the user since the 3.0 PostgreSQL
	# port, because we have dropped the outer join with it...
	if {[im_table_exists im_employees]} {
	    
	    # Simply add the record to all users, even it they are not employees...
	    set im_employees_exist [db_string im_employees_exist "select count(*) from im_employees where employee_id = :new_user_id"]
	    if {!$im_employees_exist} {
		db_dml add_im_employees "insert into im_employees (employee_id) values (:new_user_id)"
	    }
	}
	
	
	# Add a im_freelancers record to the user since the 3.0 PostgreSQL
	# port, because we have dropped the outer join with it...
	if {[im_table_exists im_freelancers]} {
	    
	    # Simply add the record to all users, even it they are not freelancers...
	    set im_freelancers_exist [db_string im_freelancers_exist "select count(*) from im_freelancers where user_id = :new_user_id"]
	    if {!$im_freelancers_exist} {
		db_dml add_im_freelancers "insert into im_freelancers (user_id) values (:new_user_id)"
	    }
	}

    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error creating user: '$err_msg'."]
    }

    if {[catch {
	im_rest_object_type_update_sql \
	    -rest_otype "user" \
	    -rest_oid $new_user_id \
	    -hash_array [array get hash]

    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error updating user: '$err_msg'."]
    }

    return $new_user_id
}


# --------------------------------------------------------
# Invoices
# --------------------------------------------------------

ad_proc -private im_rest_post_object_type_im_invoice {
    { -format "xml" }
    { -user_id 0 }
    { -content "" }
} {
    Create a new Financial Document and return the task_id.
} {
    ns_log Notice "im_rest_post_object_type_im_invoice: user_id=$user_id"

    # store the key-value pairs into a hash array
    if {[catch {set doc [dom parse $content]} err_msg]} {
	return [im_rest_error -http_status 406 -message "Unable to parse XML: '$err_msg'."]
    }

    set note ""
    set amount 0
    set currency "EUR"
    set vat ""
    set tax ""

    set root_node [$doc documentElement]
    foreach child [$root_node childNodes] {
	# Store the values
	set nodeName [$child nodeName]
	set nodeText [$child text]
	set hash($nodeName) $nodeText
	set $nodeName $nodeText
    }

    # Check for duplicate
    set dup_sql "
		select  count(*)
		from    im_invoices
		where	invoice_nr = :invoice_nr
    "
    if {[db_string duplicates $dup_sql]} {
	return [im_rest_error -http_status 406 -message "Duplicate Financial Document: Your financial document already exists with the specified invoice_nr='$invoice_nr'."]
    }

    if {[catch {
	set rest_oid [db_string new_invoice "
		select im_invoice__new (
			NULL,			-- invoice_id
			'im_invoice',		-- object_type
			now(),			-- creation_date 
			:user_id,		-- creation_user
			'[ad_conn peeraddr]',	-- creation_ip
			null,			-- context_id

			:invoice_nr,		-- invoice_nr
			:customer_id,		-- customer_id
			:provider_id,		-- provider_id
			:company_contact_id,	-- company_contact_id
			:effective_date,	-- effective_date
			:currency,		-- currency
			:template_id,		-- template_id
			:cost_status_id,	-- cost_status_id
			:cost_type_id,		-- cost_type_id
			:payment_method_id,	-- payment_method_id
			:payment_days,		-- payment_days
			:amount,		-- amount
			:vat,			-- vat
			:tax,			-- tax
			:note			-- note
		)
	"]
    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error creating financial document: '$err_msg'."]
    }

    if {[catch {
	im_rest_object_type_update_sql \
	    -rest_otype "im_invoice" \
	    -rest_oid $rest_oid \
	    -hash_array [array get hash]

    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error updating financial document: '$err_msg'."]
    }
    
    return $rest_oid
}


# --------------------------------------------------------
# Invoice Items - It's not really an object type,
# so we have to fake it here.
# --------------------------------------------------------

ad_proc -private im_rest_post_object_type_im_invoice_item {
    { -format "xml" }
    { -user_id 0 }
    { -content "" }
} {
    Create a new Financial Document line and return the item_id.
} {
    ns_log Notice "im_rest_post_object_type_im_invoice_item: user_id=$user_id"

    # store the key-value pairs into a hash array
    if {[catch {set doc [dom parse $content]} err_msg]} {
	return [im_rest_error -http_status 406 -message "Unable to parse XML: '$err_msg'."]
    }

    set root_node [$doc documentElement]
    foreach child [$root_node childNodes] {
	# Store the values
	set nodeName [$child nodeName]
	set nodeText [$child text]
	set hash($nodeName) $nodeText
	set $nodeName $nodeText
    }

    # Check for duplicate
    set dup_sql "
		select  count(*)
		from    im_invoice_items
		where	item_name = :item_name and
			invoice_id = :invoice_id and
			sort_order = :sort_order
    "
    if {[db_string duplicates $dup_sql]} {
	return [im_rest_error -http_status 406 -message "Duplicate Financial Document Item: Your item already exists with the specified invoice_name, invoice_id and sort_order."]
    }

    if {[catch {
	set rest_oid [db_string item_id "select nextval('im_invoice_items_seq')"]
	db_dml new_invoice_item "
		insert into im_invoice_items (
			item_id,
			item_name,
			invoice_id,
			item_uom_id,
			sort_order
		) values (
			:rest_oid,
			:item_name,
			:invoice_id,
			:item_uom_id,
			:sort_order
		)
	"
    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error creating financial document item: '$err_msg'."]
    }

    if {[catch {
	im_rest_object_type_update_sql \
	    -rest_otype "im_invoice_item" \
	    -rest_oid $rest_oid \
	    -hash_array [array get hash]

    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error updating financial document item: '$err_msg'."]
    }

    # re-calculate the amount of the invoice
    im_invoice_update_rounded_amount -invoice_id $invoice_id 
    
    return $rest_oid
}


# --------------------------------------------------------
# im_hour
# Not an object type really, so we have to fake it here.
# --------------------------------------------------------


ad_proc -private im_rest_post_object_type_im_hour {
    { -format "xml" }
    { -user_id 0 }
    { -content "" }
} {
    Create a new Timesheet Hour line and return the item_id.
} {
    ns_log Notice "im_rest_post_object_type_im_hour: user_id=$user_id"

    # store the key-value pairs into a hash array
    if {[catch {set doc [dom parse $content]} err_msg]} {
	return [im_rest_error -http_status 406 -message "Unable to parse XML: '$err_msg'."]
    }

    set root_node [$doc documentElement]
    foreach child [$root_node childNodes] {
	# Store the values
	set nodeName [$child nodeName]
	set nodeText [$child text]
	set hash($nodeName) $nodeText
	set $nodeName $nodeText
    }

    # Check for duplicate
    set dup_sql "
		select  count(*)
		from    im_hours
		where	user_id = :user_id and
			project_id = :project_id and
			day = :day
    "
    if {[db_string duplicates $dup_sql]} {
	return [im_rest_error -http_status 406 -message "Duplicate Timesheet Hour: Your item already exists with the specified user, project and day."]
    }

    if {[catch {
	set rest_oid [db_string item_id "select nextval('im_hours_seq')"]
	db_dml new_im_hour "
		insert into im_hours (
			hour_id,
			user_id,
			project_id,
			day,
			hours,
			note
		) values (
			:rest_oid,
			:user_id,
			:project_id,
			:day,
			:hours,
			:note
		)
	"
    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error creating Timesheet Hour: '$err_msg'."]
    }

    if {[catch {
	im_rest_object_type_update_sql \
	    -rest_otype "im_hour" \
	    -rest_oid $rest_oid \
	    -hash_array [array get hash]

    } err_msg]} {
	return [im_rest_error -http_status 406 -message "Error updating financial document item: '$err_msg'."]
    }

    return $rest_oid
}


# --------------------------------------------------------
# im_hours
#
# Update operation. This is implemented here, because
# im_hour isn't a real object

ad_proc -private im_rest_post_object_im_hour {
    { -format "xml" }
    { -user_id 0 }
    { -rest_otype "" }
    { -rest_oid "" }
    { -query_hash_pairs "" }
    { -content "" }
    { -debug 0 }
} {
    Handler for POST calls on particular im_hour objects.
    im_hour is not a real object type and performs a "delete" 
    operation specifying hours=0 or hours="".
} {
    ns_log Notice "im_rest_post_object_im_hour: rest_oid=$rest_oid"

    # store the key-value pairs into a hash array
    if {[catch {set doc [dom parse $content]} err_msg]} {
	return [im_rest_error -http_status 406 -message "Unable to parse XML: '$err_msg'."]
    }

    set root_node [$doc documentElement]
    array unset hash_array
    foreach child [$root_node childNodes] {
	set nodeName [$child nodeName]
	set nodeText [$child text]
       	set hash_array($nodeName) $nodeText
    }
    ns_log Notice "im_rest_post_object_im_hour: hash_array = [array get hash_array]"

    set hours $hash_array(hours)
    set hour_id $hash_array(hour_id)
    if {"" == $hours || 0.0 == $hours} {
	
	# Delete the hour instead of updating it.
	# im_hours is not a real object, so we don't need to
	# cleanup acs_objects.
	ns_log Notice "im_rest_post_object_im_hour: deleting hours because hours='$hours', hour_id=$hour_id"
	db_dml del_hours "delete from im_hours where hour_id = :hour_id"

    } else {


	# Update the object. This routine will return a HTTP error in case 
	# of a database constraint violation
	ns_log Notice "im_rest_post_object_im_hour: updating hours=$hours with hour_id=$hour_id"
	im_rest_object_type_update_sql \
	    -rest_otype $rest_otype \
	    -rest_oid $rest_oid \
	    -hash_array [array get hash_array]

    }

    # The update was successful - return a suitable message.
    switch $format {
	html { 
	    set page_title "object_type: $rest_otype"
	    doc_return 200 "text/html" "
		[im_header $page_title][im_navbar]<table>
		<tr class=rowtitle><td class=rowtitle>Object ID</td></tr>
		<tr<td>$rest_oid</td></tr>
		</table>[im_footer]
	    "
	}
	xml {  doc_return 200 "text/xml" "<?xml version='1.0'?>\n<object_id id=\"$rest_oid\">$rest_oid</object_id>\n" }
    }
}


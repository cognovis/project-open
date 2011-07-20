# /packages/intranet-audit/tcl/intranet-audit-procs.tcl
#
# Copyright (C) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Components to show Audit info
# ----------------------------------------------------------------------

ad_proc -public im_audit_component { 
    -object_id:required
} {
    Generic portlet component to show the audit trail for the given
    Object
} {
    template::list::create \
	-name audit_list \
	-multirow audit_multirow \
	-key audit_id \
	-selected_format "normal" \
	-class "list" \
	-main_class "list" \
	-sub_class "narrow" \
	-actions {
	} -bulk_actions {
	} -elements {
	    audit_date {
		display_col audit_date_pretty
		label "[lang::message::lookup {} intranet-audit.Date {Date}]"
	        display_template {
			<a href="@audit_multirow.audit_details_url;noquote@"><nobr>@audit_multirow.audit_date_pretty@</nobr></a>
		}
	    }
	    audit_user_initials {
		label "[lang::message::lookup {} intranet-audit.User_Abbrev U]"
	        display_template {
	            <if @audit_multirow.audit_user_id@ ne 0>
			<a href="@audit_multirow.audit_user_url;noquote@" title="@audit_multirow.audit_user_name@">@audit_multirow.audit_user_initials@</a>
	            </if>
		}
	    }
	    audit_action {
		label "[lang::message::lookup {} intranet-audit.Action_Abbrev A]"
	        display_template {
		    @audit_multirow.audit_action_gif;noquote@
		}
	    }
	    audit_ip {
		display_col audit_ip
		label "[lang::message::lookup {} intranet-audit.IP_Address {IP}]"
	    }
	    audit_object_status {
		label "[lang::message::lookup {} intranet-audit.Object_Status {Status}]"
	    }
	    audit_diff {
		label "[lang::message::lookup {} intranet-audit.Diff {Diff}]"
	    }
	}    

    set audit_sql "
	select	*,
		to_char(audit_date, 'YYYY-MM-DD HH24:MI:SS') as audit_date_pretty,
		im_category_from_id(audit_object_status_id) as audit_object_status,
		im_initials_from_user_id(audit_user_id) as audit_user_initials,
		im_name_from_user_id(audit_user_id) as audit_user_name
	from	im_audits
	where	audit_object_id = :object_id
	order by audit_id DESC
    "
    
    set cnt 0
    db_multirow -extend { audit_details_url audit_user_url audit_ip_url audit_action_gif } audit_multirow audit_list $audit_sql {
	set audit_details_url [export_vars -base "/intranet-audit/view" {audit_id}]
	set audit_user_url [export_vars -base "/intranet/users/view" {{user_id $audit_user_id}}]
	set audit_ip_url ""

	switch $audit_action {
	    create { set audit_action_abbrev "c" }
	    update { set audit_action_abbrev "u" }
	    delete { set audit_action_abbrev "d" }
	    nuke { set audit_action_abbrev "n" }
	    default { set audit_action_abbrev "" }
	}
	set audit_action_msg [lang::message::lookup "" intranet-audit.Action_${audit_action}_help $audit_action]
	set audit_action_gif [im_gif $audit_action_abbrev $audit_action_msg]
	incr cnt
    }

    # Compile and execute the listtemplate
    eval [template::adp_compile -string {<listtemplate name="audit_list"></listtemplate>}]
    set list_html $__adp_output

    return $list_html

#    set title [lang::message::lookup "" intranet-audit.Audit_Trail "Audit Trail"]
#    return [im_table_with_title $title $list_html]
}




# ----------------------------------------------------------------------
# Audit Procedures
# ----------------------------------------------------------------------

ad_proc -public im_audit_object_type_sql { 
    -object_type:required
} {
    Calculates the SQL statement to extract the value for an object
    of the given object_type. The SQL will contains a ":object_id"
    colon-variables, so the variable "object_id" must be defined in 
    the context where this statement is to be executed.
} {
    ns_log Notice "im_audit_object_type_sql: object_type=$object_type"

    # ---------------------------------------------------------------
    # Construct a SQL that pulls out all information about one object
    set tables_sql "
	select	table_name,
		id_column
	from	acs_object_types
	where	object_type = :object_type
UNION
	select	table_name,
		id_column
	from	acs_object_type_tables
	where	object_type = :object_type
    "

    set letters {a b c d e f g h i j k l m n o p q r s t u v w x y z}
    set from {}
    set wheres { "1=1" }
    set cnt 0
    db_foreach tables $tables_sql {
	set letter [lindex $letters $cnt]
	lappend froms "$table_name $letter"
	lappend wheres "$letter.$id_column = :object_id"
	incr cnt
    }

    set sql "
	select	*
	from	[join $froms ", "]
	where	[join $wheres " and "]
    "

    ns_log Notice "im_audit_object_type_sql: About to return sql=$sql"
    return $sql
}



ad_proc -public im_audit_object_value { 
    -object_id:required
    { -object_type "" }
} {
    Concatenates the value of all object fields (according to DynFields)
    to form a single string describing the object's values.
} {
    ns_log Notice "im_audit_object_value: object_id=$object_id, object_type=$object_type"

    if {"" == $object_id} { return "" }
    im_security_alert_check_integer -location "im_audit_object_value" -value $object_id

    if {"" == $object_type} {
	set object_type [util_memoize [list db_string otype "select object_type from acs_objects where object_id = $object_id" -default ""]]
    }

    # Get the SQL to extract all values from the object
    set sql [util_memoize [list im_audit_object_type_sql -object_type $object_type]]

    # Execute the sql. As a result we get "col_names" with list of columns and "lol" with the result list of lists
    set col_names ""
    db_with_handle db {
	set selection [db_exec select $db query $sql 1]
	set lol [list]
	while { [db_getrow $db $selection] } {
	    set col_names [ad_ns_set_keys $selection]
	    set this_result [list]
	    for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		lappend this_result [ns_set value $selection $i]
	    }
	    lappend lol $this_result
	}
    }
    db_release_unused_handles

    if {![info exists col_names]} {
	ns_log Error "im_audit_object_value: For some reason we didn't find any record matching sql=$sql"
	return ""
    }

    # lol should have only a single line!
    set col_values [lindex $lol 0]

    set value ""
    for {set i 0} {$i < [llength $col_names]} {incr i} {
	set var [lindex $col_names $i]
	set val [lindex $col_values $i]
	
	# We need to quote \n and \t in $val because it is used to separate values
	regsub -all {\n} $val {\n} val
	regsub -all {\t} $val {\t} val

	# Skip a number of known internal variables
	if {"tree_sortkey" == $var} { continue }
	if {"max_child_sortkey" == $var} { continue }

	# Add the line to the "value"
	append value "$var	$val\n"
    }

    return $value
}



ad_proc -public im_audit_calculate_diff { 
    -old_value:required
    -new_value:required
} {
    Calculates the difference between and old an a new value and
    returns only the lines that have changed.
    Each line consists of: variable \t value \n.
} {
    foreach old_line [split $old_value "\n"] {
	set pieces [split $old_line "\t"]
	set var [lindex $pieces 0]
	set val [lindex $pieces 1]
	set hash($var) $val
    }

    set diff ""
    foreach new_line [split $new_value "\n"] {
	set pieces [split $new_line "\t"]
	set var [lindex $pieces 0]
	set val [lindex $pieces 1]
	set old_val ""
	if {[info exists hash($var)]} { set old_val $hash($var) }
	if {$val != $old_val} { append diff "$new_line\n" }
    }

    return $diff   
}


# ----------------------------------------------------------------------
# Main Audit Procedure
# ----------------------------------------------------------------------

ad_proc -public im_audit_impl { 
    -object_id:required
    {-user_id "" }
    {-object_type "" }
    {-status_id "" }
    {-type_id "" }
    {-action "after_update" }
    {-comment "" }
} {
    Creates a new audit item for object after an update.
} {
    ns_log Notice "im_audit_impl: object_id=$object_id, user_id=$user_id, object_type=$object_type, status_id=$status_id, type_id=$type_id, action=$action, comment=$comment"

    if {"" == $user_id} { set user_id [ad_get_user_id] }
    set peeraddr [ns_conn peeraddr]
    if {"" == $action} { set action "update" }
    set action [string tolower $action]

    # Are we behind a firewall or behind a reverse proxy?
    if {"127.0.0.1" == $peeraddr} {

	# Get the IP of the browser of the user
	set header_vars [ns_conn headers]
	set x_forwarded_for [ns_set get $header_vars "X-Forwarded-For"]
	if {"" != $x_forwarded_for} {
	    set peeraddr $x_forwarded_for
	}
    }

    # Get information about the audit object
    set object_type ""
    set old_value ""
    set last_audit_id ""
    db_0or1row last_info "
	select	a.audit_value as old_value,
		o.object_type,
		o.last_audit_id
	from	im_audits a,
		acs_objects o
	where	o.object_id = :object_id and
		o.last_audit_id = a.audit_id
    "

    # Get the new value from the database
    set new_value [im_audit_object_value -object_id $object_id -object_type $object_type]

    # Calculate the "diff" between old and new value.
    # Return "" if nothing has changed:
    set diff [im_audit_calculate_diff -old_value $old_value -new_value $new_value]

    if {"" != $diff} {
	# Something has changed...
	# Create a new im_audit entry and associate it to the object.
	set new_audit_id [db_nextval im_audit_seq]
	set audit_ref_object_id ""
	set audit_note $comment
	set audit_hash ""

	db_dml insert_audit "
		insert into im_audits (
			audit_id,
			audit_object_id,
			audit_object_status_id,
			audit_action,
			audit_user_id,
			audit_date,
			audit_ip,
			audit_last_id,
			audit_ref_object_id,
			audit_value,
			audit_diff,
			audit_note,
			audit_hash
		) values (
			:new_audit_id,
			:object_id,
			im_biz_object__get_status_id(:object_id),
			:action,
			:user_id,
			now(),
			:peeraddr,
			:last_audit_id,
			:audit_ref_object_id,
			:new_value,
			:diff,
			:audit_note,
			:audit_hash
		)
	"

	db_dml update_object "
		update acs_objects set
			last_audit_id = :new_audit_id,
			last_modified = now(),
			modifying_user = :user_id,
			modifying_ip = :peeraddr
		where object_id = :object_id
	"

    }

    return $diff
}



# -------------------------------------------------------------------
# Audit Sweeper - Make a copy of all "active" projects
# -------------------------------------------------------------------

ad_proc -public im_audit_sweeper { } {
    Make a copy of all "active" projects
} {
    set audit_exists_p [util_memoize "im_table_exists im_projects_audit"]
    if {!$audit_exists_p} { return }

    # Make sure that only one thread is sweeping at a time
    if {[nsv_incr intranet_core audit_sweep_semaphore] > 1} {
        nsv_incr intranet_core audit_sweep_semaphore -1
        ns_log Notice "im_core_audit_sweeper: Aborting. There is another process running"
        return "busy"
    }

    set debug ""
    set err_msg ""
    set counter 0
    catch {
	set interval_hours [parameter::get_from_package_key \
		-package_key intranet-core \
		-parameter AuditProjectProgressIntervalHours \
		-default 0 \
        ]

	set interval_hours 1

	# Select all "active" (=not deleted or canceled) main projects
	# without an update in the last X hours
	set project_sql "
	select	project_id
	from	im_projects
	where	parent_id is null and
		project_status_id not in (
			[im_project_status_deleted], 
			[im_project_status_canceled]
		) and
		project_id not in (
			select	distinct project_id
			from	im_projects_audit
			where	last_modified > (now() - '$interval_hours hours'::interval)
		)
	LIMIT 10
        "
	db_foreach audit $project_sql {
	    append debug [im_project_audit -project_id $project_id]
	    lappend debug $project_id
	    incr counter
	}
    } err_msg

    # Free the semaphore for next use
    nsv_incr intranet_audit audit_sweep_semaphore -1

    return [string trim "$counter $debug $err_msg"]
}


# -------------------------------------------------------------------
# 
# -------------------------------------------------------------------

ad_proc -public im_project_audit_impl  {
    -project_id:required
    {-user_id "" }
    {-action after_update }
    {-comment "" }
} {
    Creates an audit entry of the specified project
} {
    # Call the normal audit function
    if {"" == $user_id} { set user_id [ad_get_user_id] }
    im_audit_impl -object_id $project_id -user_id $user_id

    # No audit for non-existing projects
    if {"" == $project_id} { return "project_id is empty" }
    if {0 == $project_id} { return "project_id = 0" }

    # Make sure the table exists (compatibility)
    set audit_exists_p [im_table_exists im_projects_audit]
    if {!$audit_exists_p} { return "Audit table doesn't exist" }

    # No audit for tasks
    set project_type_id [util_memoize "db_string ptype \"select project_type_id from im_projects where project_id=$project_id\" -default 0"]
    if {$project_type_id == [im_project_type_task]} { return "Project is a task" }

    # Parameter to enable/disable project audit
    set audit_projects_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "AuditProjectsP" -default 1]
    if {!$audit_projects_p} { return "Audit not enabled" }


    # Who is modifying? Use empty values when called from schedules proc sweeper
    set peeraddr "0.0.0.0"
    catch { set peeraddr [ad_conn peeraddr] }
    set modifying_user $user_id
    set modifying_ip $peeraddr

    catch {

	db_dml audit "
	    insert into im_projects_audit (
		modifying_action,
		last_modified,		last_modifying_user,		last_modifying_ip,
		project_id,		project_name,			project_nr,
		project_path,		parent_id,			company_id,
		project_type_id,	project_status_id,		description,
		billing_type_id,	note,				project_lead_id,
		supervisor_id,		project_budget,			corporate_sponsor,
		percent_completed,	on_track_status_id,		project_budget_currency,
		project_budget_hours,	end_date,			start_date,
		company_contact_id,	company_project_nr,		final_company,
		cost_invoices_cache,	cost_quotes_cache,		cost_delivery_notes_cache,
		cost_bills_cache,	cost_purchase_orders_cache,	reported_hours_cache,
		cost_timesheet_planned_cache,	cost_timesheet_logged_cache,
		cost_expense_planned_cache,	cost_expense_logged_cache
	    ) 
	    select
		:action,		
		now(),			:modifying_user,		:modifying_ip,
		project_id,		project_name,			project_nr,
		project_path,		parent_id,			company_id,
		project_type_id,	project_status_id,		description,
		billing_type_id,	note,				project_lead_id,
		supervisor_id,		project_budget,			corporate_sponsor,
		percent_completed,	on_track_status_id,		project_budget_currency,
		project_budget_hours,	end_date,			start_date,
		company_contact_id,	company_project_nr,		final_company,
		cost_invoices_cache,	cost_quotes_cache,		cost_delivery_notes_cache,
		cost_bills_cache,	cost_purchase_orders_cache,	reported_hours_cache,
		cost_timesheet_planned_cache,	cost_timesheet_logged_cache,
		cost_expense_planned_cache,	cost_expense_logged_cache
	    from	im_projects
	    where	project_id = :project_id
        "
    } err_msg

    return $err_msg
}


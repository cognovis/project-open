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
		link_url_eval $audit_user_url
	        display_template {
	            <if @audit_multirow.audit_user_id@ ne 0>
			<a href="@audit_multirow.audit_user_url;noquote@">@audit_multirow.audit_user_initials@</a>
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
	    audit_diff {
		label "[lang::message::lookup {} intranet-audit.Diff {Diff}]"
	    }
	}    

    set audit_sql "
	select	*,
		to_char(audit_date, 'YYYY-MM-DD') as audit_date_pretty,
		im_initials_from_user_id(audit_user_id) as audit_user_initials
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
	    pre_update { set audit_action_abbrev "p" }
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
    return $sql
}



ad_proc -public im_audit_object_value { 
    -object_id:required
    { -object_type "" }
} {
    Concatenates the value of all object fields (according to DynFields)
    to form a single string describing the object's values.
} {
    if {"" == $object_id} { return "" }
    im_security_alert_check_integer -location "im_audit_object_value" -value $object_id

    if {"" == $object_type} {
	set object_type [util_memoize [list db_string otype "select object_type from acs_objects where object_id = $object_id" -default ""]]
    }

    # Get the SQL to extract all values from the object
    set sql [util_memoize [list im_audit_object_type_sql -object_type $object_type]]

    # Execute the sql. As a result we get "col_names" with list of columns and "lol" with the result list of lists
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

    # lol should have only a single line!
    set col_values [lindex $lol 0]

    set value ""
    for {set i 0} {$i < [llength $col_names]} {incr i} {
	set var [lindex $col_names $i]
	set val [lindex $col_values $i]

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
    {-object_type "" }
    {-action "update" }
    {-comment "" }
} {
    Creates a new audit item for object after an update.
} {
    set user_id [ad_get_user_id]
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
			last_audit_id = :new_audit_id
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
    {-action update }
    {-comment "" }
} {
    Creates an audit entry of the specified project
} {
    # Call the normal audit function
    im_audit_impl -object_id $project_id

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
    if {[ad_conn -connected_p]} {
	set modifying_user [ad_get_user_id]
	set modifying_ip [ad_conn peeraddr]
    } else {
	set modifying_user ""
	set modifying_ip ""
    }

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




# ----------------------------------------------------------------------
# Project EVA
# ---------------------------------------------------------------------

ad_proc im_audit_fake_history {
} {
    Create project audit entries for all projects.
    Should be run every hour or two on demo servers.
} {
   set project_ids [db_list pids "select project_id from im_projects where parent_id is null"]
   foreach pid $project_ids {
	im_audit_fake_history_for_project -project_id $pid
   }   
}

ad_proc im_audit_fake_history_for_project {
    -project_id
    {-steps 50}
} {
    Creates im_projects_audit entries for the project
    by splitting the time between start_date and end_date
    in $intervals pieces and calculates new im_projects_audit
    entries for the dates based on the information of
    timesheet hours and financial documents
} {
    set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
    set default_hourly_rate [ad_parameter -package_id [im_package_cost_id] "DefaultTimesheetHourlyCost" "" "30.0"]
    set target_margin_percentage [ad_parameter -package_id [im_package_cost_id] "TargetMarginPercentage" "" "30.0"]

    # Extract max values from the project
    db_1row start_end "
	select
		max(trunc((project_budget * im_exchange_rate(start_date::date, project_budget_currency, :default_currency))::numeric, 2)) as project_budget_max,
		-- The cost side - thee different types - ts, bills and expenses
		max(cost_timesheet_logged_cache) as cost_timesheet_logged_cache_max,
		max(cost_bills_cache) as cost_bills_cache_max,
		max(cost_expense_logged_cache) as cost_expense_logged_cache_max,
		-- The income side - quotes and invoices
		max(cost_invoices_cache) as cost_invoices_cache_max,
		max(cost_quotes_cache) as cost_quotes_cache_max,
		-- Delivered value
		max(cost_delivery_notes_cache) as cost_delivery_notes_cache_max
        from    im_projects_audit
        where   project_id = :project_id
    "

    if {"" == $project_budget_max} { set project_budget_max 0 }
    if {"" == $cost_timesheet_logged_cache_max} { set cost_timesheet_logged_cache_max 0 }
    if {"" == $cost_bills_cache_max} { set cost_bills_cache_max 0 }
    if {"" == $cost_expense_logged_cache_max} { set cost_expense_logged_cache_max 0 }
    if {"" == $cost_invoices_cache_max} { set cost_invoices_cache_max 0 }
    if {"" == $cost_quotes_cache_max} { set cost_quotes_cache_max 0 }
    if {"" == $cost_delivery_notes_cache_max} { set cost_delivery_notes_cache_max 0 }

    set cost_max [expr $cost_timesheet_logged_cache_max + $cost_bills_cache_max + $cost_expense_logged_cache_max]
    set widget_max $cost_max
    if {$project_budget_max > $widget_max} { set widget_max $project_budget_max}
    if {100.0 > $widget_max} { set widget_max 100.0}

    # Get start- and end date in Julian format (as integer)
    db_1row start_end "
        select	p.*,
		to_char(coalesce(start_date, now()), 'J') as start_date_julian,
		to_char(coalesce(end_date, now()), 'J') as end_date_julian,
		to_char(now(), 'J') as now_julian,
		to_char(end_date, 'J')::integer - to_char(start_date, 'J')::integer as duration_days
        from	im_projects p
        where	project_id = :project_id
    "
    
    set cost_start_date_julian [db_string cost_start_date "
	select	to_char(min(c.effective_date), 'J')
	from	im_costs c
	where	c.project_id in (
				select	child.project_id
				from	im_projects parent,
					im_projects child
				where	parent.project_id = :project_id and
					child.tree_sortkey 
						between parent.tree_sortkey 
						and tree_right(parent.tree_sortkey)
		)
    "]


    if {"" != $cost_start_date_julian && $cost_start_date_julian < $start_date_julian} { 
	set start_date_julian $cost_start_date_julian 
    }
    set modifying_action "update"
    if {$now_julian < $end_date_julian} { set end_date_julian $now_julian }
    if {$now_julian < $start_date_julian } { set start_date_julian [expr $now_julian - 10] }
    set duration_days [expr $end_date_julian - $start_date_julian]
    set increment [expr round($duration_days / $steps)]

    # Let's increase the %done value every 3-5th step
    # by a random amount, so that it reaches more or less
    # total_cost / budget
    set percent_completed_final [expr 100.0 * $cost_max / $widget_max]
    set percent_completed 0.0
    ns_log Notice "im_audit_fake_history_for_project: percent_completed_final=$percent_completed_final"

    # Delete the entire history
    db_dml del_audit "delete from im_projects_audit where project_id = :project_id"

    # Loop for every day and calculate the sum of all cost types
    # per cost type
    for { set i $start_date_julian} {$i < $end_date_julian} { set i [expr $i + 1 + $increment] } {

	# Don't go further then today + 30 days
	if {$i > $now_julian + 90} { return }

	# Increase the percent_completed every 5th step
	# by a random percentage
	if {[expr rand()] < 0.2} {
	    set now_done [expr ($percent_completed_final - $percent_completed) * 5.0 / ($steps * 0.2) * rand()]
	    set now_done [expr ($now_done + abs($now_done)) / 2.0]
	    set percent_completed [expr $percent_completed + $now_done]
	    ns_log Notice "im_audit_fake_history_for_project: percent_completed=$percent_completed"
	}

	set cost_timesheet_planned_cache 0.0
	set cost_expense_logged_cache 0.0
	set cost_expense_planned_cache 0.0
	set cost_quotes_cache 0.0
	set cost_bills_cache 0.0
	set cost_purchase_orders_cache 0.0
	set cost_delivery_notes_cache 0.0
	set cost_invoices_cache 0.0
	set cost_timesheet_logged_cache 0.0

	set cost_sql "
		select	sum(c.amount) as amount,
			c.cost_type_id
		from	im_costs c
		where	c.effective_date < to_date(:i, 'J') and
			c.project_id in (
				select	child.project_id
				from	im_projects parent,
					im_projects child
				where	parent.project_id = :project_id and
					child.tree_sortkey 
						between parent.tree_sortkey 
						and tree_right(parent.tree_sortkey)
			)
		group by
			cost_type_id
	"
	db_foreach costs $cost_sql {
	    switch $cost_type_id {
		 3726 { set cost_timesheet_planned_cache $amount }
		 3722 { set cost_expense_logged_cache $amount }
		 3728 { set cost_expense_planned_cache $amount }
		 3702 { set cost_quotes_cache $amount }
		 3704 { set cost_bills_cache $amount }
		 3706 { set cost_purchase_orders_cache $amount }
		 3724 { set cost_delivery_notes_cache $amount }
		 3700 { set cost_invoices_cache $amount }
		 3718 { set cost_timesheet_logged_cache $amount }
	    }
	}
	set ts_sql "
		select	sum(h.hours) as hours
		from	im_hours h
		where	h.day < to_date(:i, 'J') and
			h.project_id in (
				select	child.project_id
				from	im_projects parent,
					im_projects child
				where	parent.project_id = :project_id and
					child.tree_sortkey 
						between parent.tree_sortkey 
						and tree_right(parent.tree_sortkey)
			)
	"
	set reported_hours_cache [db_string hours $ts_sql]

	db_dml insert "
		insert into im_projects_audit (
			modifying_action,
			last_modified,
			last_modifying_user,
			last_modifying_ip,
			project_id,
			project_name,
			project_nr,
			project_path,
			parent_id,
			company_id,
			project_type_id,
			project_status_id,
			description,
			billing_type_id,
			note,
			project_lead_id,
			supervisor_id,
			project_budget,
			corporate_sponsor,
			percent_completed,
			on_track_status_id,
			project_budget_currency,
			project_budget_hours,
			end_date,
			start_date,
			company_contact_id,
			company_project_nr,
			final_company,
			cost_invoices_cache,
			cost_quotes_cache,
			cost_delivery_notes_cache,
			cost_bills_cache,
			cost_purchase_orders_cache,
			cost_timesheet_planned_cache,
			cost_timesheet_logged_cache,
			cost_expense_planned_cache,
			cost_expense_logged_cache,
			reported_hours_cache
		) values (
			:modifying_action,
			to_date(:i,'J'),
			'[ad_get_user_id]',
			'[ns_conn peeraddr]',
			:project_id,
			:project_name,
			:project_nr,
			:project_path,
			:parent_id,
			:company_id,
			:project_type_id,
			:project_status_id,
			:description,
			:billing_type_id,
			:note,
			:project_lead_id,
			:supervisor_id,
			:project_budget,
			:corporate_sponsor,
			:percent_completed,
			:on_track_status_id,
			:project_budget_currency,
			:project_budget_hours,
			:end_date,
			:start_date,
			:company_contact_id,
			:company_project_nr,
			:final_company,
			:cost_invoices_cache,
			:cost_quotes_cache,
			:cost_delivery_notes_cache,
			:cost_bills_cache,
			:cost_purchase_orders_cache,
			:cost_timesheet_planned_cache,
			:cost_timesheet_logged_cache,
			:cost_expense_planned_cache,
			:cost_expense_logged_cache,
			:reported_hours_cache
		)
	"		    
    }
}


ad_proc im_audit_project_eva_diagram {
    -project_id
    { -name "" }
    { -histogram_values {} }
    { -diagram_width 300 }
    { -diagram_height 200 }
    { -font_color "000000" }
    { -diagram_color "0080FF" }
    { -dot_size 4 }
    { -font_size 8 }
    { -font_style "font-family:Verdana;font-weight:normal;line-height:10pt;font-size:8pt;" }
    { -bar_color "0080FF" }
    { -outer_distance 2 }
    { -left_distance 35 }
    { -bottom_distance 20 }
    { -widget_bins 5 }
} {
    Returns a formatted HTML text to display a timeline of dots
    based on Lutz Tautenhahn' "Javascript Diagram Builder", v3.3.
    @param values Contains a list of "element" lists.
} {
    # ------------------------------------------------
    # Constants & Setup

    set date_format "YYYY-MM-DD HH:MI:SS"
    set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
    set target_margin_percentage [ad_parameter -package_id [im_package_cost_id] "TargetMarginPercentage" "" "30.0"]
    db_1row project_info "
	select	project_name,
		parent_id,
		to_char(now(), :date_format) as today
	from	im_projects
	where	project_id = :project_id
    "

    # Don't show the component for sub-projects
    if {"" != $parent_id} { return "" }

    # Use the project name as name if not specified
    if {"" == $name} { set name $project_name }

    # The diagram name: Every diagram needs a unique identified,
    # so that multiple diagrams can be shown on a single HTML page.
    set oname "D[expr round(rand()*1000000000.0)]"


    # ------------------------------------------------
    # Check for values that are always zero. We just let the DB calculate the sum...
    db_1row start_end "
	select
		sum(project_budget) as project_budget_sum,
		sum(cost_timesheet_logged_cache) as cost_timesheet_logged_cache_sum,
		sum(cost_bills_cache) as cost_bills_cache_sum,
		sum(cost_expense_logged_cache) as cost_expense_logged_cache_sum,
		sum(cost_invoices_cache) as cost_invoices_cache_sum,
		sum(cost_quotes_cache) as cost_quotes_cache_sum,
		sum(cost_delivery_notes_cache) as cost_delivery_notes_cache_sum
        from    im_projects_audit
        where   project_id = :project_id
    "

    # ------------------------------------------------
    # Extract boundaries of the diagram: first and last date, maximum of the various values
    db_1row start_end "
	select  to_char(min(last_modified), :date_format) as first_date,
		to_char(max(last_modified), :date_format) as last_date,
		max(trunc((project_budget * im_exchange_rate(start_date::date, project_budget_currency, :default_currency))::numeric, 2)) as project_budget_max,
		-- The cost side - thee different types - ts, bills and expenses
		max(cost_timesheet_logged_cache) as cost_timesheet_logged_cache_max,
		max(cost_bills_cache) as cost_bills_cache_max,
		max(cost_expense_logged_cache) as cost_expense_logged_cache_max,
		-- The income side - quotes and invoices
		max(cost_invoices_cache) as cost_invoices_cache_max,
		max(cost_quotes_cache) as cost_quotes_cache_max,
		-- Delivered value
		max(cost_delivery_notes_cache) as cost_delivery_notes_cache_max
        from    im_projects_audit
        where   project_id = :project_id
    "

    if {"" == $project_budget_max} { set project_budget_max 0 }
    if {"" == $cost_timesheet_logged_cache_max} { set cost_timesheet_logged_cache_max 0 }
    if {"" == $cost_bills_cache_max} { set cost_bills_cache_max 0 }
    if {"" == $cost_expense_logged_cache_max} { set cost_expense_logged_cache_max 0 }
    if {"" == $cost_invoices_cache_max} { set cost_invoices_cache_max 0 }
    if {"" == $cost_quotes_cache_max} { set cost_quotes_cache_max 0 }
    if {"" == $cost_delivery_notes_cache_max} { set cost_delivery_notes_cache_max 0 }

    regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $first_date match year0 month0 day0 hour0 min0 sec0
    regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $last_date match year9 month9 day9 hour9 min9 sec9

    set cost_max [expr $cost_timesheet_logged_cache_max + $cost_bills_cache_max + $cost_expense_logged_cache_max]
    set widget_max $cost_max
    if {$project_budget_max > $widget_max} { set widget_max $project_budget_max}
    if {$cost_invoices_cache_max > $widget_max} { set widget_max $cost_invoices_cache_max }
    if {$cost_quotes_cache_max > $widget_max} { set widget_max $cost_quotes_cache_max }
    if {100.0 > $widget_max} { set widget_max 100.0}
    set widget_max [expr $widget_max * 1.01]
    set widget_min [expr $widget_max * -0.01]

    # ------------------------------------------------
    # Define the SQL to select the information from im_projects_audit
    set sql "
	select	*,
		to_char(last_modified, 'YYYY-MM-DD HH:MI:SS') as date,
		trunc((project_budget * im_exchange_rate(start_date::date, project_budget_currency, :default_currency))::numeric, 2) as project_budget_converted
	from	im_projects_audit pa
	where	project_id = :project_id
	order by
		last_modified
    "

    # ------------------------------------------------
    # Setup the parameters for every line to be drawn: Color, title, type of display

    set blue1 "00FFFF"
    set blue2 "0080FF"
    set blue3 "0000FF"
    set dark_green "408040"
    set dark_green "306030"
    set orange1 "FF8000"
    set orange2 "fecd00"
    set keys {
	date done budget
	expenses expenses_bills expenses_bills_ts
	quotes invoices
    }
    set titles { 
	"Date" "%Done" "Budget" 
	"Expenses" "Expenses+Bills" "Expenses+Bills+TS" 
	"Quotes" "Invoices"
    }
    set colors [list \
	"black" $dark_green "red" \
	$blue1 $blue2 $blue3 \
	$orange1 $orange2 \
    ]
    set show_bar_ps {
	0 0 0
	1 1 1
	0 0
    }
    set sums [list \
	1 1 $project_budget_sum \
	$cost_expense_logged_cache_sum \
	[expr $cost_expense_logged_cache_sum + $cost_bills_cache_sum] \
	[expr $cost_expense_logged_cache_sum + $cost_bills_cache_sum + $cost_timesheet_logged_cache_sum] \
	$cost_quotes_cache_sum $cost_invoices_cache_sum \
    ]

    for {set k 0} {$k < [llength $keys]} {incr k} {
	set key [lindex $keys $k]
	set title [lindex $titles $k]
	set title_hash($key) $title
	set show_bar_p [lindex $show_bar_ps $k]
	set show_bar_hash($key) $show_bar_p
	set sum [lindex $sums $k]
	set sum_hash($key) $sum
	set color [lindex $colors $k]
	set color_hash($key) $color
    }

    # ------------------------------------------------
    # Rename the cost titles if the lower ones are 0
    if {0.0 == $sum_hash(expenses)} {
	set title_hash(expenses_bills) "Bills"
	set title_hash(expenses_bills_ts) "Bills+Timesheet"
    }
    if {0.0 == $sum_hash(expenses) && 0.0 == $sum_hash(expenses_bills)} {
	set title_hash(expenses_bills) "Bills"
	set title_hash(expenses_bills_ts) "Timesheet"
    }

    # ------------------------------------------------
    # Loop through all im_projects_audit rows returned
    set last_v [list]
    set last_date $first_date
    set diagram_html ""
    set dup_ctr 0
    db_foreach project_eva $sql {

	# Fix budget as max(quotes, invoices) - target_margin
	if {"" == $cost_invoices_cache} { set cost_invoices_cache 0.0 }
	if {"" == $cost_quotes_cache} { set cost_quotes_cache 0.0 }
	if {"" == $project_budget_converted} {
	    if {$cost_quotes_cache > $cost_invoices_cache} {
set project_budget_converted [expr $cost_quotes_cache * (100.0 - $target_margin_percentage) / 100.0]
	    } else {
set project_budget_converted [expr $cost_invoices_cache * (100.0 - $target_margin_percentage) / 100.0]
	    }
	}

	regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $date match year month day hour min sec
	regexp {([0-9]*)\-([0-9]*)\-([0-9]*) ([0-9]*)\:([0-9]*)\:([0-9]*)} $last_date match last_year last_month last_day last_hour last_min last_sec

	set val_hash(date) $date
	set val_hash(done) $percent_completed
	set val_hash(budget) $project_budget_converted
	set val_hash(expenses) [expr $cost_expense_logged_cache]
	set val_hash(expenses_bills) [expr $cost_expense_logged_cache + $cost_bills_cache]
	set val_hash(expenses_bills_ts) [expr $cost_expense_logged_cache + $cost_bills_cache + $cost_timesheet_logged_cache]
	set val_hash(quotes) $cost_quotes_cache
	set val_hash(invoices) $cost_invoices_cache

	# Deal with the very first iteration.
        if {"" == [array get last_val_hash]} { array set last_val_hash [array get val_hash] }

	# Check if we got duplicates. In this case we skip the current
	# value set and wait until the next one is different.
	set date_day "$year-$month-$day"
	set last_date_day "$last_year-$last_month-$last_day"
	if {$date_day == $last_date_day && [lsort [array get val_hash]] == [lsort [array get last_val_hash]]} { 
	    incr dup_ctr
	    continue 
	}

	# Draw lines in specific order. Values drawn later will overwrite lines drawn earlier
	foreach key {expenses_bills_ts expenses_bills expenses done budget quotes invoices} {

	    # if {"" == $val_hash($key)} { continue }
	    set val [expr round(10.0 * $val_hash($key)) / 10.0]
	    set last_val [expr round(10.0 * $last_val_hash($key)) / 10.0]
	    set color $color_hash($key)
	    set title $title_hash($key)
	    set sum $sum_hash($key)
	    set show_bar_p $show_bar_hash($key)

	    if {0.0 == $sum} { continue }
	    set dot_title "$title - $val $default_currency"
	    set bar_tooltip_text "$title = $val $default_currency"
	    
	    # Show %Done as % of widget_max, not as absolute number
	    if {"done" == $key} { 
		set dot_title "$title - $val %"
		set val [expr ($val / 100.0) * $widget_max] 
		set last_val [expr 0.01 * $last_val * $widget_max] 
	    }

	    append diagram_html "
		var x = $oname.ScreenX(Date.UTC($year, $month, $day, $hour, $min, $sec));
		var last_x = $oname.ScreenX(Date.UTC($last_year, $last_month, $last_day, $last_hour, $last_min, $last_sec));
		var y = $oname.ScreenY($val);
		var last_y = $oname.ScreenY($last_val);
		new Line(last_x, last_y, x, y, \"#$color\", 1, \"$dot_title\");
		new Dot(x, y, $dot_size, 3, \"#$color\", \"$dot_title\");
	    "

	    if {$show_bar_p} {
		append diagram_html "
		new Bar(last_x, y, x, $oname.ScreenY(0), \"\#$color\", \"\", \"#000000\", \"$bar_tooltip_text\");
		"
	    }

	}
	array set last_val_hash [array get val_hash]
	set last_date $date
    }

    set y_grid_delta [expr ($widget_max - $widget_min) / $widget_bins]
    set y_grid_delta [im_diagram_round_to_next_nice_number $y_grid_delta]

    set border "border:1px solid blue; "
    set border ""

    set diagram_html "
	<div style='$border position:relative;top:0px;height:${diagram_height}px;width:${diagram_width}px;'>
	<SCRIPT Language=JavaScript>
	document.open();
	var $oname=new Diagram();

	$oname.Font=\"$font_style\";
	_BFont=\"$font_style\";

	$oname.SetFrame(
		$outer_distance + $left_distance, $outer_distance, 
		$diagram_width - $outer_distance, $diagram_height - $outer_distance - $bottom_distance
	);
	$oname.SetBorder(
		Date.UTC($year0, $month0, $day0, $hour0, $min0, $sec0),
		Date.UTC($year9, $month9, $day9, $hour9, $min9, $sec9),
		$widget_min, $widget_max
	);
	$oname.XScale=4;
	$oname.YScale=1;

	$oname.GetXGrid();
	$oname.XGridDelta=$oname.XGrid\[1\];
	$oname.YGridDelta=$y_grid_delta;

	$oname.Draw(\"\", \"$diagram_color\", false);
	$oname.SetText(\"\",\"\", \"<B>$name</B>\");
	$diagram_html
	document.close();
	</SCRIPT>
	</div>
    "

    set legend_html ""
    foreach key {quotes invoices budget done expenses_bills_ts expenses_bills expenses} {
	set color $color_hash($key)
	set title $title_hash($key)
	set sum $sum_hash($key)
	if {0.0 == $sum} { continue }
	set url "http://www.project-open.org/documentation/portlet_intranet_reporting_dashboard_earned_value"
	set alt [lang::message::lookup "" intranet-reporting-dashboard.Click_for_help "Please click on the link for help about the value shown"]
	append legend_html "
		<nobr><a href=\"$url\" target=\"_blank\">
		<font color=\"#$color\">$title</font>
		</a></nobr>
		<br>
	"
    }

    return "
	<table>
	<tr>
	<td>
		$diagram_html
	</td>
	<td>
		<table border=1>
		<tr><td>
		$legend_html
		</td></tr>
		</table>
	</td>
	</tr>
	<tr><td colspan=2>
	[lang::message::lookup "" intranet-reporting-dashboard.Project_EVA_Help "For help please hold your mouse over the diagram or click on the legend links."]
	</td></tr>
	</table>
    "
}


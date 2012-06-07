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
    set return_url [im_url_with_query]

    set object_found_p [db_0or1row audit_object_info "
	select	o.*
	from	acs_objects o
	where	o.object_id = :object_id
    "]
    if {!$object_found_p} {
	ns_log Error "im_audit_component: Didn't find object #$object_id"
	return ""
    }

    set attribute_l10n [lang::message::lookup "" intranet-core.Attribute Attribute]
    set value_l10n [lang::message::lookup "" intranet-core.Value Value]

    # Define how the data should be rendered on the screen
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
	    audit_diff_pretty {
		label "[lang::message::lookup {} intranet-audit.Diff {Diff}]"
	        display_template {
		    @audit_multirow.audit_diff_pretty;noquote@
		}
	    }
	}    

    # ----------------------------------------------------------------
    # Prepare data

    # Initialize the hash with pretty names with some static values
    array set pretty_name_hash [im_audit_attribute_pretty_names -object_type $object_type]
    array set ignore_hash [im_audit_attribute_ignore -object_type $object_type]
    array set deref_hash [im_audit_attribute_deref -object_type $object_type]

    # ----------------------------------------------------------------
    # Get the data from im_audits and write out a "multirow" with the data
    set audit_sql "
	select	*,
		to_char(audit_date, 'YYYY-MM-DD HH24:MI:SS') as audit_date_pretty,
		im_category_from_id(audit_object_status_id) as audit_object_status,
		im_initials_from_user_id(audit_user_id) as audit_user_initials,
		im_name_from_user_id(audit_user_id) as audit_user_name
	from	im_audits
	where	audit_object_id = :object_id and
		audit_date > :creation_date::timestamptz + '5 second'::interval -- ignore initial audit
	order by audit_id DESC
    "
    
    set cnt 0
    db_multirow -extend { audit_details_url audit_user_url audit_ip_url audit_action_gif audit_diff_pretty } audit_multirow audit_list $audit_sql {
	set audit_details_url [export_vars -base "/intranet-audit/view" {audit_id return_url}]
	set audit_user_url [export_vars -base "/intranet/users/view" {{user_id $audit_user_id}}]
	set audit_ip_url ""

	switch $audit_action {
	    create 		{ set audit_action_abbrev "c" }
	    before_create	{ set audit_action_abbrev "c" }
	    after_create	{ set audit_action_abbrev "c" }
	    update		{ set audit_action_abbrev "u" }
	    before_update	{ set audit_action_abbrev "u" }
	    after_update	{ set audit_action_abbrev "u" }
	    delete		{ set audit_action_abbrev "d" }
	    nuke		{ set audit_action_abbrev "n" }
	    before_nuke		{ set audit_action_abbrev "n" }
	    after_nuke		{ set audit_action_abbrev "n" }
	    default		{ set audit_action_abbrev "cog" }
	}
	set audit_action_msg [lang::message::lookup "" intranet-audit.Action_${audit_action}_help $audit_action]
	set audit_action_gif [im_gif $audit_action_abbrev $audit_action_msg]

	# Prettyfy the audit_diff.
	# Go through values and dereference them.
	set audit_diff_pretty ""
	foreach field [split $audit_diff "\n"] {
	    set attribute_name [lindex $field 0]
	    set attribute_value [lrange $field 1 end]

	    if {[regexp {^acs_rel} $attribute_name match]} { 
		catch {
		    set attribute_value [im_audit_format_rel_value -object_id $object_id -value $attribute_value]
		}
	    }

	    # Should we ignore this field?
	    if {[info exists ignore_hash($attribute_name)]} { continue }

	    # Determine the pretty_name for the field
	    set pretty_name $attribute_name
	    if {[info exists pretty_name_hash($attribute_name)]} { set pretty_name $pretty_name_hash($attribute_name) }

	    # Determine the pretty_value for the field
	    set pretty_value $attribute_value

	    # Apply the dereferencing function if available
	    # This function will pull out the object name for an ID
	    # or the category for a category_id
	    if {[info exists deref_hash($attribute_name)]} { 
		set deref_function $deref_hash($attribute_name)
		set pretty_value [db_string deref "select ${deref_function}(:attribute_value)"]
	    }

	    # Skip the field if the attribute_name is empty.
	    # This could be the last line of the audit_diff or audit_value field
	    if {"" == $attribute_name} { continue }

	    if {"" != $audit_diff_pretty} { append audit_diff_pretty ",\n<br>" }
	    append audit_diff_pretty "$pretty_name = $pretty_value"
	}

	# Skip the entire line if it's empty.
	if {"" == $audit_diff_pretty} { continue }

	incr cnt
    }

    # Compile and execute the listtemplate
    eval [template::adp_compile -string {<listtemplate name="audit_list"></listtemplate>}]
    set list_html $__adp_output

    return $list_html
}


ad_proc -public im_audit_format_rel_value {
    -object_id:required
    -value:required
} {
    Returns a formatted pretty string representing a relationship
} {
    ns_log Notice "im_audit_format_rel_value: object_id=$object_id, value='$value'"
    array set rel_hash $value

    set object_id_one ""
    if {[info exists rel_hash(object_id_one)]} { 
	set object_id_one $rel_hash(object_id_one) 
	unset rel_hash(object_id_one)
    }

    set object_id_two ""
    if {[info exists rel_hash(object_id_two)]} { 
	set object_id_two $rel_hash(object_id_two) 
	unset rel_hash(object_id_two)
    }

    set rel_type ""
    if {[info exists rel_hash(rel_type)]} { 
	set rel_type $rel_hash(rel_type) 
	unset rel_hash(rel_type)
    }

    if {$object_id_one == $object_id} {
	set arrow [im_gif arrow_left]
	set other_object_id $object_id_two
    } else {
	set arrow [im_gif arrow_right]
	set other_object_id $object_id_one
    }

    set other_object_name "undefined"
    if {"" != $other_object_id && [string is integer $other_object_id]} {
        set other_object_name [util_memoize [list db_string object_name "select acs_object__name($other_object_id)"]]
    }
    set result "$rel_type $arrow $other_object_name"
    set list ""
    foreach key [lsort [array names rel_hash]] {
	lappend list "$key $rel_hash($key)"
    }
    return $result
}


ad_proc -public im_audit_attribute_pretty_names {
    -object_type:required
} {
    Returns a key-value list of pretty names for object attributes
} {
    return [im_audit_attribute_pretty_names_helper -object_type $object_type]
    return [util_memoize [list im_audit_attribute_pretty_names_helper -object_type $object_type]]
}


ad_proc -public im_audit_attribute_pretty_names_helper {
    -object_type:required
} {
    Returns a key-value list of pretty names for object attributes
} {
    # Get the list of all define DynField names
    set dynfield_sql "
	select	*
	from	acs_attributes aa,
		im_dynfield_attributes da
	where	aa.attribute_id = da.acs_attribute_id and
		aa.object_type = :object_type
    "
    db_foreach dynfields $dynfield_sql {
	set pretty_name_hash($attribute_name) $pretty_name
    }

    set pretty_name_hash(project_id) [lang::message::lookup "" intranet-core.Project_ID "Project ID"]
    set pretty_name_hash(project_name) [lang::message::lookup "" intranet-core.Project_Name "Project Name"]
    set pretty_name_hash(project_nr) [lang::message::lookup "" intranet-core.Project_Nr "Project Nr"]
    set pretty_name_hash(project_path) [lang::message::lookup "" intranet-core.Project_Path "Project Path"]
    set pretty_name_hash(project_type_id) [lang::message::lookup "" intranet-core.Project_Type "Project Type"]
    set pretty_name_hash(project_status_id) [lang::message::lookup "" intranet-core.Project_Status "Project Status"]
    set pretty_name_hash(project_lead_id) [lang::message::lookup "" intranet-core.Project_Manager "Project Manager"]
    
    # Project standard fields
    set pretty_name_hash(start_date) [lang::message::lookup "" intranet-core.Start_Date "Start Date"]
    set pretty_name_hash(end_date) [lang::message::lookup "" intranet-core.End_Date "End Date"]
    set pretty_name_hash(description) [lang::message::lookup "" intranet-core.Description "Description"]
    set pretty_name_hash(note) [lang::message::lookup "" intranet-core.Note "Note"]
    set pretty_name_hash(parent_id) [lang::message::lookup "" intranet-core.Parent_ID "Parent"]
    set pretty_name_hash(company_id) [lang::message::lookup "" intranet-core.Company_ID "Company"]
    set pretty_name_hash(template_p) [lang::message::lookup "" intranet-core.Template_p "Template?"]
    
    # Project Cost Cache
    set pretty_name_hash(cost_bills_cache) [lang::message::lookup "" intranet-core.Cost_Bills_Cache "Bills Cache"]
    set pretty_name_hash(cost_delivery_notes_cache) [lang::message::lookup "" intranet-core.Cost_Delivery_Notes_Cache "Delivery Notes Cache"]
    set pretty_name_hash(cost_expenses_logged_cache) [lang::message::lookup "" intranet-core.Cost_Expenses_Logged_Cache "Expenses Logged Cache"]
    set pretty_name_hash(cost_expenses_planned_cache) [lang::message::lookup "" intranet-core.Cost_Expenses_Planned_Cache "Expenses Planned Cache"]
    set pretty_name_hash(cost_invoices_cache) [lang::message::lookup "" intranet-core.Cost_Invoices_Cache "Invoices Cache"]
    set pretty_name_hash(cost_purchase_orders_cache) [lang::message::lookup "" intranet-core.Cost_Purchase_Orders_Cache "Purchase Orders Cache"]
    set pretty_name_hash(cost_quotes_cache) [lang::message::lookup "" intranet-core.Cost_Quotes_Cache "Quotes Cache"]
    set pretty_name_hash(cost_timesheet_logged_cache) [lang::message::lookup "" intranet-core.Cost_Timesheet_Logged_Cache "Timesheet Logged Cache"]
    set pretty_name_hash(cost_timesheet_planned_cache) [lang::message::lookup "" intranet-core.Cost_Timesheet_Planned_Cache "Timesheet Planned Cache"]
    set pretty_name_hash(reported_days_cache) [lang::message::lookup "" intranet-core.Cost_Reported_Days_Cache "Reported Days Cache"]
    set pretty_name_hash(reported_hours_cache) [lang::message::lookup "" intranet-core.Cost_Reported_Days_Cache "Reported Days Cache"]


    # Ticket fields
    set pretty_name_hash(ticket_done_date) [lang::message::lookup "" intranet-helpdesk.Ticket_Done_Date "Ticket Done Date"]
    set pretty_name_hash(ticket_creation_date) [lang::message::lookup "" intranet-helpdesk.Ticket_Creation_Date "Ticket Creation Date"]
    set pretty_name_hash(ticket_alarm_date) [lang::message::lookup "" intranet-helpdesk.Ticket_Alarm_Date "Ticket Alarm Date"]
    set pretty_name_hash(ticket_reaction_date) [lang::message::lookup "" intranet-helpdesk.Ticket_Reaction_Date "Ticket Reaction Date"]
    set pretty_name_hash(ticket_confirmation_date) [lang::message::lookup "" intranet-helpdesk.Ticket_Confirmation_Date "Ticket Confirmation Date"]
    set pretty_name_hash(ticket_signoff_date) [lang::message::lookup "" intranet-helpdesk.Ticket_Signoff_Date "Ticket Signoff Date"]

    return [array get pretty_name_hash]
}




ad_proc -public im_audit_attribute_ignore {
    -object_type:required
} {
    Returns a hash of attributes to be ignored in the audit package
} {
#    return [util_memoize [list im_audit_attribute_ignore_helper -object_type $object_type]]
    return [im_audit_attribute_ignore_helper -object_type $object_type]
}


ad_proc -public im_audit_attribute_ignore_helper {
    -object_type:required
} {
    Returns a hash of attributes to be ignored in the audit package
} {
    # Project Cost Cache (automatically updated)
    set ignore_hash(cost_bills_cache) 1
    set ignore_hash(cost_delivery_notes_cache) 1
    set ignore_hash(cost_expense_logged_cache) 1
    set ignore_hash(cost_expense_planned_cache) 1
    set ignore_hash(cost_invoices_cache) 1
    set ignore_hash(cost_purchase_orders_cache) 1
    set ignore_hash(cost_quotes_cache) 1
    set ignore_hash(cost_timesheet_logged_cache) 1
    set ignore_hash(cost_timesheet_planned_cache) 1

    set ignore_hash(reported_days_cache) 1
    set ignore_hash(reported_hours_cache) 1
    set ignore_hash(cost_cache_dirty) 1

    # Obsolete project fields
    set ignore_hash(corporate_sponsor) 1
    set ignore_hash(percent_completed) 1
    set ignore_hash(requires_report_p) 1
    set ignore_hash(supervisor_id) 1
    set ignore_hash(team_size) 1
    set ignore_hash(trans_project_hours) 1
    set ignore_hash(trans_project_words) 1
    set ignore_hash(trans_size) 1


    # Ticket automatically updated fields
    set ignore_hash(ticket_resolution_time) 1
    set ignore_hash(ticket_resolution_time_per_queue) 1
    set ignore_hash(ticket_resolution_time_dirty) 1

    return [array get ignore_hash]
}





ad_proc -public im_audit_attribute_deref {
    -object_type:required
} {
    Returns a hash of deref functions for important attributes
} {
#    return [util_memoize [list im_audit_attribute_deref_helper -object_type $object_type]]
    return [im_audit_attribute_deref_helper -object_type $object_type]
}


ad_proc -public im_audit_attribute_deref_helper {
    -object_type:required
} {
    Returns a hash of deref functions for important attributes
} {
    # Get DynField meta-information and write into a hash array
    set dynfield_sql "
	select	aa.attribute_name,
		aa.pretty_name,
		dw.deref_plpgsql_function
	from	acs_attributes aa,
		im_dynfield_attributes da,
		im_dynfield_widgets dw
	where	aa.attribute_id = da.acs_attribute_id and
		da.widget_name = dw.widget_name and
		aa.object_type = :object_type
    "
    db_foreach dynfields $dynfield_sql {
	set deref_hash($attribute_name) $deref_plpgsql_function
    }

    # Manually add a few frequently used deref functions

    set deref_hash(project_id) "acs_object__name"
    set deref_hash(company_id) "acs_object__name"
    set deref_hash(ticket_id) "acs_object__name"

    set deref_hash(status_id) "im_category_from_id"
    set deref_hash(project_status_id) "im_category_from_id"
    set deref_hash(ticket_status_id) "im_category_from_id"
    set deref_hash(type_id) "im_category_from_id"
    set deref_hash(project_type_id) "im_category_from_id"
    set deref_hash(ticket_type_id) "im_category_from_id"

    set deref_hash(ticket_prio_id) "im_category_from_id"
    set deref_hash(ticket_customer_contact_id) "im_name_from_user_id"
    set deref_hash(ticket_assignee_id) "acs_object__name"
    set deref_hash(ticket_queue_id) "acs_object__name"

    return [array get deref_hash]
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
    set froms {}
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


ad_proc -public im_audit_object_rels_sql { 
} {
    Returns the SQL for pulling out all relationships for an object
} {
    ns_log Notice "im_audit_object_rels_sql:"

    # Get the list of all sub relationships, together with their meta-information
    set sub_rel_sql "
	select	aot.*
	from	acs_object_types aot
	where	aot.supertype = 'relationship'
    "
    set outer_joins ""
    db_foreach sub_rels $sub_rel_sql {
	if {![im_table_exists $table_name]} { continue }
	append outer_joins "LEFT OUTER JOIN $table_name ON (r.rel_id = $table_name.$id_column)\n\t\t"
    }

    set sql "
	select	*
	from	acs_rels r
		$outer_joins
	where	(r.object_id_one = :object_id or r.object_id_two = :object_id)
	order by
		r.rel_id
    "

    return $sql
}


ad_proc -public im_audit_object_rels { 
    -object_id:required
} {
    Creates a single string for the object's relationships with other objects.
} {
    ns_log Notice "im_audit_object_rels: object_id=$object_id"

    # Get the SQL for pulling out all rels of an object
    set sql [util_memoize [list im_audit_object_rels_sql]]

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
	ns_log Error "im_audit_object_rels: For some reason we didn't find any record matching sql=$sql"
	return ""
    }

    set result_list ""
    foreach col_values $lol {
	set value_list ""
	for {set i 0} {$i < [llength $col_names]} {incr i} {
	    set var [lindex $col_names $i]
	    set val [lindex $col_values $i]
	    if {"" == $val} { continue }
	    lappend value_list $var $val
	}
	# The result list is an "array" type of key-value list.
	lappend result_list [join $value_list " "]
    }

    return $result_list
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
    if {"" == $object_type} {
	ns_log warning "im_audit_object_value -object_id $object_id:  Database inconsistency: found an empty object_type"
	return
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

    # Add information about the object's relationships
    set audit_rels_p [parameter::get_from_package_key \
		-package_key intranet-audit \
		-parameter AuditObjectRelationshipsP \
		-default 1 \
    ]
    if {$audit_rels_p} {
	foreach rel_record [im_audit_object_rels -object_id $object_id] {
	    array unset rel_hash
	    array set rel_hash $rel_record
	    set rel_id $rel_hash(rel_id)
	    unset rel_hash(rel_id)
	    set list ""
	    foreach key [lsort [array names rel_hash]] {
		lappend list "$key $rel_hash($key)"
	    }
	    append value "acs_rel-$rel_id	[join $list " "]\n"
	}
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
    {-baseline_id "" }
    {-user_id "" }
    {-object_type "" }
    {-status_id "" }
    {-type_id "" }
    {-action "after_update" }
    {-comment "" }
} {
    Creates a new audit item for object after an update.
    @param baseline_id A baseline is a version of a project.
           baseline_id != "" means that we have to write a new version.
	   The baseline_id is stored in im_projects_audit.baseline_id,
	   because baselines always refer to projects.
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

    set new_audit_id ""
    if {"" != $diff || "" != $baseline_id} {
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

	if {"" == $baseline_id} {
	    # Update the last_audit_id ONLY if this was not a baseline.
	    # Baselines can be deleted, and the foreign key constraint
	    # would give trouble with that.
	    db_dml update_object "
		update acs_objects set
			last_audit_id = :new_audit_id,
			last_modified = now(),
			modifying_user = :user_id,
			modifying_ip = :peeraddr
		where object_id = :object_id
	    "
	}

    }

    return $new_audit_id
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

	if {0 == $interval_hours} { set interval_hours 24 }

	# Select all "active" (=not deleted or canceled) main projects
	# without an update in the last X hours
	set project_sql "
	select	project_id
	from	im_projects
	where	parent_id is null and
		project_status_id not in ([im_project_status_deleted]) and
		project_id not in (
			select	distinct project_id
			from	im_projects_audit
			where	last_modified > (now() - '$interval_hours hours'::interval)
		)
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
    {-baseline_id "" }
    {-user_id "" }
    {-object_type "" }
    {-status_id "" }
    {-type_id "" }
    {-action after_update }
    {-comment "" }
} {
    Additional(!) functionality when auditing a project.
    Writes a record to im_projects_audit.
    @param baseline_id A Baseline is a version of the project.
} {
    ns_log Notice "im_project_audit_impl: project_id=$project_id, user_id=$user_id, baseline_id=$baseline_id"
    if {"" == $user_id} { set user_id [ad_get_user_id] }

    # No audit for non-existing projects
    if {"" == $project_id} { 
	ns_log Notice "im_project_audit_impl: project_id is empty" 
	return ""
    }
    if {0 == $project_id} { 
	ns_log Notice "im_project_audit_impl: project_id = 0"
	return ""
    }

    # Make sure the table exists (compatibility)
    set audit_exists_p [im_table_exists im_projects_audit]
    if {!$audit_exists_p} { 
	ns_log Notice "im_project_audit_impl: Audit table doesn't exist" 
	return ""
    }

    # Parameter to enable/disable project audit
    set audit_projects_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "AuditProjectsP" -default 1]
    if {!$audit_projects_p} { 
	ns_log Notice "im_project_audit_impl: Audit not enabled"
	return ""
    }

    # Who is modifying? Use empty values when called from schedules proc sweeper
    set peeraddr "0.0.0.0"
    catch { set peeraddr [ad_conn peeraddr] }
    set modifying_user $user_id
    set modifying_ip $peeraddr

    # Write a generic audit record
    set audit_id [im_audit_impl \
                -user_id $user_id \
                -object_id $project_id \
                -object_type $object_type \
		-baseline_id $baseline_id \
                -action $action \
                -comment $comment \
    ]

    # Add a baseline_id if specified.
    if {"" != $baseline_id && [im_column_exists im_projects_audit baseline_id]} {
	set baseline_var_sql ",baseline_id"
	set baseline_val_sql ",:baseline_id as baseline_id"
    } else {
	set baseline_var_sql ""
	set baseline_val_sql ""
    }

    ns_log Notice "im_project_audit_impl: About to write im_projects_audit log"
    if {[catch {
	db_dml audit_insert "
	    insert into im_projects_audit (
		modifying_action,	audit_id,
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
		$baseline_var_sql
	    ) 
	    select
		:action,		:audit_id,
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
		$baseline_val_sql
	    from	im_projects
	    where	project_id = :project_id
        "
    } err_msg]} {
	ns_log Error "im_project_audit_impl: Error creating an im_projects_audit entry: $err_msg"
	ad_return_complaint 1 "im_project_audit_impl: Error creating an im_projects_audit entry:<br><pre>$err_msg</pre>"
	
    }
    ns_log Notice "im_project_audit_impl: After writing im_projects_audit log"

    return $err_msg
}


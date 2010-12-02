# /packages/intranet-helpdesk/www/ticket-select.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Shows a list of "Problem tickets" to which we can related the
    current "Incident Ticket".
    @author frank.bergmann@project-open.com
} {
    { tid:integer,multiple {} }
    { ticket_ids {} }
    { action_id:integer "" }
    { return_url "/intranet-helpdesk/index" }

    { order_by "Creation Date" }
    { mine_p "all" }
    { ticket_status_id:integer "[im_ticket_status_open]" } 
    { ticket_type_id:integer "[im_ticket_type_problem_ticket]" } 
    { ticket_queue_id:integer 0 } 
    { customer_id:integer 0 } 
    { customer_contact_id:integer 0 } 
    { assignee_id:integer 0 } 
    { letter:trim "" }
    { start_idx:integer 0 }
    { how_many "" }
    { view_name "ticket_list_duplicates" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-helpdesk.Select_a_base_for_the_Duplicated_Ticket "Please Select a Base for the Duplicated Ticket"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set letter [string toupper $letter]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]


if { {} != $ticket_ids} {
    set tid $ticket_ids
}
# ad_return_complaint 1 "l=[llength $ticket_ids], tid=$tid, ticket_ids=$ticket_ids"


# Unprivileged users can only see their own tickets
if {"all" == $mine_p && ![im_permission $current_user_id "view_tickets_all"]} {
    set mine_p "queue"
}

if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage  "" 50]
}
set end_idx [expr $start_idx + $how_many]

# ---------------------------------------------------------------
# Defined Table Fields
# ---------------------------------------------------------------

# Define the column headers and column contents that 
# we want to show:
#
set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
if {!$view_id } {
    ad_return_complaint 1 "<b>Unknown View Name</b>:<br> The view '$view_name' is not defined.<br> 
    Maybe you need to upgrade the database. <br> Please notify your system administrator."
    return
}


# ---------------------------------------------------------------
# Format the List Table Header
# ---------------------------------------------------------------

set column_headers [list]
set column_vars [list]
set extra_selects [list]
set extra_froms [list]
set extra_wheres [list]
set view_order_by_clause ""

set table_header_html "<tr>\n"
set column_sql "
	select	vc.*
	from	im_view_columns vc
	where	view_id=:view_id
		and group_id is null
	order by sort_order
"
db_foreach column_list_sql $column_sql {
    if {"" == $visible_for || [eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"
	if {"" != $extra_select} { lappend extra_selects $extra_select }
	if {"" != $extra_from} { lappend extra_froms $extra_from }
	if {"" != $extra_where} { lappend extra_wheres $extra_where }
	if {"" != $order_by_clause &&
	    $order_by==$column_name} {
	    set view_order_by_clause $order_by_clause
	}

	# Build the column header
	regsub -all " " $column_name "_" col_txt
	set col_txt [lang::message::lookup "" intranet-helpdesk.$col_txt $column_name]
	set col_url [export_vars -base "index" {{order_by $column_name}}]
	
	set admin_link "<a href=[export_vars -base "/intranet/admin/views/new-column" {return_url column_id {form_mode edit}}]>[im_gif wrench]</a>"

	if {!$user_is_admin_p} { set admin_link "" }
	
	if { [string compare $order_by $column_name] == 0} {
	    append table_header_html "<td class=rowtitle>$col_txt$admin_link</td>\n"
	} else {
	    append table_header_html "<td class=rowtitle><a href=\"$col_url\">$col_txt</a>$admin_link</td>\n"
	}
    }
}
append table_header_html "</tr>\n"


# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]

# ---------------------------------------------------------------
# Filter with Dynamic Fields
# ---------------------------------------------------------------

set form_id "ticket_filter"
set object_type "im_ticket"
set action_url "/intranet-helpdesk/ticket-select"
set form_mode "edit"

set mine_p_options {}
if {[im_permission $current_user_id "view_tickets_all"]} { 
    lappend mine_p_options [list [lang::message::lookup "" intranet-helpdesk.All "All"] "all" ] 
}
lappend mine_p_options [list [lang::message::lookup "" intranet-helpdesk.My_queues "My Queues"] "queue"]
lappend mine_p_options [list [lang::message::lookup "" intranet-helpdesk.Mine "Mine"] "mine"]

set ticket_member_options [util_memoize "db_list_of_lists ticket_members {
	select  distinct
		im_name_from_user_id(object_id_two) as user_name,
		object_id_two as user_id
	from    acs_rels r,
		im_tickets p
	where   r.object_id_one = p.ticket_id
	order by user_name
}" 300]
set ticket_member_options [linsert $ticket_member_options 0 [list [_ intranet-core.All] ""]]

set ticket_queue_options [im_helpdesk_ticket_queue_options]
set ticket_sla_options [im_helpdesk_ticket_sla_options -include_create_sla_p 1 -include_empty_p 1]

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export {start_idx order_by how_many view_name letter action_id return_url ticket_ids} \
    -form {
    	{mine_p:text(select),optional {label "Mine/All"} {options $mine_p_options }}
    }

if {[im_permission $current_user_id "view_tickets_all"]} {  
    ad_form -extend -name $form_id -form {
	{ticket_status_id:text(im_category_tree),optional {label "[lang::message::lookup {} intranet-helpdesk.Status Status]"} {custom {category_type "Intranet Ticket Status" translate_p 1}} }
	{ticket_type_id:text(im_category_tree),optional {label "[lang::message::lookup {} intranet-helpdesk.Type Type]"} {custom {category_type "Intranet Ticket Type" translate_p 1} } }
	{ticket_queue_id:text(select),optional {label "[lang::message::lookup {} intranet-helpdesk.Queue Queue]"} {options $ticket_queue_options}}
	{ticket_sla_id:text(select),optional {label "[lang::message::lookup {} intranet-helpdesk.SLA SLA]"} {options $ticket_sla_options}}
    }

    template::element::set_value $form_id ticket_status_id $ticket_status_id
    template::element::set_value $form_id ticket_type_id $ticket_type_id
    template::element::set_value $form_id ticket_queue_id $ticket_queue_id
}

template::element::set_value $form_id mine_p $mine_p

im_dynfield::append_attributes_to_form \
    -object_type $object_type \
    -form_id $form_id \
    -object_id 0 \
    -advanced_filter_p 1 \
    -search_p 1

# Set the form values from the HTTP form variable frame
im_dynfield::set_form_values_from_http -form_id $form_id
im_dynfield::set_local_form_vars_from_http -form_id $form_id
array set extra_sql_array [im_dynfield::search_sql_criteria_from_form \
			       -form_id $form_id \
			       -object_type $object_type
]

#ToDo: Export the extra DynField variables into form's "export" variable list

# ---------------------------------------------------------------
# Generate SQL Query
# ---------------------------------------------------------------

set criteria [list]
if { ![empty_string_p $ticket_status_id] && $ticket_status_id > 0 } {
    lappend criteria "t.ticket_status_id in ([join [im_sub_categories $ticket_status_id] ","])"
}
if { ![empty_string_p $ticket_type_id] && $ticket_type_id != 0 } {
    lappend criteria "t.ticket_type_id in ([join [im_sub_categories $ticket_type_id] ","])"
}
if { ![empty_string_p $ticket_queue_id] && $ticket_queue_id != 0 } {
    lappend criteria "t.ticket_queue_id = :ticket_queue_id"
}
if {0 != $assignee_id && "" != $assignee_id} {
    lappend criteria "t.ticket_assignee_id = :assignee_id"
}
if { ![empty_string_p $customer_id] && $customer_id != 0 } {
    lappend criteria "p.company_id = :customer_id"
}
if { ![empty_string_p $customer_contact_id] && $customer_contact_id != 0 } {
    lappend criteria "t.ticket_customer_contact_id = :customer_contact_id"
}
if { ![empty_string_p $letter] && [string compare $letter "ALL"] != 0 && [string compare $letter "SCROLL"] != 0 } {
    lappend criteria "im_first_letter_default_to_a(t.ticket_name)=:letter"
}

switch $mine_p {
    "all" { }
    "queue" {
	lappend criteria "(
		t.ticket_assignee_id = :current_user_id 
		OR t.ticket_customer_contact_id = :current_user_id
		OR t.ticket_queue_id in (
			select distinct
				g.group_id
			from	acs_rels r, groups g 
			where	r.object_id_one = g.group_id and
				r.object_id_two = :current_user_id
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
		) OR p.project_id in (	
			-- cases with user as task holding_user
			select distinct wfc.object_id
			from	wf_tasks wft,
				wf_cases wfc
			where	wft.holding_user = :current_user_id and
				wft.state in ('enabled', 'started') and
				wft.case_id = wfc.case_id
		) 
	)"
    }
    "mine" {
	lappend criteria "(
		t.ticket_assignee_id = :current_user_id 
		OR t.ticket_customer_contact_id = :current_user_id
		OR p.project_id in (	
			-- cases with user as task holding_user
			select distinct wfc.object_id
			from	wf_tasks wft,
				wf_cases wfc
			where	wft.state in ('enabled', 'started') and
				wft.case_id = wfc.case_id and
				wft.holding_user = :current_user_id
		)
	)"
    }
    "default" { ad_return_complaint 1 "Error:<br>Invalid variable mine_p = '$mine_p'" }
}

set order_by_clause "order by lower(t.ticket_id) DESC"
switch [string tolower $order_by] {
    "creation date" { set order_by_clause "order by p.start_date DESC" }
    "type" { set order_by_clause "order by ticket_type" }
    "status" { set order_by_clause "order by ticket_status_id" }
    "customer" { set order_by_clause "order by lower(company_name)" }
}

# ---------------------------------------------------------------
#
# ---------------------------------------------------------------

set where_clause [join $criteria " and\n	    "]
set extra_select [join $extra_selects ",\n\t"]
set extra_from [join $extra_froms ",\n\t"]
set extra_where [join $extra_wheres "and\n\t"]

if { ![empty_string_p $where_clause] } { set where_clause " and $where_clause" }
if { ![empty_string_p $extra_select] } { set extra_select ",\n\t$extra_select" }
if { ![empty_string_p $extra_from] } { set extra_from ",\n\t$extra_from" }
if { ![empty_string_p $extra_where] } { set extra_where ",\n\t$extra_where" }


# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

# Create a ns_set with all local variables in order to pass it to the SQL query
set form_vars [ns_set create]
foreach varname [info locals] {

    # Don't consider variables that start with a "_", that
    # contain a ":" or that are array variables:
    if {"_" == [string range $varname 0 0]} { continue }
    if {[regexp {:} $varname]} { continue }
    if {[array exists $varname]} { continue }

    # Get the value of the variable and add to the form_vars set
    set value [expr "\$$varname"]
    ns_set put $form_vars $varname $value
}


# Deal with DynField Vars and add constraint to SQL
# Add the DynField variables to $form_vars
set dynfield_extra_where $extra_sql_array(where)
set ns_set_vars $extra_sql_array(bind_vars)
set tmp_vars [util_list_to_ns_set $ns_set_vars]
set tmp_var_size [ns_set size $tmp_vars]
for {set i 0} {$i < $tmp_var_size} { incr i } {
    set key [ns_set key $tmp_vars $i]
    set value [ns_set get $tmp_vars $key]
    ns_set put $form_vars $key $value
}

# Add the additional condition to the "where_clause"
if {"" != $dynfield_extra_where} {
    append where_clause "
	    and ticket_id in $dynfield_extra_where
    "
}

# ---------------------------------------------------------------
#
# ---------------------------------------------------------------

set sql "
	SELECT
		t.*,
		im_category_from_id(t.ticket_type_id) as ticket_type,
		im_category_from_id(t.ticket_status_id) as ticket_status,
		im_category_from_id(t.ticket_prio_id) as ticket_prio,
		im_name_from_user_id(t.ticket_customer_contact_id) as ticket_customer_contact,
		im_name_from_user_id(t.ticket_assignee_id) as ticket_assignee,
		(select group_name from groups where group_id = ticket_queue_id) as ticket_queue_name,
		p.*,
		to_char(p.start_date, 'YYYY-MM-DD') as start_date_formatted,
		to_char(p.end_date, 'YYYY-MM-DD') as end_date_formatted,
		to_char(t.ticket_alarm_date, 'YYYY-MM-DD') as ticket_alarm_date_formatted,
		ci.*,
		c.company_name,
		sla.project_id as sla_id,
		sla.project_name as sla_name
		$extra_select
	FROM
		im_projects p
		LEFT OUTER JOIN im_projects sla ON (p.parent_id = sla.project_id),
		im_tickets t
		LEFT OUTER JOIN im_conf_items ci ON (t.ticket_conf_item_id = ci.conf_item_id),
		im_companies c
		$extra_from
	WHERE
		p.company_id = c.company_id
		and t.ticket_id = p.project_id
		and p.project_type_id = [im_project_type_ticket]
		and p.project_status_id not in ([join [im_sub_categories [im_project_status_deleted]] ","])
		$where_clause
		$extra_where
	$order_by_clause
"


# ---------------------------------------------------------------
# 5a. Limit the SQL query to MAX rows and provide << and >>
# ---------------------------------------------------------------

if {[string equal $letter "ALL"]} {
    # Set these limits to negative values to deactivate them
    set total_in_limited -1
    set how_many -1
    set selection $sql
} else {
    # We can't get around counting in advance if we want to be able to
    # sort inside the table on the page for only those users in the
    # query results
    set total_in_limited [db_string total_in_limited "
	select count(*)
	from ($sql) s
    "]
    set selection [im_select_row_range $sql $start_idx $end_idx]
}	

# ---------------------------------------------------------------
# Format the Result Data
# ---------------------------------------------------------------

set table_body_html ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0
set idx $start_idx
db_foreach tickets_info_query $selection -bind $form_vars {

    # Append together a line of data based on the "column_vars" parameter list
    set row_html "<tr$bgcolor([expr $ctr % 2])>\n"
    foreach column_var $column_vars {
	append row_html "\t<td valign=top>"
	set cmd "append row_html $column_var"
	eval "$cmd"
	append row_html "</td>\n"
    }
    append row_html "</tr>\n"
    append table_body_html $row_html

    incr ctr
    if { $how_many > 0 && $ctr > $how_many } { break }
    incr idx
}

# Show a reasonable message when there are no result rows:
if { [empty_string_p $table_body_html] } {
    set table_body_html "
	<tr><td colspan=$colspan><ul><li><b>
	[lang::message::lookup "" intranet-core.lt_There_are_currently_n "There are currently no entries matching the selected criteria"]
        </b></ul></td></tr>
    "
}

if { $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr $end_idx + 0]
    set next_page_url "index?start_idx=$next_start_idx&amp;[export_ns_set_vars url [list start_idx]]"
} else {
    set next_page_url ""
}

if { $start_idx > 0 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page_url "index?start_idx=$previous_start_idx&amp;[export_ns_set_vars url [list start_idx]]"
} else {
    set previous_page_url ""
}


# ---------------------------------------------------------------
# Format Table Continuation
# ---------------------------------------------------------------

# Check if there are rows that we decided not to return
# => include a link to go to the next page
#
if {$total_in_limited > 0 && $end_idx < $total_in_limited} {
    set next_start_idx [expr $end_idx + 0]
    set next_page "<a href=index?start_idx=$next_start_idx&amp;[export_ns_set_vars url [list start_idx]]>Next Page</a>"
} else {
    set next_page ""
}

# Check if this is the continuation of a table (we didn't start with the
# first row - there is at least 1 previous row.
# => add a previous page link
#
if { $start_idx > 0 } {
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page "<a href=index?start_idx=$previous_start_idx&amp;[export_ns_set_vars url [list start_idx]]>Previous Page</a>"
} else {
    set previous_page ""
}

set table_continuation_html "
	<tr>
	  <td align=center colspan=$colspan>
	    [im_maybe_insert_link $previous_page $next_page]
	  </td>
	</tr>
"

set table_submit_html "
	<tr>
	  <td align=left colspan=$colspan>
		<input type=submit value='[lang::message::lookup "" intranet-helpdesk.Select "Select"]'>
	  </td>
	</tr>
"





# ---------------------------------------------------------------
# List of tickets to mark as duplicated
# ---------------------------------------------------------------

set bulk_action_list ""
if {![info exists ticket_id]} { set ticket_id 0}

list::create \
    -name duplicated_tickets \
    -multirow duplicated_tickets_multirow \
    -key ticket_id \
    -row_pretty_plural "[lang::message::lookup {} intranet-helpdesk.Duplicated_Tickets "Duplicated Tickets"]" \
    -has_checkboxes \
    -bulk_actions $bulk_action_list \
    -bulk_action_export_vars { ticket_id } \
    -actions [list ] \
    -elements {
	ticket_chk {
	    label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('ticket_list', this.checked)\" 
                          title=\"Check/uncheck all rows\"
			  checked
	    >"
	    display_template {
		@duplicated_tickets_multirow.ticket_chk;noquote@
	    }
	}
	project_nr { 
	    label "Nr" 
	    link_url_col ticket_url
	}
	project_name { 
	    label "Ticket Name"
	    link_url_col ticket_url
	}
    } \
    -orderby {
	ticket_nr {orderby ticket_nr}
	ticket_name {orderby ticket_name}
    }


set duplicated_tickets_sql "
	select
		t.*,
		p.*
	from
		im_tickets t,
		im_projects p
	where
		t.ticket_id = p.project_id and
		t.ticket_id in ([join $tid ","])
	[template::list::orderby_clause -name duplicated_tickets -orderby]
"

db_multirow -extend { ticket_chk ticket_url } duplicated_tickets_multirow duplicated_tickets $duplicated_tickets_sql {
    set ticket_url [export_vars -base "/intranet-helpdesk/new" {ticket_id}]
    set ticket_chk "<input type=\"checkbox\" 
			name=\"tid\" 
			value=\"$ticket_id\" 
			id=\"ticket_list,$ticket_id\"
			checked
		    >
    "
}

# ---------------------------------------------------------------
# Navbars
# ---------------------------------------------------------------

set menu_select_label ""
set ticket_navbar_html [im_project_navbar $letter "/intranet/tickets/index" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter ticket_status_id] $menu_select_label]

eval [template::adp_compile -string {<formtemplate id="ticket_filter"></formtemplate>}]
set filter_html $__adp_output

set left_navbar_html "
      <div class='filter-block'>
         <div class='filter-title'>
            [lang::message::lookup "" intranet-core.Filter_Base_Tickets "Filter Base Tickets"]
         </div>
         $filter_html
      </div>
      <hr/>

"
# /packages/intranet-events/www/index.tcl
#
# Copyright (c) 1998-2008 ]project-open[
# All rights reserved

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author frank.bergmann@event-open.com
} {
    { order_by "date" }
    { mine_p "all" }
    { start_date "" }
    { event_name "" }
    { event_status_id:integer "" } 
    { event_type_id:integer 0 } 
    { event_material_id:integer 0 } 
    { event_location_id:integer 0 } 
    { event_creator_id:integer 0 } 
    { customer_id:integer 0 } 
    { customer_contact_id:integer 0 } 
    { letter:trim "" }
    { start_idx:integer 0 }
    { how_many "" }
    { view_name "event_list" }
    { timescale "next_3w" }
    { report_show_users_p ""}
    { report_show_locations_p ""}
    { report_show_resources_p ""}
    { report_show_event_list_p ""}
    { report_show_all_users_p ""}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-events.Events "Events"]
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set letter [string toupper $letter]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set return_url [im_url_with_query]

set event_name_org $event_name
set event_type_id_org $event_type_id
set event_status_id_org $event_status_id
set event_material_id_org $event_material_id
set event_location_id_org $event_location_id

set next_page_url ""
set previous_page_url ""

# Default start and end of cube
set today [db_string today "select now()::date from dual"]
if {"" == $start_date} {
    set start_date $today
}
if {[regexp {^(....)-(..)-(.)$} $start_date match y m d]} { set start_date "$y-$m-0$d" }
if {[regexp {^(....)-(.)-(..)$} $start_date match y m d]} { set start_date "$y-0$m-$d" }
if {[regexp {^(....)-(.)-(.)$} $start_date match y m d]} { set start_date "$y-0$m-0$d" }

if {[catch {
    set start_date_julian [im_date_ansi_to_julian $start_date]
} err_msg]} {
    ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-events.Invalid_Date_Format "Invalid Data Format"]</b>:<br>
    [lang::message::lookup "" intranet-events.Invalid_Date_Format_Message "Please enter the Start Date in format 'YYYY-MM-DD'"]"
}

# Unprivileged users can only see their own events
set view_events_all_p [im_permission $current_user_id "view_events_all"]
if {"all" == $mine_p && !$view_events_all_p} {
    set mine_p "mine"
}

if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage  "" 50]
}
set end_idx [expr $start_idx + $how_many]

set mine_all_l10n [lang::message::lookup "" intranet-core.Mine_All "Mine/All"]
set all_l10n [lang::message::lookup "" intranet-core.All "All"]
set timescale_l10n [lang::message::lookup "" intranet-events.Timescale "Timescale"]

set show_users_l10n [lang::message::lookup "" intranet-events.Show_Users_P "Show Users?"]
set show_locations_l10n [lang::message::lookup "" intranet-events.Show_Users_P "Show Locations?"]
set show_resources_l10n [lang::message::lookup "" intranet-events.Show_Users_P "Show Resources?"]
set show_event_list_l10n [lang::message::lookup "" intranet-events.Show_Users_P "Show Event List?"]
set show_all_users_l10n [lang::message::lookup "" intranet-events.Show_All_Users_P "Show All Users?"]


# ---------------------------------------------------------------
# Date Scale
# ---------------------------------------------------------------

switch $timescale {
    "next_3w" {
        set report_start_date $start_date
        set report_end_date [im_date_julian_to_ansi [expr $start_date_julian + 21]]
    }
    "last_3w" {
        set report_start_date [im_date_julian_to_ansi [expr $start_date_julian - 21]]
        set report_end_date $start_date
    }
    "past" {
        set report_start_date [db_string future "select min(event_end_date)::date from im_events" -default "2013-01-01"]
        set report_end_date $start_date
    }
    "future" {
        set report_start_date $start_date
        set report_end_date [db_string future "select max(event_end_date)::date from im_events" -default "2020-01-01"]
    }
    "next_3m" {
        set report_start_date $start_date
        set report_end_date [im_date_julian_to_ansi [expr $start_date_julian + 93]]
    }
    "last_3m" {
        set report_start_date [im_date_julian_to_ansi [expr $start_date_julian - 93]]
        set report_end_date $start_date
    }
}

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
set table_header_html ""

set column_sql "
	select	vc.*
	from	im_view_columns vc
	where	view_id = :view_id
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
	set col_txt [lang::message::lookup "" intranet-events.$col_txt $column_name]
	set col_url [export_vars -base "index" {event_id mine_p start_date timescale report_show_users_p report_show_locations_p report_show_resources_p report_show_event_list_p report_show_all_users_p event_name event_creator_id {order_by $column_name}}]

	# Append the DynField values from the Filter as pass-through variables
	# so that sorting won't alter the selected events
	set dynfield_sql "
		select	aa.attribute_name
		from	im_dynfield_attributes a,
			acs_attributes aa
		where	a.acs_attribute_id = aa.attribute_id
			and aa.object_type = 'im_event'
	"
	db_foreach pass_through_vars $dynfield_sql {
	    append col_url "&$attribute_name=[im_opt_val $attribute_name]"
	}

	set admin_link "<a href=[export_vars -base "/intranet/admin/views/new-column" {return_url column_id {form_mode display}}]>[im_gif wrench]</a>"

	if {!$user_is_admin_p} { set admin_link "" }
	set checkbox_p [regexp {<input} $column_name match]
	
	if { [string compare $order_by $column_name] == 0 || $checkbox_p } {
	    append table_header_html "<td class=rowtitle>$col_txt$admin_link</td>\n"
	} else {
	    append table_header_html "<td class=rowtitle><a href=\"$col_url\">$col_txt</a>$admin_link</td>\n"
	}
    }
}
set table_header_html "
	<thead>
	<tr>
	$table_header_html
	</tr>
	</thead>
"


# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]


# ---------------------------------------------------------------
# Filter with Dynamic Fields
# ---------------------------------------------------------------

set dynamic_fields_p 1
set form_id "event_filter"
set object_type "im_event"
set action_url "/intranet-events/index"
set form_mode "edit"

set mine_p_options {}
if {$view_events_all_p} { 
    lappend mine_p_options [list $all_l10n "all" ] 
}
lappend mine_p_options [list [lang::message::lookup "" intranet-events.Mine "Mine"] "mine"]

# Add custom searches to drop-down
if {[im_table_exists im_sql_selectors]} {
    set selector_sql "
	select	s.name, s.short_name
	from	im_sql_selectors s
	where	s.object_type = :object_type
    "
    db_foreach selectors $selector_sql {
	lappend mine_p_options [list $name $short_name]
    }
}


set timescale_types [list \
                         "next_3w" [lang::message::lookup "" intranet-timesheet2.Next_3_Weeks "Next 3 Weeks"] \
                         "next_3m" [lang::message::lookup "" intranet-timesheet2.Next_3_Month "Next 3 Months"] \
                         "future" [lang::message::lookup "" intranet-timesheet2.Future "Future"] \
                         "past" [lang::message::lookup "" intranet-timesheet2.Past "Past"] \
                         "last_3m" [lang::message::lookup "" intranet-timesheet2.Last_3_Month "Last 3 Months"] \
                         "last_3w" [lang::message::lookup "" intranet-timesheet2.Last_3_Weeks "Last 3 Weeks"] \
]
foreach { value text } $timescale_types {
    lappend timescale_options [list $text $value]
}


set event_member_options [util_memoize "db_list_of_lists event_members {
	select  distinct
		im_name_from_user_id(object_id_two) as user_name,
		object_id_two as user_id
	from    acs_rels r,
		im_events p
	where   r.object_id_one = p.event_id
	order by user_name
}" 300]
set event_member_options [linsert $event_member_options 0 [list $all_l10n ""]]
set event_creator_options [list]
set event_creator_options [db_list_of_lists event_creators "
	select	distinct
		im_name_from_user_id(creation_user) as creator_name,
		creation_user as creator_id
	from	acs_objects
	where	object_type = :object_type
	order by creator_name
"]
set event_creator_options [linsert $event_creator_options 0 [list "" ""]]


ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -form {
    	{mine_p:text(select),optional {label "$mine_all_l10n"} {options $mine_p_options }}
	{start_date:text(text) {label "[_ intranet-timesheet2.Start_Date]"} {html {size 10}} {after_html {<input type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendar('start_date', 'y-m-d');" >}}}

    	{timescale:text(select),optional {label "$timescale_l10n"} {options $timescale_options }}
	{report_show_users_p:integer(checkbox),optional {label "$show_users_l10n"} {options {{"" 1}}} }
	{report_show_locations_p:integer(checkbox),optional {label "$show_locations_l10n"} {options {{"" 1}}} }
	{report_show_resources_p:integer(checkbox),optional {label "$show_resources_l10n"} {options {{"" 1}}} }
	{report_show_event_list_p:integer(checkbox),optional {label "$show_event_list_l10n"} {options {{"" 1}}} }

	{report_show_all_users_p:integer(checkbox),optional {label "$show_all_users_l10n"} {options {{"" 1}}} }

	{event_name:text(text),optional {label "[_ intranet-core.Name]"} {html {size 12}}}
	{event_status_id:text(im_category_tree),optional {label "[lang::message::lookup {} intranet-events.Status Status]"} {custom {category_type "Intranet Event Status" translate_p 1 package_key "intranet-core"}} }
    }

if {$view_events_all_p} {  
    ad_form -extend -name $form_id -form {
	{event_type_id:text(im_category_tree),optional {label "[lang::message::lookup {} intranet-events.Type Type]"} {custom {category_type "Intranet Event Type" translate_p 1 package_key "intranet-core"} } }
	{event_creator_id:text(select),optional {label "[lang::message::lookup {} intranet-events.Creator Creator]"} {options $event_creator_options}}
    }

    template::element::set_value $form_id event_status_id $event_status_id
    template::element::set_value $form_id event_type_id $event_type_id
}

template::element::set_value $form_id mine_p $mine_p
template::element::set_value $form_id start_date $start_date
template::element::set_value $form_id timescale $timescale

template::element::set_value $form_id report_show_users_p [im_opt_val report_show_users_p]
template::element::set_value $form_id report_show_locations_p [im_opt_val report_show_locations_p]
template::element::set_value $form_id report_show_resources_p [im_opt_val report_show_resources_p]
template::element::set_value $form_id report_show_event_list_p [im_opt_val report_show_event_list_p]
template::element::set_value $form_id report_show_all_users_p [im_opt_val report_show_all_users_p]


im_dynfield::append_attributes_to_form \
    -object_type $object_type \
    -form_id $form_id \
    -object_id 0 \
    -advanced_filter_p 1 \
    -search_p 1 \
    -page_url "/intranet-events/index"

# Set the form values from the HTTP form variable frame
set org_mine_p $mine_p
im_dynfield::set_form_values_from_http -form_id $form_id
im_dynfield::set_local_form_vars_from_http -form_id $form_id
set mine_p $org_mine_p

# A customer should not get the "My queue" filter pre-selected - should he get the "My queue" selection at all? 
if { [im_profile::member_p -profile_id [im_customer_group_id] -user_id $current_user_id] && [string first "mine" [string tolower $mine_p_options]] != -1 } {
    template::element::set_value $form_id mine_p "mine"
    set mine_p "mine"
}

array set extra_sql_array [im_dynfield::search_sql_criteria_from_form \
			       -form_id $form_id \
			       -object_type $object_type
]

# ---------------------------------------------------------------
# Generate SQL Query
# ---------------------------------------------------------------

if {1 == $report_show_event_list_p} {

set criteria [list]
if { ![empty_string_p $event_status_id_org] && $event_status_id_org > 0 } {
    lappend criteria "e.event_status_id in ([join [im_sub_categories $event_status_id_org] ","])"
}
if { ![empty_string_p $event_type_id_org] && $event_type_id_org != 0 } {
    lappend criteria "e.event_type_id in ([join [im_sub_categories $event_type_id_org] ","])"
}

if { [empty_string_p $event_material_id] == 0 && $event_material_id != 0 } {
    lappend criteria "e.event_material_id = :event_material_id"
}

if { [empty_string_p $event_creator_id] == 0 && $event_creator_id != 0 } {
    lappend criteria "e.event_id in (select object_id from acs_objects where creation_user = :event_creator_id)"
}

if { ![empty_string_p $customer_id] && $customer_id != 0 } {
    lappend criteria "p.company_id = :customer_id"
}
if { ![empty_string_p $customer_contact_id] && $customer_contact_id != 0 } {
    lappend criteria "e.event_customer_contact_id = :customer_contact_id"
}

if { ![empty_string_p $report_start_date] && $report_start_date != "" } {
    lappend criteria "e.event_end_date >= :report_start_date::timestamptz"
}
if { ![empty_string_p $report_end_date] && $report_end_date != "" } {
    lappend criteria "e.event_start_date < :report_end_date::timestamptz"
}
if { ![empty_string_p $event_name] && $event_name != "" } {
    if {0 && ![string isalphanum $event_name]} {
	ad_return_complaint 1 [lang::message::lookup "" intranet-events.Only_alphanum_allowed "
		Only alphanumerical characters are allowed for searching for security reasons.
	"]
	ad_script_abort
    }
    lappend criteria "lower(e.event_name) like lower('%$event_name%')"
}


set letter [string toupper $letter]

if { ![empty_string_p $letter] && [string compare $letter "ALL"] != 0 && [string compare $letter "SCROLL"] != 0 } {
    lappend criteria "im_first_letter_default_to_a(p.project_name) = upper(:letter)"
}

switch $mine_p {
    "all" { }
    "queue" { }
    "mine" {
	lappend criteria "(
		e.event_id in (select object_id_two from acs_rels where object_id_one = :current_user_id)
	)"
    }
    "default" { 
	# The short name of a SQL selector
	set selector_sql [db_string selector_sql "select selector_sql from im_sql_selectors where short_name = :mine_p" -default ""]
	if {"" == $selector_sql} {
	    ad_return_complaint 1 "Error:<br>Invalid variable mine_p = '$mine_p'" 
	    ad_script_abort
	}

	lappend criteria "e.event_id in ($selector_sql)"
    }
}

set order_by_clause "order by e.event_id DESC"

# ad_return_complaint 1 $order_by
switch [string tolower $order_by] {
    "date" { set order_by_clause "order by e.event_start_date DESC" }
    "start" { set order_by_clause "order by e.event_start_date DESC" }
    "name" { set order_by_clause "order by lower(e.event_name), e.event_start_date" }
    "type" { set order_by_clause "order by e.event_type_id, e.event_start_date" }
    "status" { set order_by_clause "order by e.event_status_id, e.event_start_date" }
    "material" { set order_by_clause "order by acs_object__name(e.event_material_id), e.event_name" }
    "duration" { set order_by_clause "order by (e.event_end_date - e.event_start_date) DESC, e.event_name" }
    "location" { set order_by_clause "order by acs_object__name(e.event_location_id), e.event_name" }
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
	    and event_id in $dynfield_extra_where
    "
}



# ---------------------------------------------------------------
#
# ---------------------------------------------------------------

set sql "
		SELECT
			e.*,
			im_category_from_id(e.event_type_id) as event_type,
			im_category_from_id(e.event_status_id) as event_status,
			to_char(e.event_start_date, 'YYYY-MM-DD') as event_start_date_formatted,
			to_char(e.event_end_date, 'YYYY-MM-DD') as event_end_date_formatted,
			(e.event_end_date::date - e.event_start_date::date) + 1 as event_duration_days,
			m.material_name,
			im_event__participant_list(e.event_id) as event_participant_list,
			im_event__customer_list(e.event_id) as event_customer_list,
			acs_object__name(e.event_location_id) as event_location_name
		FROM
			acs_objects o,
			im_events e
			LEFT OUTER JOIN im_materials m ON (e.event_material_id = m.material_id)
			$extra_from
		WHERE
			e.event_id = o.object_id
			$where_clause
			$extra_where
		$order_by_clause
"

# ---------------------------------------------------------------
# 5a. Limit the SQL query to MAX rows and provide << and >>
# ---------------------------------------------------------------

# The SQL can contain commands [..] that need to be
# evaluated in the context of this page.
eval "set sql \"$sql\""

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
db_foreach events_info_query $selection -bind $form_vars {

    set event_participants_pretty [join $event_participant_list "<br>"]
    set event_customers_pretty [join $event_customer_list "<br>"]

    # Bulk Action Checkbox
    set action_checkbox "<input type=checkbox name=tid value=$event_id id=event,$event_id>\n"

    # L10n
    regsub -all {[^0-9a-zA-Z]} $event_type "_" event_type_key
    set event_type_l10n [lang::message::lookup "" intranet-core.$event_type_key $event_type]
    regsub -all {[^0-9a-zA-Z]} $event_status "_" event_status_key
    set event_status_l10n [lang::message::lookup "" intranet-core.$event_status_key $event_status]

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
    if { $how_many > 0 && $ctr > $how_many } {
	break
    }
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


# Showing "next page" and the number of events shown
set start_idxpp [expr $start_idx+1]
set end_idx [expr $start_idx + $how_many]
if {$end_idx > $total_in_limited} { set end_idx $total_in_limited }
set viewing_msg [lang::message::lookup "" intranet-events.Viewing_start_end_from_total_in_limited "
	    Viewing events %start_idxpp% to %end_idx% from %total_in_limited%"]
if {$total_in_limited < 1} { set viewing_msg "" }

set table_continuation_html "
	<tr>
	  <td align=center colspan=$colspan>
	    $viewing_msg &nbsp;
	    [im_maybe_insert_link $previous_page $next_page]
	  </td>
	</tr>
"

set table_submit_html "
  <tfoot>
	<tr valign=top>
	  <td align=left colspan=[expr $colspan-1] valign=top>
<!--		[im_gif cleardot]	-->
		<table cellspacing=1 cellpadding=1 border=0>
		<tr valign=top>
<!--
		<td>
			[lang::message::lookup "" intranet-events.Action "Action:"]	
		</td>
-->
		<td>
			[im_category_select \
			     -translate_p 1 \
			     -package_key "intranet-events" \
			     -plain_p 1 \
			     -include_empty_p 1 \
			     -include_empty_name "" \
			     "Intranet Event Action" \
			     action_id \
			]
		</td>
		<td>
			<input type=submit value='[lang::message::lookup "" intranet-events.Update_Events "Update"]'>
		</td>
		</tr>
		</table>

	  </td>
	</tr>
  </tfoot>
"

if {!$view_events_all_p} { set table_submit_html "" }

}

# ---------------------------------------------------------------
# Calendar display for vacation days
# ---------------------------------------------------------------

set event_cube_html ""
if {1 == $report_show_users_p || 1 == $report_show_locations_p || 1 == $report_show_resources_p} {
    set event_cube_html [im_event_cube \
			 -report_user_selection $mine_p \
			 -event_status_id $event_status_id_org \
			 -event_type_id $event_type_id_org \
			 -event_material_id $event_material_id_org \
			 -event_location_id $event_location_id_org \
			 -event_creator_id $event_creator_id \
			 -event_name $event_name_org \
			 -report_start_date $report_start_date \
			 -report_end_date $report_end_date \
			 -report_user_group_id [im_profile_employees] \
			 -report_show_users_p $report_show_users_p \
			 -report_show_locations_p $report_show_locations_p \
			 -report_show_resources_p $report_show_resources_p \
			 -report_show_all_users_p $report_show_all_users_p \
			]
}


# ----------------------------------------------------------
# Do we have to show administration links?

set admin_html "<ul>"

if {[im_is_user_site_wide_or_intranet_admin $current_user_id]} {
#    append admin_html "<li><a href=\"/intranet-events/admin/\">[lang::message::lookup "" intranet-events.Admin_Helpdesk "Admin Helpdesk"]</a>\n"
}

if {[im_permission $current_user_id "add_events"]} {
    append admin_html "<li><a href=\"[export_vars -base "/intranet-events/new" {return_url}]\">[lang::message::lookup "" intranet-events.Add_a_new_event "New Event"]</a>\n"

    set wf_oid_col_exists_p [im_column_exists wf_workflows object_type]
    if {$wf_oid_col_exists_p} {
	set wf_sql "
		select	t.pretty_name as wf_name,
			w.*
		from	wf_workflows w,
			acs_object_types t
		where	w.workflow_key = t.object_type
			and w.object_type = :object_type
	"
	db_foreach wfs $wf_sql {
	    set new_from_wf_url [export_vars -base "/intranet/events/new" {workflow_key}]
	    append admin_html "<li><a href=\"$new_from_wf_url\">[lang::message::lookup "" intranet-events.New_workflow "New %wf_name%"]</a>\n"
	}
    }
}

# Append user-defined menus
append admin_html [im_menu_ul_list -no_uls 1 "events_admin" {}]

# Close the admin_html section
append admin_html "</ul>"




# ----------------------------------------------------------
# Set color scheme 
# ----------------------------------------------------------

set color_list [im_event_cube_color_list]
set color_sql "
	select	category_id,
		category,
		category_type,
		aux_string2
	from	im_categories
	where	(enabled_p = 't' or enabled_p is null) and
		category_type in ('Intranet Event Status', 'Intranet Absence Type')
	order by 
		category_type DESC,
		category_id
"
append admin_html "<div class=filter-title>[lang::message::lookup "" intranet-timesheet2.Color_codes "Color Codes"]</div>\n"
append admin_html "<table cellpadding='5' cellspacing='5'>\n"


set index 0
set last_category_type ""
db_foreach event_color_codes $color_sql {
    # Create intermediate headers for each category tye
    if {$category_type != $last_category_type} {
	set last_category_type $category_type
	append admin_html "<tr><td class=rowwhite style='font-weight:bold'>$category_type</td></tr>\n"
    }

    # !!!
    set col $aux_string2
    if {"" == $aux_string2 } {
	set col [lindex $color_list $index]
	incr index
    }

    regsub -all " " $category "_" category_key
    set category_l10n [lang::message::lookup "" intranet-core.$category_key $category]
    if { [string length $col] == 6} {
	# Transform RGB Hex-Values (e.g. #a3b2c4) into Dec-Values
	set r_bg [expr 0x[string range $col 0 1]]
	set g_bg [expr 0x[string range $col 2 3]]
	set b_bg [expr 0x[string range $col 4 5]]
    } elseif { [string length $col] == 3 } {
	# Transform RGB Hex-Values (e.g. #a3b) into Dec-Values
	set r_bg [expr 0x[string range $col 0 0]]
	set g_bg [expr 0x[string range $col 1 1]]
	set b_bg [expr 0x[string range $col 2 2]]
    } else {
	# color codes can't be parsed -> set a middle value
	set r_bg 127
	set g_bg 127
	set b_bg 127
    }

    # calculate a brightness-value for the color
    # if brightness > 127 the foreground color is black, if < 127 the foreground color is white
    set brightness [expr $r_bg * 0.2126 + $g_bg * 0.7152 + $b_bg * 0.0722]
    set col_fg "fff"
    if {$brightness >= 127} {set col_fg "000"}
    set category_l10n [lang::message::lookup "" intranet-core.$category_key $category]
    append admin_html "<tr><td style='padding:3px; background-color:\#$col; color:\#$col_fg'>$category_l10n</td></tr>\n"
}

append admin_html "</table>\n"




# ---------------------------------------------------------------
# Dashboard column
# ---------------------------------------------------------------

set dashboard_column_html [string trim [im_component_bay "right"]]
if {"" == $dashboard_column_html} {
    set dashboard_column_width "0"
} else {
    set dashboard_column_width "250"
}

# ---------------------------------------------------------------
# Sub-Navbar
# ---------------------------------------------------------------

set menu_select_label ""
set event_navbar_html [im_event_navbar $letter "/intranet-events/index" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter event_status_id] $menu_select_label]



# ---------------------------------------------------------------
# Left-Navbar
# ---------------------------------------------------------------


# Compile and execute the formtemplate if advanced filtering is enabled.
eval [template::adp_compile -string {<formtemplate style=tiny-plain-po id="event_filter"></formtemplate>}]
set filter_html $__adp_output


set left_navbar_html "
	    <div class=\"filter-block\">
		<div class=\"filter-title\">
		    [lang::message::lookup "" intranet-events.Filter_Events "Filter Events"]
		</div>
		$filter_html
	    </div>
	    <hr/>
"

append left_navbar_html "
	    <div class=\"filter-block\">
		<div class=\"filter-title\">
		    [lang::message::lookup "" intranet-events.Admin "Admin"]
		</div>
		$admin_html
	    </div>
	    <hr/>
"


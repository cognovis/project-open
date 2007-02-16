# /packages/intranet-reporting/www/gantt-resources-cube.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Gantt Resource "Cube"
} {
    { start_date "2006-01-01" }
    { end_date "2007-07-01" }
    { top_vars "week_of_year day_of_month" }
    { left_vars "user_name_link project_name_link" }
    { project_id:integer,multiple 0 }
    { customer_id:integer 0 }
}

set s [clock clicks -milliseconds]
ns_log Notice "gantt-resources: Start:		[ns_conn url]"

# set left_vars "user_name_link"
# set top_vars "week_of_year"

set project_id [db_list pids "
	select	project_id
	from	im_projects
	where	parent_id is null
		and project_status_id = [im_project_status_open]
"]


# ------------------------------------------------------------
# Defaults

set page_title [lang::message::lookup "" intranet-reporting.Gantt_Resources "Gantt Resources"]
set rowclass(0) "roweven"
set rowclass(1) "rowodd"
set sigma "&Sigma;"


# ------------------------------------------------------------
# Define Dimensions

# The complete set of dimensions - used as the key for
# the "cell" hash. Subtotals are calculated by dropping on
# or more of these dimensions
set dimension_vars [concat $top_vars $left_vars]


# ------------------------------------------------------------
# URLs to different parts of the system

set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting/gantt-cube" {start_date end_date} ]


ns_log Notice "gantt-resources: After init:	[expr [clock clicks -milliseconds]-$s]"


# ------------------------------------------------------------
# Start formatting the page
#

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format "html"

ns_write "
[im_header]
[im_navbar]
<table border=0 cellspacing=1 cellpadding=1>
"



# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]

if {"" != $customer_id && 0 != $customer_id} {
    lappend criteria "p.company_id = :customer_id"
}

if {"" != $project_id && 0 != $project_id} {
    lappend criteria "parent.project_id in ([join $project_id ", "])"
}

set where_clause [join $criteria " and\n\t\t\t"]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

# Inner - Try to be as selective as possible for the relevant data from the fact table.
set inner_sql "
		select
		        child.*,
		        u.user_id,
			m.percentage as perc,
			d.d
		from
		        im_projects parent,
		        im_projects child,
		        acs_rels r
		        LEFT OUTER JOIN im_biz_object_members m on (r.rel_id = m.rel_id),
		        cc_users u,
		        ( select im_day_enumerator as d
		          from im_day_enumerator(
				to_date(:start_date, 'YYYY-MM-DD'), 
				to_date(:end_date, 'YYYY-MM-DD')
			) ) d
		where
		        r.object_id_one = child.project_id
		        and r.object_id_two = u.user_id
		        and parent.project_status_id in (76)
		        and parent.parent_id is null
		        and child.tree_sortkey 
				between parent.tree_sortkey 
				and tree_right(parent.tree_sortkey)
		        and d.d 
				between child.start_date 
				and child.end_date
			$where_clause
"


# Aggregate additional/important fields to the fact table.
set middle_sql "
	select
		h.*,
		trunc(h.perc) as percentage,
		'<a href=${user_url}'||user_id||'>'||im_name_from_id(h.user_id)||'</a>' as user_name_link,
		'<a href=${project_url}'||project_id||'>'||project_name||'</a>' as project_name_link,
		to_char(h.d, 'YYYY') as year,
		to_char(h.d, 'Q') as quarter_of_year,
		to_char(h.d, 'MM') as month_of_year,
		to_char(h.d, 'YYYY-IW') as week_of_year,
		to_char(h.d, 'DD') as day_of_month
	from	($inner_sql) h
	where	h.perc is not null
"

set outer_sql "
select
	sum(h.percentage) as percentage,
	[join $dimension_vars ",\n\t"]
from
	($middle_sql) h
group by
	[join $dimension_vars ",\n\t"]
"


# ------------------------------------------------------------
# Create upper date dimension

ns_log Notice "gantt-resources: Before date dims:	[expr [clock clicks -milliseconds]-$s]"


# Top scale is a list of lists such as {{2006 01} {2006 02} ...}
# The last element of the list the grand total sum.
set top_scale_plain [db_list_of_lists top_scale "
	select distinct	[join $top_vars ", "]
	from		($middle_sql) c
	order by	[join $top_vars ", "]
"]
lappend top_scale_plain [list $sigma $sigma $sigma $sigma $sigma $sigma]

ns_log Notice "gantt-resources: After date dims:	[expr [clock clicks -milliseconds]-$s]"


# Insert subtotal columns whenever a scale changes
set top_scale [list]
set last_item [lindex $top_scale_plain 0]
foreach scale_item $top_scale_plain {
    for {set i [expr [llength $last_item]-2]} {$i >= 0} {set i [expr $i-1]} {

        set last_var [lindex $last_item $i]
        set cur_var [lindex $scale_item $i]
        if {$last_var != $cur_var} {
            set item [lrange $last_item 0 $i]
            while {[llength $item] < [llength $last_item]} { lappend item $sigma }
            lappend top_scale $item
        }

    }
    lappend top_scale $scale_item
    set last_item $scale_item
}

ns_log Notice "gantt-resources: After date dim scale:	[expr [clock clicks -milliseconds]-$s]"



# ------------------------------------------------------------
# Create a sorted left dimension

ns_log Notice "gantt-resources: Before left dims:	[expr [clock clicks -milliseconds]-$s]"

# No left dimension at all gives an error...
if {![llength $left_vars]} {
    ns_write "
	<p>&nbsp;<p>&nbsp;<p>&nbsp;<p><blockquote>
	[lang::message::lookup "" intranet-reporting.No_left_dimension "No 'Left' Dimension Specified"]:<p>
	[lang::message::lookup "" intranet-reporting.No_left_dimension_message "
		You need to specify atleast one variable for the left dimension.
	"]
	</blockquote><p>&nbsp;<p>&nbsp;<p>&nbsp;
    "
    ns_write "</table>\n[im_footer]\n"
    return
}

# Scale is a list of lists. Example: {{2006 01} {2006 02} ...}
# The last element is the grand total.
set left_scale_plain [db_list_of_lists left_scale "
	select distinct	[join $left_vars ", "]
	from		($middle_sql) c
	order by	[join $left_vars ", "]
"]
set last_sigma [list]
foreach t [lindex $left_scale_plain 0] {
    lappend last_sigma $sigma
}
lappend left_scale_plain $last_sigma


# Add subtotals whenever a "main" (not the most detailed) scale changes
set left_scale [list]
set last_item [lindex $left_scale_plain 0]
foreach scale_item $left_scale_plain {

    for {set i [expr [llength $last_item]-2]} {$i >= 0} {set i [expr $i-1]} {
	set last_var [lindex $last_item $i]
	set cur_var [lindex $scale_item $i]
	if {$last_var != $cur_var} {

	    set item [lrange $last_item 0 $i]
	    while {[llength $item] < [llength $last_item]} { lappend item $sigma }
	    lappend left_scale $item
	}
    }
    lappend left_scale $scale_item
    set last_item $scale_item
}


# ------------------------------------------------------------
# Display the Table Header

ns_log Notice "gantt-resources: Before table header:	[expr [clock clicks -milliseconds]-$s]"


# Determine how many date rows (year, month, day, ...) we've got
set first_cell [lindex $top_scale 0]
set top_scale_rows [llength $first_cell]
set left_scale_size [llength [lindex $left_scale 0]]

set header ""
for {set row 0} {$row < $top_scale_rows} { incr row } {

    append header "<tr class=rowtitle>\n"
    set col_l10n [lang::message::lookup "" "intranet-ganttproject.Dim_[lindex $top_vars $row]" [lindex $top_vars $row]]
    append header "<td class=rowtitle colspan=$left_scale_size align=right>$col_l10n</td>\n"

    for {set col 0} {$col <= [expr [llength $top_scale]-1]} { incr col } {

	set scale_entry [lindex $top_scale $col]
	set scale_item [lindex $scale_entry $row]

	# Check if the previous item was of the same content
	set prev_scale_entry [lindex $top_scale [expr $col-1]]
	set prev_scale_item [lindex $prev_scale_entry $row]

	# Check for the "sigma" sign. We want to display the sigma
	# every time (disable the colspan logic)
	if {$scale_item == $sigma} { 
	    append header "\t<td class=rowtitle>$scale_item</td>\n"
	    continue
	}

	# Prev and current are same => just skip.
	# The cell was already covered by the previous entry via "colspan"
	if {$prev_scale_item == $scale_item} { continue }

	# This is the first entry of a new content.
	# Look forward to check if we can issue a "colspan" command
	set colspan 1
	set next_col [expr $col+1]
	while {$scale_item == [lindex [lindex $top_scale $next_col] $row]} {
	    incr next_col
	    incr colspan
	}
	append header "\t<td class=rowtitle colspan=$colspan>$scale_item</td>\n"	    

    }
    append header "</tr>\n"
}
ns_write $header


# ------------------------------------------------------------
# Execute query and aggregate values into a Hash array


ns_log Notice "gantt-resources: Before db_foreach:	[expr [clock clicks -milliseconds]-$s]"

set cnt_outer 0
set cnt_inner 0
db_foreach query $outer_sql {

    if {"" == $percentage} { continue }

    # Get all possible permutations (N out of M) from the dimension_vars
    set perms [im_report_take_all_ordered_permutations $dimension_vars]

    # Add the gantt hours to ALL of the variable permutations.
    # The "full permutation" (all elements of the list) corresponds
    # to the individual cell entries.
    # The "empty permutation" (no variable) corresponds to the
    # gross total of all values.
    # Permutations with less elements correspond to subtotals
    # of the values along the missing dimension. Clear?
    #
    foreach perm $perms {

	# Calculate the key for this permutation
	# something like "$year-$month-$customer_id"
	set key_expr "\$[join $perm "-\$"]"
	set key [eval "set a \"$key_expr\""]

	# Sum up the values for the matrix cells
	set sum 0
	if {[info exists hash($key)]} { set sum $hash($key) }
	
	if {"" == $percentage} { set percentage 0 }
	set sum [expr $sum + $percentage]
	set hash($key) $sum

	incr cnt_inner
    }
    incr cnt_outer
}

ns_log Notice "gantt-resources: After db_foreach:	[expr [clock clicks -milliseconds]-$s]"
ns_log Notice "gantt-resources: After db_foreach:	outer=$cnt_outer, inner=$cnt_inner"


# ------------------------------------------------------------
# Display the table body

ns_log Notice "gantt-resources: Before table disp:	[expr [clock clicks -milliseconds]-$s]"


set ctr 0
foreach left_entry $left_scale {

    set class $rowclass([expr $ctr % 2])
    incr ctr

    # Start the row and show the left_scale values at the left
    ns_write "<tr class=$class>\n"
    foreach val $left_entry { ns_write "<td>$val</td>\n" }

    # Write the left_scale values to their corresponding local 
    # variables so that we can access them easily when calculating
    # the "key".
    for {set i 0} {$i < [llength $left_vars]} {incr i} {
	set var_name [lindex $left_vars $i]
	set var_value [lindex $left_entry $i]
	set $var_name $var_value
    }
    
    foreach top_entry $top_scale {

	# Write the top_scale values to their corresponding local 
	# variables so that we can access them easily for $key
	for {set i 0} {$i < [llength $top_vars]} {incr i} {
	    set var_name [lindex $top_vars $i]
	    set var_value [lindex $top_entry $i]
	    set $var_name $var_value
	}

	# Calculate the key for this permutation
	# something like "$year-$month-$customer_id"
	set key_expr_list [list]
	foreach var_name $dimension_vars {
	    set var_value [eval set a "\$$var_name"]
	    if {$sigma != $var_value} { lappend key_expr_list $var_name }
	}
	set key_expr "\$[join $key_expr_list "-\$"]"
	set key [eval "set a \"$key_expr\""]

	set val ""
	if {[info exists hash($key)]} { set val $hash($key) }

	
	# ------------------------------------------------------------
	# Format the percentage value for percent-arithmetics:
	# - Sum up percentage values per day
	# - When showing percentag per week then sum up and divide by 5 (working days)
	# ToDo: Include vacation calendar and resource availability in
	# the future.

	if {0 == $val} { set val "" }
	if {![regexp {[^0-9]} $val match]} {
	    set color "\#000000"
	    if {$val > 100} { set color "\#808000" }
	    if {$val > 200} { set color "\#FF0000" }
	    set val "<font color=$color>$val</font>\n"
	}


	# ------------------------------------------------------------

	ns_write "<td>$val</td>\n"

    }
    ns_write "</tr>\n"
}


ns_log Notice "gantt-resources: After table disp:	[expr [clock clicks -milliseconds]-$s]"

# ------------------------------------------------------------
# Finish up the table

ns_write "</table>\n[im_footer]\n"



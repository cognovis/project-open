# /packages/intranet-reporting/www/gantt-resources-cube.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Gantt Resource "Cube"
} {
    { start_date "" }
    { end_date "" }
    { level_of_detail:integer 2 }
    { left_vars "user_name_link project_name_link" }
    { project_id:integer,multiple "" }
    { customer_id:integer 0 }
}

set s [clock clicks -milliseconds]
ns_log Notice "gantt-resources: Start:		[ns_conn url]"

# set left_vars "user_name_link"

# set top_vars "week_of_year"

set top_vars "month_of_year week_of_year day_of_month"
# set top_vars "month_of_year week_of_year"

switch $level_of_detail {
    1 { set top_vars "month_of_year" }
    2 { set top_vars "month_of_year week_of_year" }
    3 { set top_vars "month_of_year week_of_year day_of_month" }
    default { set top_vars "month_of_year" }
}
    

# ------------------------------------------------------------
# Defaults

set page_title [lang::message::lookup "" intranet-reporting.Gantt_Resources "Gantt Resources"]
set rowclass(0) "roweven"
set rowclass(1) "rowodd"
set sigma "&Sigma;"



if {0 != $customer_id && "" == $project_id} {
    set project_id [db_list pids "
	select	project_id
	from	im_projects
	where	parent_id is null
		and company_id = :customer_id
    "]
}

# No projects specified? Show the list of all active projects
if {"" == $project_id} {
    set project_id [db_list pids "
	select	project_id
	from	im_projects
	where	parent_id is null
		and project_status_id = [im_project_status_open]
    "]
}

# ------------------------------------------------------------
# Start and End-Dat as min/max of selected projects.
# Note that the sub-projects might "stick out" before and after
# the main/parent project.

if {"" == $start_date} {
    set start_date [db_string start_date "
	select
		to_char(min(child.start_date), 'YYYY-MM-DD')
	from
		im_projects parent,
		im_projects child
	where
		parent.project_id in ([join $project_id ", "])
		and parent.parent_id is null
		and child.tree_sortkey
			between parent.tree_sortkey
			and tree_right(parent.tree_sortkey)

    "]
}

if {"" == $end_date} {
    set end_date [db_string end_date "
	select
		to_char(max(child.end_date), 'YYYY-MM-DD')
	from
		im_projects parent,
		im_projects child
	where
		parent.project_id in ([join $project_id ", "])
		and parent.parent_id is null
		and child.tree_sortkey
			between parent.tree_sortkey
			and tree_right(parent.tree_sortkey)
    "]
}



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
set this_url [export_vars -base "/intranet-reporting/gantt-resources-cube" {start_date end_date} ]


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
		to_char(h.d, 'YYYY') || '<br>' || to_char(h.d, 'MM') as month_of_year,
		to_char(h.d, 'IW') as week_of_year,
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
            set item_sigma [lrange $last_item 0 $i]
            while {[llength $item_sigma] < [llength $last_item]} { lappend item_sigma $sigma }
            lappend top_scale $item_sigma
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

	# Skip the last line with all sigmas - doesn't sum up...
	set all_sigmas_p 1
	foreach e $scale_entry { if {$e != $sigma} { set all_sigmas_p 0 }	}
	if {$all_sigmas_p} { continue }



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

    # Skip empty percentage entries. Improves performance...
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

    # Add empty line before the total sum. The total sum of percentage
    # shows the overall resource assignment and doesn't make much sense...
    set user_pos [lsearch $left_vars "user_name_link"]
    set user_val [lindex $left_entry $user_pos]
    if {$sigma == $user_val} {
	ns_write "<tr><td colspan=99>&nbsp;</td></tr>\n"
    }

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

	# Skip the last line with all sigmas - doesn't sum up...
	set all_sigmas_p 1
	foreach e $top_entry { if {$e != $sigma} { set all_sigmas_p 0 }	}
	if {$all_sigmas_p} { continue }


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

	if {"" == $val} { set val 0 }

	set week_pos [lsearch $top_vars "week_of_year"]
	set week_val [lindex $top_entry $week_pos]

	set day_pos [lsearch $top_vars "day_of_month"]
	set day_val [lindex $top_entry $day_pos]

	set period "day"
	if {"" == $day_val | $sigma == $day_val} {
	    set val_week [expr round($val/5)]
	    set period "week"
	}

	if {"" == $week_val | $sigma == $week_val} {
	    set val_month [expr round($val/20)]
	    set period "month"
	}

	switch $period {
	    week { set val $val_week }
	    month { set val $val_month }
	}

#	set val "$val $week_val"

	# ------------------------------------------------------------

	if {0 == $val} { set val "" }
	if {![regexp {[^0-9]} $val match]} {
	    set color "\#000000"
	    if {$val > 100} { set color "\#808000" }
	    if {$val > 200} { set color "\#FF0000" }
	    set val "<font color=$color>$val</font>\n"
	}

	ns_write "<td>$val</td>\n"

    }
    ns_write "</tr>\n"
}


ns_log Notice "gantt-resources: After table disp:	[expr [clock clicks -milliseconds]-$s]"

# ------------------------------------------------------------
# Finish up the table

ns_write "</table>\n[im_footer]\n"



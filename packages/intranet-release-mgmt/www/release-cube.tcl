# /packages/intranet-release-mgmt/www/release-cube.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Release Cube
} {
}

# ------------------------------------------------------------
# Define Dimensions

set top_vars [list release_date release_nr]
set left_vars [list item_nr item_name]
set dimension_vars [concat $top_vars $left_vars]

# ------------------------------------------------------------
# Page Title & Help Text

set page_title "Release Overview"
set context_bar [im_context_bar $page_title]
set context ""
set help_text "<strong>$page_title</strong><br>
"


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

set gray "gray"
set sigma "&Sigma;"

set cur_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]

set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting/finance-cube" {start_date end_date} ]

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
# Define the report - SQL, counters, headers and footers 
#

# Aggregate additional/important fields to the fact table.
set middle_sql "
	select
		p.project_id as release_id,
		p.project_nr as release_nr,
		p.end_date as release_end_date,
		items.project_id as item_id,
		items.project_nr as item_nr,
		items.project_name as item_name,
		i.sort_order as item_sort_order,
		im_category_from_id(i.release_status_id) as release_status
	from
		im_projects p,
		im_projects items,
		acs_rels r,
		im_release_items i
	where
		r.rel_id = i.rel_id
		and r.object_id_one = p.project_id
		and r.object_id_two = items.project_id
		and p.project_status_id not in (
			select child_id
			from im_category_hierarchy
			where parent_id = [im_project_status_closed]
		    UNION
			select [im_project_status_closed]
		)
"

# ------------------------------------------------------------
# Create upper & left dimensions

# Top scale is a list of lists such as {{2006 01} {2006 02} ...}
# The last element of the list the grand total sum.
set top_scale [db_list_of_lists top_scale "
	select	distinct
		to_char(release_end_date, 'YYYY-MM-DD'),
		release_nr
	from	($middle_sql) c
	order by
		to_char(release_end_date, 'YYYY-MM-DD')
"]

set left_scale_base [db_list_of_lists left_scale "
	select distinct
		to_char(release_end_date, 'YYYY-MM-DD'),
		item_nr,
		item_name,
		item_sort_order
	from	($middle_sql) c
	order by
		to_char(release_end_date, 'YYYY-MM-DD'), item_sort_order
"]

# Eliminate duplicate entries for same items
set left_scale [list]
foreach el $left_scale_base {
    set release_date [lindex $el 0]
    set item_nr [lindex $el 1]
    set item_name [lindex $el 2]
    set item_sort_order [lindex $el 3]
    if {![info exists item_nr_hash($item_nr)]} {
	lappend left_scale [list $item_nr $item_name]
    }

    set item_nr_hash($item_nr) 1
}


# ------------------------------------------------------------
# Display the Table Header

# Determine how many date rows (year, month, day, ...) we've got
set first_cell [lindex $top_scale 0]
set top_scale_rows [llength $first_cell]
set left_scale_size [llength [lindex $left_scale 0]]

set header ""
for {set row 0} {$row < $top_scale_rows} { incr row } {

    append header "<tr class=rowtitle>\n"
    append header "<td colspan=$left_scale_size></td>\n"

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

db_foreach query $middle_sql {
    set key "$release_nr-$item_nr"
    set hash($key) $release_status
}


# ------------------------------------------------------------
# Display the table body

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
	set key "$release_nr-$item_nr"
	set val "&nbsp;"
	if {[info exists hash($key)]} { set val $hash($key) }

	ns_write "<td>$val</td>\n"

    }
    ns_write "</tr>\n"
}


# ------------------------------------------------------------
# Finish up the table

ns_write "</table>\n[im_footer]\n"



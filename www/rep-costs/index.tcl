# /packages/intranet-cost/www/repeating-costs/index.tcl
#
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Shows a summary of the loged hours by all team members of a project (1 week)


    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @author Alwin Egger (alwin.egger@gmx.net)
} {
    { start_date "" }
    { report_months 12 }
    { return_url "/intranet-cost/repeating-costs/" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set subsite_id [ad_conn subsite_id]
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set site_url "/intranet-cost/repeating-costs"
set cost_create_url "/intranet-cost/repeating-costs/new-repeated-item"

# Start with January of this year if not otherwise specified:
if {"" == $start_date} {
    set start_date [db_string get_current_year "select to_char(sysdate, 'YYYY') from dual"]
    set start_date "$start_date-01-01"
}

# Extract year, month and day
regexp {(....)-(..)-(..)} $start_date match start_year start_month start_day

if {"" == $start_month || $start_month < 1 || $start_month > 12} {
    ad_return_complaint 1 "<li>Wrong date '$start_date'"
    return
}

# ---------------------------------------------------------------
# Get the data and fill it into arrays
# ---------------------------------------------------------------

# Get the list of repeating cost_ids
set repeating_costs_sql "select * from im_repeating_costs"
set repeating_cost_ids [list]
db_foreach repeating_costs $repeating_costs_sql {
    lappend repeating_cost_ids [list $cost_id $cost_name]
}


# The SQL that returns all "start_blocks" (=first
# days of each month) during the lifetime of all
# "repeating cost items".
set all_start_blocks_sql "
select	rc.cost_id as rep_cost_id,
        sm.start_block
from	im_repeating_costs rc,
        im_start_months sm
where	start_block >= rc.start_date
        and (rc.end_date is null or start_block < rc.end_date)
        and start_block < sysdate + 365"

db_foreach all_start_blocks $all_start_blocks_sql {
    set key "$cost_id:$start_block"
    # Fill the field with a link to create a new cost item
    set blocks($key) "<a href=$cost_create_url?[export_url_vars rep_cost_id start_block return_url]>(create)</a>"
}

# Get the cost for each start_block.
# ...

# ---------------------------------------------------------------
# Render the table header
# ---------------------------------------------------------------

set table_header_html "<tr><th>&nbsp;</td>\n"
for {set month 1} {$month <= $report_months} {incr month} {
    set mm $month
    if {1 == [string length $mm]} { set mm "0$mm" }
    append table_header_html "<th class=rowtitle>$start_year-$mm</th>"
}
append table_header_html "</tr>\n"


# ---------------------------------------------------------------
# Render the main table -
# ---------------------------------------------------------------

set table_body_html ""
set ctr 1
foreach cost_tuple $repeating_cost_ids {

    set cost_id [lindex $cost_tuple 0]
    set cost_name [lindex $cost_tuple 1]

    append table_body_html "<tr $bgcolor([expr $ctr % 2])>\n"
    append table_body_html "<td><a href=asdf>$cost_name</a></td>\n"

    for {set month 1} {$month <= $report_months} {incr month} {

	set mm $month
	if {1 == [string length $mm]} { set mm "0$mm" }
	set start_block "$start_year-$mm-01"
	set key "$cost_id:$start_block"
	if {[info exists blocks($key)]} {
	    set value $blocks($key)
	    append table_body_html "\t<td>$key - $value</td>\n"
	} else {
	    append table_body_html "\t<td>&nbsp;</td>\n"
	}

    }
    append table_body_html "</tr>\n"
    incr ctr
}

set table_continuation_html ""

db_release_unused_handles

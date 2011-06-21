# /packages/intranet-sencha-ticket-tracker/www/report-area.tcl
#
# Copyright (c) 2011 ]ticket-open[
#
# All rights reserved. Please check
# http://www.ticket-open.com/ for licensing details.


ad_page_contract {
    SPRI Cube
} {
    { start_date "2001-06-01" }
    { end_date "2011-07-01" }
}


# ----------------------------------------------------------------
# Calculate information by channel
# ----------------------------------------------------------------

set dimension_vars [list ticket_area_id ticket_incoming_channel_id]
set dimension_perms [im_report_take_all_ordered_permutations $dimension_vars]
# ad_return_complaint 1 $dimension_perms

set channel_sql "
	select	count(*) as aggregate,
		t.ticket_area_id,
		t.ticket_incoming_channel_id
	from	im_tickets t,
		im_projects p,
		acs_objects o
	where	t.ticket_id = p.project_id and
		t.ticket_id = o.object_id
	group by
		t.ticket_area_id,
		t.ticket_incoming_channel_id
"

#		o.creation_date >= :start_date and
#		o.creation_date < :end_date

db_foreach channel_hash $channel_sql {

    # Take the parent of the ticket area if available.
    set ticket_area_id_parent [lindex [im_category_parents $ticket_area_id] 0]
    if {"" != $ticket_area_id_parent} { set ticket_area_id $ticket_area_id_parent }

    # Take the parent of the ticket incoming_channel if available.
    set ticket_incoming_channel_id_parent [lindex [im_category_parents $ticket_incoming_channel_id] 0]
    if {"" != $ticket_incoming_channel_id_parent} { set ticket_incoming_channel_id $ticket_incoming_channel_id_parent }

    set ticket_area [im_category_from_id $ticket_area_id]
    set ticket_incoming_channel [im_category_from_id $ticket_incoming_channel_id]

    foreach perm $dimension_perms {
	set key_expr "\$[join $perm "-\$"]"
	set key [eval "set a \"$key_expr\""]
	
	set sum 0
	if {[info exists channel_hash($key)]} { set sum $channel_hash($key) }
	if {"" == $aggregate} { set aggregate 0 }
	set sum [expr $sum + $aggregate]
	set channel_hash($key) $sum
    }
}

# ----------------------------------------------------------------
# Calculate the dimension values
# ----------------------------------------------------------------

set area_list_sql "
	select	category_id
	from	im_categories
	where	category_type = 'Intranet Sencha Ticket Tracker Area'
	order by category
"
set area_list [list]
db_foreach area $area_list_sql {
    set parent_id [lindex [im_category_parents $category_id] 0]
    if {"" != $parent_id} { set category_id $parent_id }
    if {[lsearch $area_list $category_id] >= 0} { continue }
    lappend area_list $category_id
}
lappend area_list ""

set channel_list_sql "
	select	category_id
	from	im_categories
	where	category_type = 'Intranet Ticket Origin'
	order by category
"
set channel_list [list]
db_foreach channel $channel_list_sql {
    set parent_id [lindex [im_category_parents $category_id] 0]
    if {"" != $parent_id} { set category_id $parent_id }
    if {[lsearch $channel_list $category_id] >= 0} { continue }
    lappend channel_list $category_id
}
lappend channel_list ""




# ----------------------------------------------------------------
# Format the data 
# ----------------------------------------------------------------

set channel_header "<td class=rowtitle></td>"
append channel_header "<td class=rowtitle>Total</td>"
foreach channel_id $channel_list {
    append channel_header "<td class=rowtitle>[im_category_from_id $channel_id]</td>"
}
set channel_header "<tr class=rowtitle>$channel_header</tr>"

set channel_body ""
foreach area_id $area_list {
    set row "<tr><td>[im_category_from_id $area_id]</td>\n"
    set total ""
    set key "$area_id"
    if {[info exists channel_hash($key)]} { set total $channel_hash($key) }
    append row "<td>$total</td>\n"
    foreach channel_id $channel_list {
	set val "-"
	set key "$area_id-$channel_id"
	if {[info exists channel_hash($key)]} { set val $channel_hash($key) }
	append row "<td>$val</td>"
    }
    append row "</tr>"
    append channel_body $row
}

set channel_footer "<td></td>"
append channel_footer "<td>grand total</td>"
foreach channel_id $channel_list {
    set val "-"
    set key "$channel_id"
    if {[info exists channel_hash($key)]} { set val $channel_hash($key) }
    append channel_footer "<td>$val</td>"
}
set channel_footer "<tr>$channel_footer</tr>"

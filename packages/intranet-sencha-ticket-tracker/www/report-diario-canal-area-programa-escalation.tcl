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

set sigma "&Sigma;"

# ----------------------------------------------------------------
# Dimensions
# ----------------------------------------------------------------

set area_list_sql "
	select distinct
		coalesce(
			(select min(im_category_parents) from im_category_parents(category_id)), 
			category_id
		) as category_id
	from	im_categories
	where	category_type = 'Intranet Sencha Ticket Tracker Area'
	order by category_id
"
set area_list [list]
db_foreach area $area_list_sql {
    lappend area_list $category_id
}
lappend area_list -1000

set channel_list_sql "
	select distinct
		coalesce(
			(select min(im_category_parents) from im_category_parents(category_id)), 
			category_id
		) as category_id
	from	im_categories
	where	category_type = 'Intranet Ticket Origin'
	order by category_id
"
set channel_list [list]
db_foreach channel $channel_list_sql {
    lappend channel_list $category_id
}
lappend channel_list -1001


set service_list_sql "
	select distinct
		coalesce(
			(select min(im_category_parents) from im_category_parents(category_id)), 
			category_id
		) as category_id
	from	im_categories
	where	category_type = 'Intranet Ticket Type'
	order by category_id
"
set service_list [list]
db_foreach service $service_list_sql {
    lappend service_list $category_id
}
lappend service_list -1002




# ----------------------------------------------------------------
# Initialize the columns
# ----------------------------------------------------------------

set header ""
foreach area_id $area_list {
    set row($area_id) ""
}
set footer ""


# ----------------------------------------------------------------
# Calculate information by channel
# ----------------------------------------------------------------

set dimension_vars [list area_id channel_id]
set dimension_perms [im_report_take_all_ordered_permutations $dimension_vars]
# ad_return_complaint 1 $dimension_perms

set channel_sql "
	select  count(*) as aggregate,
		coalesce(
			(select min(im_category_parents) from im_category_parents(t.ticket_area_id)), 
			t.ticket_area_id
		) as area_id,
		coalesce(
			(select min(im_category_parents) from im_category_parents(t.ticket_incoming_channel_id)), 
			t.ticket_incoming_channel_id
		) as channel_id
	from    im_tickets t,
		im_projects p,
		acs_objects o
	where   t.ticket_id = p.project_id and
		t.ticket_id = o.object_id
	group by area_id, channel_id
"

#		o.creation_date >= :start_date and
#		o.creation_date < :end_date


db_foreach channel_hash $channel_sql {

    set area [im_category_from_id -translate_p 0 $area_id]
    set channel [im_category_from_id -translate_p 0 $channel_id]

    if {"" == $area_id} {
	set area_id -1000
	set area "undefined_area"
    }
    if {"" == $channel_id} {
	set channel_id -1001
	set channel "undefined_channel"
    }

    ns_log Notice "report-area:"
    ns_log Notice "report-area: area_id=$area_id, channel_id=$channel_id"

    foreach perm $dimension_perms {

	# Add a "$" before every variable
	set perm_subs [list]
	foreach p $perm { lappend perm_subs "\$$p" }

	set key_expr [join $perm_subs "-"]
	set key [eval "set a \"$key_expr\""]
	
	set sum 0
	if {[info exists channel_hash($key)]} { set sum $channel_hash($key) }
	if {"" == $aggregate} { set aggregate 0 }
	set sum [expr $sum + $aggregate]
	set channel_hash($key) $sum
	ns_log Notice "report-area: key=$key, agg=$aggregate, perm=$perm => sum=$sum"
    }
}



# ----------------------------------------------------------------
# Format the data 

append header "<td class=rowtitle></td>"
foreach channel_id $channel_list {
    append header "<td class=rowtitle>[im_category_from_id -translate_p 0 $channel_id]</td>\n"
}
append header "<td class=rowtitle>$sigma</td>\n"

foreach area_id $area_list {
    set row($area_id) "<td>[im_category_from_id -translate_p 0 $area_id]</td>\n"
    foreach channel_id $channel_list {
	set val "-"
	set key "$area_id-$channel_id"
	if {[info exists channel_hash($key)]} { set val $channel_hash($key) }
	append row($area_id) "<td>$val</td>"
    }

    # Last Column
    set val "-"
    set key $area_id
    if {[info exists channel_hash($key)]} { set val $channel_hash($key) }
    append row($area_id) "<td>$val</td>"
}

append footer "<td>$sigma</td>\n"
foreach channel_id $channel_list {
    set val "-"
    set key "$channel_id"
    if {[info exists channel_hash($key)]} { set val $channel_hash($key) }
    append footer "<td>$val</td>"
}

# Last Column
set val "-"
set key ""
if {[info exists channel_hash($key)]} { set val $channel_hash($key) }
append footer "<td>$val</td>"







# ----------------------------------------------------------------
# Calculate information by service
# ----------------------------------------------------------------

set dimension_vars [list area_id service_id]
set dimension_perms [im_report_take_all_ordered_permutations $dimension_vars]
# ad_return_complaint 1 $dimension_perms

set service_sql "
	select  count(*) as aggregate,
		coalesce(
			(select min(im_category_parents) from im_category_parents(t.ticket_area_id)), 
			t.ticket_area_id
		) as area_id,
		coalesce(
			(select min(im_category_parents) from im_category_parents(t.ticket_service_type_id)), 
			t.ticket_service_type_id
		) as service_id
	from    im_tickets t,
		im_projects p,
		acs_objects o
	where   t.ticket_id = p.project_id and
		t.ticket_id = o.object_id
	group by area_id, service_id
"

#		o.creation_date >= :start_date and
#		o.creation_date < :end_date


db_foreach service_hash $service_sql {

    set area [im_category_from_id -translate_p 0 $area_id]
    set service [im_category_from_id -translate_p 0 $service_id]

    if {"" == $area_id} {
	set area_id -1000
	set area "undefined_area"
    }
    if {"" == $service_id} {
	set service_id -1002
	set service "undefined_service"
    }

    ns_log Notice "report-area:"
    ns_log Notice "report-area: area_id=$area_id, service_id=$service_id"

    foreach perm $dimension_perms {

	# Add a "$" before every variable
	set perm_subs [list]
	foreach p $perm { lappend perm_subs "\$$p" }

	set key_expr [join $perm_subs "-"]
	set key [eval "set a \"$key_expr\""]
	
	set sum 0
	if {[info exists service_hash($key)]} { set sum $service_hash($key) }
	if {"" == $aggregate} { set aggregate 0 }
	set sum [expr $sum + $aggregate]
	set service_hash($key) $sum
	ns_log Notice "report-area: key=$key, agg=$aggregate, perm=$perm => sum=$sum"
    }
}


# ----------------------------------------------------------------
# Format the data 

append header "<td class=rowtitle></td>"
foreach service_id $service_list {
    append header "<td class=rowtitle>[im_category_from_id -translate_p 0 $service_id]</td>\n"
}
append header "<td class=rowtitle>$sigma</td>\n"

foreach area_id $area_list {
    append row($area_id) "<td>[im_category_from_id -translate_p 0 $area_id]</td>\n"
    foreach service_id $service_list {
	set val "-"
	set key "$area_id-$service_id"
	if {[info exists service_hash($key)]} { set val $service_hash($key) }
	append row($area_id) "<td>$val</td>"
    }

    # Last Column
    set val "-"
    set key $area_id
    if {[info exists service_hash($key)]} { set val $service_hash($key) }
    append row($area_id) "<td>$val</td>"
}

append footer "<td>$sigma</td>\n"
foreach service_id $service_list {
    set val "-"
    set key "$service_id"
    if {[info exists service_hash($key)]} { set val $service_hash($key) }
    append footer "<td>$val</td>"
}

# Last Column
set val "-"
set key ""
if {[info exists service_hash($key)]} { set val $service_hash($key) }
append footer "<td>$val</td>"



# ----------------------------------------------------------------
# Join the area rows
# ----------------------------------------------------------------

set body ""
foreach area_id $area_list {
    ns_log Notice "report-area: area_id=$area_id"
    append body "<tr>$row($area_id)</tr>\n"
}


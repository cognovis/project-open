# /packages/intranet-sencha-ticket-tracker/www/report-area.tcl
#
# Copyright (c) 2011 ]ticket-open[
#
# All rights reserved. Please check
# http://www.ticket-open.com/ for licensing details.

ad_page_contract {
    SPRI Cube
} {
    { output_format "html" }
    { start_date "" }
    { end_date "" }
    { locale "es_ES" }
    { perc_p 1 }
    { channel_p 1 }
    { type_p 0 }
    { queue_p 0 }
}


# ----------------------------------------------------------------
# Constants & Security 
# ----------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-sencha-ticket-tracker.Report_Tickets_por_Area "Tickets por Area"]
set sigma "&Sigma;"
set days_in_past 0

db_1row todays_date "
select
	to_char(sysdate::date - :days_in_past::integer, 'YYYY') as todays_year,
	to_char(sysdate::date - :days_in_past::integer, 'MM') as todays_month,
	to_char(sysdate::date - :days_in_past::integer, 'DD') as todays_day
from dual
"

if {"" == $start_date} { 
    set start_date "$todays_year-$todays_month-01"
}

db_1row end_date "
select
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'YYYY') as end_year,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'MM') as end_month,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'DD') as end_day
from dual
"

if {"" == $end_date} { 
    set end_date "$end_year-$end_month-01"
}


# Check that Start & End-Date have correct format
if {"" != $start_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if {"" != $end_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $end_date]} {
    ad_return_complaint 1 "End Date doesn't have the right format.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

# ----------------------------------------------------------------
# Dereferencing Function
# ----------------------------------------------------------------

ad_proc -public v { 
    var_name
    {undef "-"}
} {
    Acts like a "$" to evaluate a variable, but
    returns "-" if the variable is not defined
    instead of an error.
} {
    upvar $var_name var
    if [exists_and_not_null var] { return $var }
    return $undef
} 


# ----------------------------------------------------------------
# Dimensions
# ----------------------------------------------------------------

set area_list_sql "
	select distinct
		coalesce(
			(select min(im_category_parents) from im_category_parents(category_id)), 
			category_id
		) as area_id
	from	im_categories
	where	category_type = 'Intranet Sencha Ticket Tracker Area'
	order by area_id
"
set area_list [list]
db_foreach area_sql $area_list_sql {
    lappend area_list $area_id
}
lappend area_list -1000


set program_list_sql "
	select
		coalesce(
			(select min(im_category_parents) from im_category_parents(c.category_id)), 
			c.category_id
		) as area_id,
		c.category_id as program_id
	from	im_categories c
	where	c.category_type = 'Intranet Sencha Ticket Tracker Area'
	order by area_id, program_id
"
db_foreach program_sql $program_list_sql {
    if {$area_id == $program_id} { continue }
    # exclude areas that somehow got into the list
    if {[lsearch $area_list $program_id] > -1} { continue }
    set program_list [v program_list_hash($area_id) {}]
    lappend program_list $program_id
    set program_list_hash($area_id) $program_list
}

# ad_return_complaint 1 "<pre>[join [array get program_list_hash] "<br>"]</pre>"


# ----------------------------------------------------------------
# Initialize the columns and show total
# ----------------------------------------------------------------

set top_header ""
set header ""
foreach area_id $area_list {
    set row($area_id) ""

    set area_footer($area_id) ""
    switch $output_format {
	html { append area_footer($area_id) "<td>Total</td>\n" }
	csv  { append area_footer($area_id) "\"Total\";" }
    }
}
set footer ""

switch $output_format {
    html {  
	append top_header "<td class=rowtitle></td>\n"
	append top_header "<td class=rowtitle align=center colspan=2>Actividad</td>\n"
	append header "<td class=rowtitle></td>"
	append header "<td class=rowtitle>Total</td>\n"
	append header "<td class=rowtitle>Total %</td>\n"
    }
    csv  {  
	append top_header "\"\"; "
	append top_header "\"Actividad\";\"\";"
	append header "\"\";"
	append header "\"Total\";"
	append header "\"Total %\";"
    }
}



set dimension_vars [list area_id program_id]
set dimension_perms [im_report_take_all_ordered_permutations $dimension_vars]

set total_sql "
	select  coalesce(
			(select min(im_category_parents) from im_category_parents(t.ticket_area_id)), 
			t.ticket_area_id
		) as area_id,
		t.ticket_area_id as program_id
	from    im_tickets t,
		im_projects p,
		acs_objects o
	where   t.ticket_id = p.project_id and
		t.ticket_id = o.object_id and
		o.creation_date >= :start_date and
		o.creation_date < :end_date
"

set total_aggregate_sql "
	select	count(*) as aggregate,
		area_id,
		program_id
	from	($total_sql) t
	group by
		area_id,
		program_id
"

db_foreach total_hash $total_aggregate_sql {
    if {"" == $area_id} { set area_id -1000 }
    foreach perm $dimension_perms {
	# Add a "$" before every variable
	set perm_subs [list]
	foreach p $perm { lappend perm_subs "\$$p" }
	set key_expr [join $perm_subs "-"]
	set key [eval "set a \"$key_expr\""]
	set sum [v total_hash($key) 0]
	set sum [expr $sum + $aggregate]
	set total_hash($key) $sum
    }
}

# The total number of tickets is stored in the bucket
# without any dimension vars
set total_tickets [v total_hash() 0]

# Add the total to all areas
foreach area_id $area_list {
    set row($area_id) ""
    set total_ticket_for_area [v total_hash($area_id) 0]

    # -------------------------------------
    # Area name (from category)
    switch $output_format {
	html { append row($area_id) "<td>[im_category_from_id -translate_p 0 $area_id]</td>\n" }
	csv  { append row($area_id) "\"[im_category_from_id -translate_p 0 $area_id]\";" }
    }

    # -------------------------------------
    # Total and Total %
    set val [v total_hash($area_id) 0]
    if {[catch { set perc "[lc_numeric [expr round(1000.0 * $val / $total_tickets) / 10.0] "" $locale]%" }]} { set perc "undef" }

    switch $output_format {
	html {  
	    append row($area_id) "<td align=right>$val</td>"
	    append area_footer($area_id) "<td align=right>$val</td>"
	    append row($area_id) "<td align=right>$perc</td>"
	    append area_footer($area_id) "<td align=right>$perc</td>"
	}
	csv  {  
	    append row($area_id) "\"$val\";"
	    append area_footer($area_id) "\"$val\";"
	    append row($area_id) "\"$perc\";"
	    append area_footer($area_id) "\"$perc\";"
	}
    }


    # -------------------------------------
    # Repeat the same procedure for the programs contained in the area
    set program_list [v program_list_hash($area_id) ""]
    foreach program_id $program_list {
	set val [v total_hash($program_id) 0]
	if {[catch { set perc "[lc_numeric [expr round(1000.0 * $val / $total_tickets) / 10.0] "" $locale]%" }]} { set perc "undef" }

	switch $output_format {
	    html {  
		append row($program_id) "<td>[im_category_from_id -translate_p 0 $program_id]</td>\n"
		append row($program_id) "<td align=right>$val</td>"
		append row($program_id) "<td align=right>$perc</td>"
	    }
	    csv  {  
		append row($program_id) "\"[im_category_from_id -translate_p 0 $program_id]\";\"$val\";\"$perc\";"
	    }
	}
    }
}

switch $output_format {
    html {  
	append footer "<td>Total</td>\n"
	append footer "<td align=right>$total_tickets</td>\n"
	append footer "<td align=right>100.0%</td>\n"
    }
    csv  {  
	append footer "\"Total\";\"$total_tickets\";\"100\";"
    }
}


# ----------------------------------------------------------------
# Calculate information by channel
# ----------------------------------------------------------------

if {$channel_p} {

    set dimension_vars [list area_id program_id channel_level1_id channel_id]
    set dimension_perms [im_report_take_all_ordered_permutations $dimension_vars]
    
    # ----------------------------------------------------------------
    # Get the list of all channels
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
    

    # ----------------------------------------------------------------
    # Select out the number of tickets per dimension variable
    
    set channel_sql "
	select  coalesce(
			(select min(im_category_parents) from im_category_parents(t.ticket_area_id)), 
			t.ticket_area_id
		) as area_id,
		t.ticket_area_id as program_id,
		coalesce(
			(select min(im_category_parents) from im_category_parents(t.ticket_incoming_channel_id)), 
			t.ticket_incoming_channel_id
		) as channel_level1_id,
		t.ticket_incoming_channel_id - 10000000 as channel_id
	from    im_tickets t,
		im_projects p,
		acs_objects o
	where   t.ticket_id = p.project_id and
		t.ticket_id = o.object_id and
		o.creation_date >= :start_date and
		o.creation_date < :end_date
    "

    set channel_aggregate_sql "
	select	count(*) as aggregate,
		area_id,
		program_id,
		channel_level1_id,
		channel_id
	from	($channel_sql) t
	group by
		area_id,
		program_id,
		channel_level1_id,
		channel_id
    "

    # Write the values from the SQL into a hash array and aggregate
    db_foreach channel_hash $channel_aggregate_sql {

	if {"" == $area_id}			{ set area_id -1000 }
	if {"" == $program_id}		{ set program_id -1004 }
	if {"" == $channel_id} 		{ set channel_id -1001 }
	if {"" == $channel_level1_id} 	{ set channel_level1_id -1002 }
	
	foreach perm $dimension_perms {
	    # Add a "$" before every variable
	    set perm_subs [list]
	    foreach p $perm { lappend perm_subs "\$$p" }
	    set key_expr [join $perm_subs "-"]
	    set key [eval "set a \"$key_expr\""]
	    set sum [v channel_hash($key) 0]
	    set sum [expr $sum + $aggregate]
	    set channel_hash($key) $sum
	    ns_log Notice "report-area: key=$key, agg=$aggregate, perm=$perm => sum=$sum"
	}
    }
    
    # ----------------------------------------------------------------
    # Calculate the list of incoming channels with values != 0
    set channels_with_values_list [list]
    foreach channel_id $channel_list {
	
	set val [v channel_hash($channel_id) 0]
	if {0 != $val} {
	    lappend channels_with_values_list $channel_id
	    
	    # Disable for debugging
	    # continue
	    
	    # Check for sub-categories with values
	    set subcats [im_sub_categories $channel_id]
	    foreach sub_channel_id $subcats {
		set sub_channel_id [expr $sub_channel_id - 10000000]
		if {0 == $sub_channel_id} { continue }
		if {$channel_id == $sub_channel_id} { continue }
		set val [v channel_hash($sub_channel_id) 0]
		if {0 != $val} {
		    lappend channels_with_values_list $sub_channel_id
		}
	    }
	}
    }
    
    # ----------------------------------------------------------------
    # Format the data 
    
    switch $output_format {
	html {  
	    append top_header "<td class=rowtitle></td>\n"
	    append header "<td class=rowtitle></td>\n"
	}
	csv  {  
	    append top_header "\"\";"
	    append header "\"\";"
	}
    }

    set cnt 0
    foreach channel_id $channels_with_values_list {
	set channel [im_category_from_id $channel_id]
	if {$channel_id < 1000} { 
	    # Ugly. Restore the category
	    switch $output_format {
		html { set channel "Sub-Cat<br>[im_category_from_id [expr $channel_id + 10000000]]" }
		csv  { set channel "Sub-Cat [im_category_from_id [expr $channel_id + 10000000]]" }
	    }
	}
	if {$channel_id < 0} { set channel "N/C" }
	
	switch $output_format {
	    html { append header "<td class=rowtitle>$channel</td>\n" }
	    csv  { append header "\"$channel\";" }
	}
	
	if {$perc_p} { 
	    switch $output_format {
		html { append header "<td class=rowtitle>%</td>\n"  }
		csv  { append header "\"%\";"  }
	    }
	}
	incr cnt
    }
    switch $output_format {
	html { 
	    append top_header "<td class=rowtitle align=center colspan=[expr (1+$perc_p)*$cnt]>Por Canal</td>\n" 
	}
	csv  { 
	    append top_header "\"Por Canal\";"
	    for {set i 0} {$i < [expr (1+$perc_p)*$cnt - 1]} {incr i} { append top_header "\"\";" }
	}
    }
    
    # Constants defined for channels
    set telephone_channel_id 10000036
    set email_channel_id 10000089
    set empty_channel_id -1001
    
    
    foreach area_id $area_list {
	set total_ticket_for_area [v channel_hash($area_id) 0]
	
	# -------------------------------------
	# Area empty colum
	switch $output_format {
	    html {  
		append row($area_id) "<td align=right></td>"
		append area_footer($area_id) "<td align=right></td>"
	    }
	    csv  {  
		append row($area_id) "\"\";"
		append area_footer($area_id) "\"\";"
	    }
	}

	
	# List of category values
	foreach channel_id $channels_with_values_list {
	    set key "$area_id-$channel_id"
	    set val [v channel_hash($key) ""]
	    switch $output_format {
		html {  
		    append row($area_id) "<td align=right>$val</td>"
		    append area_footer($area_id) "<td align=right>$val</td>"
		}
		csv  {  
		    append row($area_id) "\"$val\";"
		    append area_footer($area_id) "\"$val\";"
		}
	    }
	    
	    if {$perc_p} {
		if {[catch { set perc [lc_numeric [expr round(1000.0 * $val / $total_ticket_for_area) / 10.0] "" $locale] }]} { set perc "undef" }
		set perc "$perc%"
		if {"" == $val} { set perc "" }
		switch $output_format {
		    html {  
			append row($area_id) "<td align=right>$perc</td>"
			append area_footer($area_id) "<td align=right>$perc</td>"
		    }
		    csv  {  
			append row($area_id) "\"$perc\";"
			append area_footer($area_id) "\"$perc\";"
		    }
		}
	    }
	}
	
	# -------------------------------------
	# Repeat the same procedure for the programs contained in the area
	set program_list [v program_list_hash($area_id) ""]
	foreach program_id $program_list {
	    set total_ticket_for_program [v channel_hash($program_id) 0]
	    switch $output_format {
		html { append row($program_id) "<td align=right></td>" }
		csv  { append row($program_id) "\"\";" }
	    }
	    
	    foreach channel_id $channels_with_values_list {
		set key "$program_id-$channel_id"
		set val [v channel_hash($key) ""]
		switch $output_format {
		    html { append row($program_id) "<td align=right>$val</td>" }
		    csv  { append row($program_id) "\"$val\";" }
		}
		if {$perc_p} {
		    if {[catch { set perc [lc_numeric [expr round(1000.0 * $val / $total_ticket_for_program) / 10.0] "" $locale] }]} { set perc "undef" }
		    set perc "$perc%"
		    if {"" == $val} { set perc "" }
		    switch $output_format {
			html { append row($program_id) "<td align=right>$perc</td>" }
			csv  { append row($program_id) "\"$perc\";" }
		    }
		}
	    }
	}
    }
    
    # Deal with footer
    switch $output_format {
	html { append footer "<td align=right></td>" }
	csv  { append footer "\"\";" }
    }
    
    foreach channel_id $channels_with_values_list {
	set key "$channel_id"
	set val [v channel_hash($key) 0]
	switch $output_format {
	    html { append footer "<td align=right>$val</td>" }
	    csv  { append footer "\"$val\";" }
	}
	if {$perc_p} { 
	    switch $output_format {
		html { append footer "<td align=right></td>"  }
		csv  { append footer "\"\";"  }
	    }
	}
    }
    
}


# ----------------------------------------------------------------
# Calculate information by service
# ----------------------------------------------------------------

if {$type_p} {

    set dimension_vars [list area_id program_id type_level1_id type_id]
    set dimension_perms [im_report_take_all_ordered_permutations $dimension_vars]

    set type_list_sql "
	select distinct
		coalesce(
			(select min(im_category_parents) from im_category_parents(category_id)), 
			category_id
		) as category_id
	from	im_categories
	where	category_type = 'Intranet Ticket Type'
	order by category_id
    "
    set type_list [list]
    db_foreach type $type_list_sql {
	lappend type_list $category_id
    }
    lappend type_list -1002
    

    set type_sql "
	select  coalesce(
			(select min(im_category_parents) from im_category_parents(t.ticket_area_id)), 
			t.ticket_area_id
		) as area_id,
		t.ticket_area_id as program_id,
		coalesce(
			(select min(im_category_parents) from im_category_parents(t.ticket_type_id)), 
			t.ticket_type_id
		) as type_level1_id,
		t.ticket_type_id - 10000000 as type_id
	from    im_tickets t,
		im_projects p,
		acs_objects o
	where   t.ticket_id = p.project_id and
		t.ticket_id = o.object_id and
		o.creation_date >= :start_date and
		o.creation_date < :end_date
    "

    set type_aggregate_sql "
	select	count(*) as aggregate,
		area_id,
		program_id,
		type_level1_id,
		type_id
	from	($type_sql) t
	group by
		area_id,
		program_id,
		type_level1_id,
		type_id
    "
   
    db_foreach type_hash $type_aggregate_sql {
	
	if {"" == $area_id}			{ set area_id -1000 }
	if {"" == $program_id}		{ set program_id -1004 }
	if {"" == $type_id} 		{ set type_id -1001 }
	if {"" == $type_level1_id}		{ set type_level1_id -1002 }

	foreach perm $dimension_perms {
	    # Add a "$" before every variable
	    set perm_subs [list]
	    foreach p $perm { lappend perm_subs "\$$p" }
	    set key_expr [join $perm_subs "-"]
	    set key [eval "set a \"$key_expr\""]
	    set sum [v type_hash($key) 0]
	    set sum [expr $sum + $aggregate]
	    set type_hash($key) $sum
	    ns_log Notice "report-area: key=$key, agg=$aggregate, perm=$perm => sum=$sum"
	}
    }


    # ----------------------------------------------------------------
    # Calculate the list of incoming types with values != 0
    set types_with_values_list [list]
    foreach type_id $type_list {
	
	set val [v type_hash($type_id) 0]
	if {0 != $val} {
	    lappend types_with_values_list $type_id
	    
	    # Disable sub-categories for ticket_type
	    continue
	    
	    # Check for sub-categories with values
	    set subcats [im_sub_categories $type_id]
	    foreach sub_type_id $subcats {
		set sub_type_id [expr $sub_type_id - 10000000]
		if {0 == $sub_type_id} { continue }
		if {$type_id == $sub_type_id} { continue }
		set val [v type_hash($sub_type_id) 0]
		if {0 != $val} {
		    lappend types_with_values_list $sub_type_id
		}
	    }
	}
    }

    # ----------------------------------------------------------------
    # Format the data 

    switch $output_format {
	html {  
	    append top_header "<td class=rowtitle></td>"
	    append header "<td class=rowtitle></td>"
	}
	csv  {  
	    append top_header "\"\";"
	    append header "\"\";"
	}
    }

    set cnt 0
    foreach type_id $types_with_values_list {
	set type [im_category_from_id $type_id]
	if {$type_id < 1000} { 
	    # Ugly. Restore the category
	    set type "Sub-Cat<br>[im_category_from_id [expr $type_id + 10000000]]"
	}
	if {$type_id < 0} { set type "N/C" }
	switch $output_format {
	    html { append header "<td class=rowtitle>$type</td>\n" }
	    csv  { append header "\"$type\";" }
	}
	if {$perc_p} { 
	    switch $output_format {
		html { append header "<td class=rowtitle>%</td>\n"  }
		csv  { append header "\"%\";"  }
	    }
	}
	incr cnt
    }
    switch $output_format {
	html { append top_header "<td class=rowtitle align=center colspan=[expr (1+$perc_p)*$cnt]>Por Servicio</td>\n" }
	csv  { 
	    append top_header "\"Por Servicio\";" 
	    for {set i 0} {$i < [expr (1+$perc_p)*$cnt - 1]} {incr i} { append top_header "\"\";" }
	}
    }
    

    
    set total_tickets [v type_hash() 0]
    
    # Constants defined for types
    set telephone_type_id 10000036
    set email_type_id 10000089
    set empty_type_id -1001


    foreach area_id $area_list {
	set total_ticket_for_area [v type_hash($area_id) 0]
	
	# -------------------------------------
	# Area name (from category)
	switch $output_format {
	    html {  
		append row($area_id) "<td></td>\n"
		append area_footer($area_id) "<td></td>\n"
	    }
	    csv  {  
		append row($area_id) "\"\";"
		append area_footer($area_id) "\"\";"
	    }
	}

	
	# List of category values
	foreach type_id $types_with_values_list {
	    set key "$area_id-$type_id"
	    set val [v type_hash($key) ""]
	    switch $output_format {
		html {  
		    append row($area_id) "<td align=right>$val</td>"
		    append area_footer($area_id) "<td align=right>$val</td>"
		}
		csv  {  
		    append row($area_id) "\"$val\";"
		    append area_footer($area_id) "\"$val\";"
		}
	    }
	    if {$perc_p} {
		if {[catch { set perc [lc_numeric [expr round(1000.0 * $val / $total_ticket_for_area) / 10.0] "" $locale] }]} { set perc "undef" }
		set perc "$perc%"
		if {"" == $val} { set perc "" }
		switch $output_format {
		    html {  
			append row($area_id) "<td align=right>$perc</td>"
			append area_footer($area_id) "<td align=right>$perc</td>"		    
		    }
		    csv  {  
			append row($area_id) "\"$perc\";"
			append area_footer($area_id) "\"$perc\";"		    
		    }
		}

	    }
	}
	
	# -------------------------------------
	# Repeat the same procedure for the programs contained in the area
	set program_list [v program_list_hash($area_id) ""]
	foreach program_id $program_list {
	    set total_ticket_for_program [v type_hash($program_id) 0]
	    switch $output_format {
		html { append row($program_id) "<td></td>\n" }
		csv  { append row($program_id) "\"\";" }
	    }
	    foreach type_id $types_with_values_list {
		set key "$program_id-$type_id"
		set val [v type_hash($key) ""]
		switch $output_format {
		    html { append row($program_id) "<td align=right>$val</td>" }
		    csv  { append row($program_id) "\"$val\";" }
		}
		if {$perc_p} {
		    if {[catch { set perc [lc_numeric [expr round(1000.0 * $val / $total_ticket_for_program) / 10.0] "" $locale] }]} { set perc "undef" }
		    set perc "$perc%"
		    if {"" == $val} { set perc "" }
		    switch $output_format {
			html { append row($program_id) "<td align=right>$perc</td>" }
			csv  { append row($program_id) "\"$perc\";" }
		    }
		}
	    }
	}
    }
    
    switch $output_format {
	html { append footer "<td></td>\n" }
	csv  { append footer "\"\";" }
    }
    
    foreach type_id $types_with_values_list {
	set key "$type_id"
	set val [v type_hash($key)]
	switch $output_format {
	    html { append footer "<td align=right>$val</td>" }
	    csv  { append footer "\"$val\";" }
	}
	if {$perc_p} { 
	    switch $output_format {
		html { append footer "<td align=right></td>"  }
		csv  { append footer "\"\";"  }
	    }
	}
    }
}



# ----------------------------------------------------------------
# Calculate information by queue
# ----------------------------------------------------------------

if {$queue_p} {

    set dimension_vars [list area_id program_id queue_id]
    set dimension_perms [im_report_take_all_ordered_permutations $dimension_vars]

    set queue_list_sql "
	select distinct
		ticket_queue_id
	from	im_tickets
	where	ticket_queue_id is not null
	order by ticket_queue_id
    "
    set queue_list [list]
    db_foreach queue $queue_list_sql {
	lappend queue_list $ticket_queue_id
    }
    lappend queue_list -1003
    

    set queue_sql "
	select  coalesce(
			(select min(im_category_parents) from im_category_parents(t.ticket_area_id)), 
			t.ticket_area_id
		) as area_id,
		t.ticket_area_id as program_id,
		t.ticket_queue_id as queue_id
	from    im_tickets t,
		im_projects p,
		acs_objects o
	where   t.ticket_id = p.project_id and
		t.ticket_id = o.object_id and
		o.creation_date >= :start_date and
		o.creation_date < :end_date
    "

    set queue_aggregate_sql "
	select	count(*) as aggregate,
		area_id,
		program_id,
		queue_id
	from	($queue_sql) t
	group by
		area_id,
		program_id,
		queue_id
    "

    db_foreach queue_hash $queue_aggregate_sql {
	
	if {"" == $area_id}			{ set area_id -1000 }
	if {"" == $program_id}		{ set program_id -1004 }
	if {"" == $queue_id} 		{ set queue_id -1003 }
	
	ns_log Notice "---------------------------------------------------------------"
	ns_log Notice "report-area: aggregate=$aggregate, area_id=$area_id, queue_id=$queue_id"
	ns_log Notice ""
	
	foreach perm $dimension_perms {
	    # Add a "$" before every variable
	    set perm_subs [list]
	    foreach p $perm { lappend perm_subs "\$$p" }
	    set key_expr [join $perm_subs "-"]
	    set key [eval "set a \"$key_expr\""]
	    set sum [v queue_hash($key) 0]
	    set sum [expr $sum + $aggregate]
	    set queue_hash($key) $sum
	    ns_log Notice "report-area: key=$key, agg=$aggregate, perm=$perm => sum=$sum"
	}
    }
    
    # ad_return_complaint 1 [array get queue_hash]

    # ----------------------------------------------------------------
    # Calculate the list of queues
    set queues_with_values_list [list]
    foreach queue_id $queue_list {
	set val [v queue_hash($queue_id) 0]
	if {0 != $val} {
	    lappend queues_with_values_list $queue_id
	}
    }

    # ad_return_complaint 1 $queues_with_values_list
    
    # ----------------------------------------------------------------
    # Format the data 

    switch $output_format {
	html {  
	    append top_header "<td class=rowtitle></td>"
	    append header "<td class=rowtitle></td>"
	}
	csv  {  
	    append top_header "\"\";"
	    append header "\"\";"
	}
    }

    set cnt 0
    foreach queue_id $queues_with_values_list {
	set queue [db_string queue "select acs_object__name(:queue_id)"]
	if {"Employees" == $queue} { set queue "No escalado" }
	if {"" == $queue} { set queue $queue_id }
	if {-1003 == $queue} { set queue "N/C" }
	switch $output_format {
	    html { append header "<td class=rowtitle>$queue</td>\n" }
	    csv  { append header "\"$queue\";" }
	}
	if {$perc_p} { 
	    switch $output_format {
		html { append header "<td class=rowtitle>%</td>\n"  }
		csv  { append header "\"%\";"  }
	    }
	}
	incr cnt
    }
    
    switch $output_format {
	html { 
	    append top_header "<td class=rowtitle align=center colspan=[expr (1+$perc_p)*$cnt]>Por Escalado</td>\n" 
	}
	csv  { 
	    append top_header "\"Por Escalado\";" 
	    for {set i 0} {$i < [expr (1+$perc_p)*$cnt - 1]} {incr i} { append top_header "\"\";" }
	}
    }
    
    
    foreach area_id $area_list {
	set total_ticket_for_area [v queue_hash($area_id) 0]
	
	# -------------------------------------
	# Area name (from category)
	switch $output_format {
	    html {  
		append row($area_id) "<td></td>\n"
		append area_footer($area_id) "<td></td>\n"
	    }
	    csv  {  
		append row($area_id) "\"\";"
		append area_footer($area_id) "\"\";"
	    }
	}
	
	# List of queues
	foreach queue_id $queues_with_values_list {
	    set key "$area_id-$queue_id"
	    set val [v queue_hash($key) ""]
	    switch $output_format {
		html {  
		    append row($area_id) "<td align=right>$val</td>"
		    append area_footer($area_id) "<td align=right>$val</td>"
		}
		csv  {  
		    append row($area_id) "\"$val\";"
		    append area_footer($area_id) "\"$val\";"
		}
	    }
	    if {$perc_p} {
		if {[catch { set perc [lc_numeric [expr round(1000.0 * $val / $total_ticket_for_area) / 10.0] "" $locale] }]} { set perc "undef" }
		set perc "$perc%"
		if {"" == $val} { set perc "" }
		switch $output_format {
		    html {  
			append row($area_id) "<td align=right>$perc</td>"
			append area_footer($area_id) "<td align=right>$perc</td>"
		    }
		    csv  {  
			append row($area_id) "\"$perc\";"
			append area_footer($area_id) "\"$perc\";"
		    }
		}
	    }
	}
	
	# -------------------------------------
	# Repeat the same procedure for the programs contained in the area
	set program_list [v program_list_hash($area_id) ""]
	foreach program_id $program_list {
	    set total_ticket_for_program [v queue_hash($program_id) 0]
	    switch $output_format {
		html { append row($program_id) "<td></td>\n" }
		csv  { append row($program_id) "\"\";" }
	    }
	    foreach queue_id $queues_with_values_list {
		set key "$program_id-$queue_id"
		set val [v queue_hash($key) ""]
		switch $output_format {
		    html { append row($program_id) "<td align=right>$val</td>" }
		    csv  { append row($program_id) "\"$val\";" }
		}
		if {$perc_p} {
		    if {[catch { set perc [lc_numeric [expr round(1000.0 * $val / $total_ticket_for_program) / 10.0] "" $locale] }]} { set perc "undef" }
		    set perc "$perc%"
		    if {"" == $val} { set perc "" }
		    switch $output_format {
			html { append row($program_id) "<td align=right>$perc</td>" }
			csv  { append row($program_id) "\"$perc\";" }
		    }
		}
	    }
	}
    }
    
    switch $output_format {
	html { append footer "<td></td>\n" }
	csv  { append footer "\"\";" }
    }
    foreach queue_id $queues_with_values_list {
	set key "$queue_id"
	set val [v queue_hash($key)]
	switch $output_format {
	    html { append footer "<td align=right>$val</td>" }
	    csv  { append footer "\"$val\";" }
	}
	if {$perc_p} { 
	    switch $output_format {
		html { append footer "<td align=right></td>"  }
		csv  { append footer "\"\";"  }
	    }
	}
    }
    
}


# ----------------------------------------------------------------
# Join the area rows
# ----------------------------------------------------------------

set body ""
switch $output_format {
    html {  
	append body "<table cellspacing=5 cellpadding=5>"
	append body "<tr class=rowtitle valign=top>$top_header</tr>\n"
	append body "<tr class=rowtitle valign=top>$header</tr>\n"
    }
    csv  {  
	append body "$top_header\n"
	append body "$header\n"
    }
}
foreach area_id $area_list {
    switch $output_format {
	html { append body "<tr>$row($area_id)</tr>\n" }
	csv  { append body "$row($area_id)\n" }
    }
}
switch $output_format {
    html { append body "<tr class=roweven>$footer</tr>\n" }
    csv  { append body "$footer\n" }
}

set cnt 0
foreach area_id $area_list {
    set area_name [im_category_from_id $area_id]
    if {"" == $area_id || -1000 == $area_id} { set area_name "N/C" }
    switch $output_format {
	html {  
	    append body "<tr><td>&nbsp;</td></tr>\n"
	    append body "<tr class=rowtitle><td class=rowtitle colspan=999>$area_name</td></tr>\n"
	    append body "<tr class=rowtitle valign=top>$top_header</tr>\n"
	    append body "<tr class=rowtitle valign=top>$header</tr>\n"
	}
	csv  {  
	    append body "\n"
	    append body "\"$area_name\"\n"
	    append body "$top_header\n"
	    append body "$header\n"
	}
    }

    set program_list [v program_list_hash($area_id) ""]
    foreach program_id $program_list {
	switch $output_format {
	    html { append body "<tr>$row($program_id)</tr>\n" }
	    csv  { append body "$row($program_id)\n" }
	}
    }
    switch $output_format {
	html { append body "<tr class=roweven>$area_footer($area_id)</tr>\n" }
	csv  { append body "$area_footer($area_id)\n" }
    }
    incr cnt
}

switch $output_format {
    html { append body "</table>\n" }
    csv  { append body "\n" }
}


switch $output_format {
    csv  { 
	set content_type [im_report_content_type -output_format $output_format]
	
	set tcl_encoding [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvTclCharacterEncoding -default "iso8859-1" ]
	set app_type [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvContentType -default "application/csv"]
	set charset [parameter::get_from_package_key -package_key intranet-dw-light -parameter CsvHttpCharacterEncoding -default "iso-8859-1"]

	if {"utf-8" == $tcl_encoding} {
	    set body_latin1 $body
	} else {
	    set body_latin1 [encoding convertto $tcl_encoding $body]
	}
	
	# For some reason we have to send out a "hard" HTTP
	# header. ns_return and ns_respond don't seem to convert
	# the content body into the right Latin1 encoding.
	# So we do this manually here...
	set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $app_type; charset=$charset\r\n"
	util_WriteWithExtraOutputHeaders $all_the_headers
	ns_write $body_latin1
	ad_script_abort
    }
}

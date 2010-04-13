# /packages/intranet-trans-quality/tcl/intranet-trans-quality-procs.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author guillermo.belcic@project-open.com
    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# Constant functions
# ----------------------------------------------------------------------


# Frequently used Company Stati
ad_proc -public im_transq_premium_quality {} { return 110 }
ad_proc -public im_transq_high_quality {} { return 111 }
ad_proc -public im_transq_average_quality {} { return 112 }
ad_proc -public im_transq_draft_quality {} { return 113 }
ad_proc -public im_transq_machine_quality {} { return 114 }



# ----------------------------------------------------------------------
# Helper functions that include constants
# ----------------------------------------------------------------------

ad_proc -public im_transq_total_errors { minor_errors major_errors critical_errors } {
    Returns the total number of error points, 
    given the number of min, maj and crit errors.
} {
    set total_errors 0
    if {"" != $minor_errors} { set total_errors $minor_errors }
    if {"" != $major_errors} { set total_errors [expr $total_errors + $major_errors*5] }
    if {"" != $critical_errors} { set total_errors [expr $total_errors + $critical_errors*10] }

    return $total_errors
}


ad_proc -public im_transq_error_percentage { expected_quality_id } {
    Returns the percentage of error points allowed
    for a given quality level
} {
    set allowed_error_percentage 5
    switch $expected_quality_id {
	110 { # Premium Quality
	    set allowed_error_percentage 1
	}
	111 { # High Quality
	    set allowed_error_percentage 2
	}
	112 { # Average Quality
	    set allowed_error_percentage 5
	}
	113 { # Draft Qaulity
	    set allowed_error_percentage 10
	}
	114 { # Machine Qaulity
	    set allowed_error_percentage 20
	}
    }
    return $allowed_error_percentage
}

# ----------------------------------------------------------------------
# Components
# ----------------------------------------------------------------------

ad_proc im_quality_project_component { 
	-project_id 
	{-return_url "" } 
} {
    Returns a formatted HTML component that shows a relative q-diagram
    and link a the quality controler page
} {
    set user_id [ad_get_user_id]
    if {![im_project_has_type $project_id "Translation Project"]} { return "" }
    if {![im_permission $user_id view_trans_quality]} { return "" }

    db_0or1row sql_n_tasks "
	select	count(qr.task_id) as n_reports
	from	im_trans_tasks t,
		im_trans_quality_reports qr
	where	qr.task_id = t.task_id
		and t.project_id = :project_id
    "

    if {0 == $n_reports} {
	set result "<ul><li>No quality reports for this project</li>"
    } else {

	set quality_sql "
		select
			count(*) as cnt,
			q
		from	
			(select
				CASE WHEN q <= -4 THEN 4 WHEN q >= 4 THEN 4 ELSE q END as q
			from
				(select	round(log((0.0001 + allowed_error_percentage/100.0*sample_size) / (0.0001+total_errors)) / log(2)) as q
				from	im_trans_tasks t,
					im_trans_quality_reports qr
				where	qr.task_id = t.task_id
					and t.project_id = :project_id
				) t
			)t
		group by q	
	"
   	db_foreach q $quality_sql {
	    set qual($q) $cnt
	}

	set start_value 3
	set continue 1
	while {$continue} {
	    set continue 0
	    set neg_start_value [expr -$start_value]
	    if {![info exists qual($start_value)] && ![info exists qual($neg_start_value)]} { 
		set continue 1
		set start_value [expr $start_value - 1]
	    }
	}

	set msg [lang::message::lookup "" intranet-trans-quality.Allowed_error_points "Allowed error points"]
	set text(-3) "*8 $msg"
	set text(-2) "*4 $msg"
	set text(-1) "*2 $msg"
	set text(0)  " = $msg"
	set text(1)  "/2 $msg"
	set text(2)  "/4 $msg"
	set text(3)  "/8 $msg"
       	
	set values [list]
	for {set q $neg_start_value} {$q <= $start_value} {incr q} {
	    set count 0
	    set name $q
	    if {[info exists qual($q)]} { set count $qual($q) }
	    if {[info exists text($q)]} { set name $text($q) }
	    lappend values [list $name $count]
	}

	append result [im_dashboard_histogram \
                -values $values \
		-diagram_width 250 \
	]


	append result "<br>\n"
	append result "<li><a href=/intranet-trans-quality/list?[export_url_vars project_id]>See all reports for this project</a>\n"

    }

    if {[im_permission $user_id add_trans_quality]} {
	append result "<li><a href=/intranet-trans-quality/new?[export_url_vars project_id]>Add a Quality Report for this Project</a>\n"
    }

    append result "</ul>\n"
    return $result
}



# ----------------------------------------------------------------------
# Graphics Components
# ----------------------------------------------------------------------

ad_proc im_transq_gif { name width height alt } {
    Returns a GIF component
} {
    return "<img src=\"/intranet-trans-quality/images/$name.gif\" width=$width height=$height alt=\"$alt\" border=0>"
}


# ----------------------------------------------------------------------
# List Component
# ----------------------------------------------------------------------


ad_proc -public im_quality_list_component {
    {-project_id 0 }
    {-trans_id 0 }
    {-edit_id 0 }
    {-proof_id 0 }
    {-other_id 0 }
    {-person_id 0 }
    {-company_id 0 }
    {-order_by "" }
    {-how_many "" }
    {-start_idx 0 }
    {-view_name "transq_task_list" }
    {-quality_group ""}
    {-return_url "" }
} {
    Shows a list of quality reports according to the filters
    @author frank.bergmann@project-open.com
} {
    # User id already verified by filters
    set user_id [ad_get_user_id]
    if {![im_permission $user_id view_trans_quality]} { return "" }

    set local_url "list"
    if {"" == $return_url } { set return_url [im_url_with_query] }
    if { "" == $how_many} { set how_many [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage "" 50] }
    set end_idx [expr $start_idx + $how_many - 1]

    # ---------------------------------------------------------------
    # Defined Table Fields
    # ---------------------------------------------------------------

    # Define the column headers and column contents that 
    # we want to show:
    #
    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
    if {!$view_id} { ad_return_complaint 1 "<li>[_ intranet-trans-quality.lt_Didnt_find_the_the_view] '$view_name'"}
    set column_headers [list]
    set column_vars [list]

    set column_sql "
	select	column_name,
		column_render_tcl,
		visible_for
	from	im_view_columns
	where	view_id = :view_id
		and group_id is null
	order by sort_order
    "
    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    regsub -all " " $column_name "_" column_key
	    lappend column_headers "[_ intranet-trans-quality.$column_key]"
	    lappend column_vars "$column_render_tcl"
	}
    }

    # ---------------------------------------------------------------
    # Generate SQL Query
    # ---------------------------------------------------------------
    
    set criteria [list]
    if { 0 != $project_id } { lappend criteria "p.project_id = :project_id" }
    if { 0 != $company_id } { lappend criteria "p.company_id = :company_id" }
    if { 0 != $trans_id } { lappend criteria "t.trans_id = :trans_id" }
    if { 0 != $edit_id } { lappend criteria "t.edit_id = :edit_id" }
    if { 0 != $proof_id } { lappend criteria "p.proof_id = :proof_id" }
    if { 0 != $other_id } { lappend criteria "p.other_id = :other_id" }
    if { 0 != $person_id } {
	# person_id => somehow related to this quality report...
	lappend criteria "(p.trans_id = :person_id OR p.edit_id = :person_id OR p.proof_id = :person_id OR p.other_id = :person_id)"
    }

    set order_by_clause ""
    switch $order_by {
	"Task Name" { set order_by_clause "order by t.task_name DESC" }
	"Source" { set order_by_clause "order by t.source_language_id" }
	"Target" { set order_by_clause "order by t.target_language_id" }
	"Units" { set order_by_clause "order by t.task_units" }
	"Quality" { set order_by_clause "order by expected_quality_id" }
	"Due Date" { set order_by_clause "order by total_errors / allowed_errors DESC" }
	default { set order_by_clause "order by t.task_name DESC" }
    }
    
    set where_clause [join $criteria " and\n            "]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }


    # -----------------------------------------------------------------
    # Permissions
    # -----------------------------------------------------------------
    
    # Normally, the user should only see the quality reports
    # of projects where he as been directly assigned to.
    #
    set perm_sql "
        (select	p.*
        from	im_projects p,
		acs_rels r
        where	r.object_id_one = p.project_id
                and r.object_id_two = :user_id
                $where_clause
        )
    "
    
    # ... except if he's an employee or higher,
    # then he can see all projects.
    #
    if {[im_permission $user_id "view_projects_all"]} {
        set perm_sql "im_projects"
    }


    # -----------------------------------------------------------------
    # Main SQL
    # -----------------------------------------------------------------
    
    set sql "
	select
		t.task_name,
		t.task_units,
		im_category_from_id(t.source_language_id) as source_language,
		im_category_from_id(t.target_language_id) as target_language,
		qr.*,
		p.project_name,
		im_category_from_id(p.expected_quality_id) as expected_quality,
		c.company_name
	from
		im_trans_tasks t,
		im_trans_quality_reports qr,
		$perm_sql p,
		im_companies c
	where
		qr.task_id = t.task_id
		and t.project_id = p.project_id
		and p.company_id = c.company_id
	        $where_clause
	$order_by_clause
    "

    # ---------------------------------------------------------------
    # Limit the SQL query to MAX rows and provide << and >>
    # ---------------------------------------------------------------
    
    # Limit the search results to N data sets only
    # to be able to manage large sites
    #
    
    set limited_query [im_select_row_range $sql $start_idx $end_idx]
    set total_in_limited [db_string total_in_limited "
        select count(*)
        from ($sql) s
    "]
    set selection "select z.* from ($limited_query) z $order_by_clause"

    # ---------------------------------------------------------------
    # Format the List Table Header
    # ---------------------------------------------------------------

    # Set up colspan to be the number of headers + 1 for the # column
    set colspan [expr [llength $column_headers] + 1]
    
    set table_header_html ""
    
    # Format the header names with links that modify the
    # sort order of the SQL query.
    #
    set url "$local_url?"
    set query_string [export_ns_set_vars url [list order_by]]
    if { ![empty_string_p $query_string] } {
	append url "$query_string&"
    }
    
    append table_header_html "<tr>\n"
    foreach col $column_headers {
	if { [string compare $order_by $col] == 0 } {
	    append table_header_html "  <td class=rowtitle>$col</td>\n"
	} else {
	    append table_header_html "  <td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col</a></td>\n"
	}
    }
    append table_header_html "</tr>\n"
    
    
    # ---------------------------------------------------------------
    # Format the Result Data
    # ---------------------------------------------------------------
    
    set table_body_html ""
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set ctr 0
    set idx $start_idx
    db_foreach quality_list $sql {
	
	# -4 to +4 on a logaritmic scale.
	# 0 means it's meeting the allowed error points
	set rel_quality [im_transq_rel_quality $allowed_error_percentage $sample_size $total_errors]

	if {"" != $quality_group} {
	    if {$rel_quality != $quality_group} { continue }
	}

	# Append together a line of data based on the "column_vars" parameter list
	append table_body_html "<tr$bgcolor([expr $ctr % 2])>\n"
	foreach column_var $column_vars {
	    append table_body_html "\t<td valign=top>"
	    set cmd "append table_body_html $column_var"
	    eval $cmd
	    append table_body_html "</td>\n"
	}
	append table_body_html "</tr>\n"
	
	incr ctr
	if { $how_many > 0 && $ctr >= $how_many } {
	    break
	}
	incr idx
    }
    
    # Show a reasonable message when there are no result rows:
    if { [empty_string_p $table_body_html] } {
	set table_body_html "
        <tr><td colspan=$colspan><ul><li><b> 
        [_ intranet-trans-quality.lt_There_are_currently_n]
        </b></ul></td></tr>"
    }
    
    if { $ctr == $how_many && $end_idx < $total_in_limited } {
	# This means that there are rows that we decided not to return
	# Include a link to go to the next page
	set next_start_idx [expr $end_idx + 1]
	set next_page_url "$local_url?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]"
    } else {
	set next_page_url ""
    }
    
    if { $start_idx > 0 } {
	# This means we didn't start with the first row - there is
	# at least 1 previous row. add a previous page link
	set previous_start_idx [expr $start_idx - $how_many]
	if { $previous_start_idx < 0 } { set previous_start_idx 0 }
	set previous_page_url "$local_url?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]"
    } else {
	set previous_page_url ""
    }
    


    # ---------------------------------------------------------------
    # Format Table Continuation
    # ---------------------------------------------------------------
    
    # Check if there are rows that we decided not to return
    # => include a link to go to the next page 
    #
    if {$ctr==$how_many && $total_in_limited > 0 && $end_idx < $total_in_limited} {
	set next_start_idx [expr $end_idx + 1]
	set next_page "<a href=$local_url?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]>[_ intranet-trans-quality.Next_Page]</a>"
    } else {
	set next_page ""
    }

    # Check if this is the continuation of a table (we didn't start with the 
    # first row - there is at least 1 previous row.
    # => add a previous page link
    #
    if { $start_idx > 0 } {
	set previous_start_idx [expr $start_idx - $how_many]
	if { $previous_start_idx < 1 } { set previous_start_idx 0 }
	set previous_page "<a href=$local_url?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]>[_ intranet-trans-quality.Previous_Page]</a>"
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

    return "
	  <table cellpadding=2 cellspacing=2 border=0>
	    $table_header_html
	    $table_body_html
	    $table_continuation_html
	  </table>
    "
}

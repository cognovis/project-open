# /packages/intranet-reporting-dashborad/tcl/intranet-reporting-dashboard-procs.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Common procedures for Dashboard
    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# Define a color bar from red to blue or similar...
# ----------------------------------------------------------------------

ad_proc im_dashboard_pie_colors { 
    { -max_entries 8 }
    { -start_color "0080FF" }
    { -end_color "FF8000" }
} {
    Returns an array with color codes from 0.. $max_entries
    (max_entries+1 in total)
} {
    # Aux string for hex conversions
    set h "0123456789ABCDEF"

    set red_start [expr 16 * [string first [string range $start_color 0 0] $h]]
    set red_start [expr $red_start + [string first [string range $start_color 1 1] $h]]
    set green_start [expr 16 * [string first [string range $start_color 2 2] $h]]
    set green_start [expr $green_start + [string first [string range $start_color 3 3] $h]]
    set blue_start [expr 16 * [string first [string range $start_color 4 4] $h]]
    set blue_start [expr $blue_start + [string first [string range $start_color 5 5] $h]]

    set red_end [expr 16 * [string first [string range $end_color 0 0] $h]]
    set red_end [expr $red_end + [string first [string range $end_color 1 1] $h]]
    set green_end [expr 16 * [string first [string range $end_color 2 2] $h]]
    set green_end [expr $green_end + [string first [string range $end_color 3 3] $h]]
    set blue_end [expr 16 * [string first [string range $end_color 4 4] $h]]
    set blue_end [expr $blue_end + [string first [string range $end_color 5 5] $h]]

    set max [expr $max_entries + 1]

    set blue_incr [expr 1.0 * ($blue_end - $blue_start) / $max]
    set red_incr [expr 1.0 * ($red_end - $red_start) / $max]
    set green_incr [expr 1.0 * ($green_end - $green_start) / $max]

    for {set i 0} {$i <= $max_entries} {incr i} {
        set blue [expr round($blue_start + round($i*$blue_incr))]
        set red [expr round($red_start + round($i*$red_incr))]
        set green [expr round($green_start + round($i*$green_incr))]
    
        set red_low [expr $red % 16]
        set red_high [expr round($red / 16)]
        set blue_low [expr $blue % 16]
        set blue_high [expr round($blue / 16)]
        set green_low [expr $green % 16]
        set green_high [expr round($green / 16)]
    
        set col "\#[string range $h $red_high $red_high][string range $h $red_low $red_low]"
        append col "[string range $h $green_high $green_high][string range $h $green_low $green_low]"
        append col "[string range $h $blue_high $blue_high][string range $h $blue_low $blue_low]"
    
        set pie_colors($i) $col
    }
    return [array get pie_colors]
}



# ----------------------------------------------------------------------
# Draw a reasonable Pie chart
# ----------------------------------------------------------------------

ad_proc im_dashboard_pie_chart { 
    { -max_entries 8 }
    { -values {} }
    { -bar_y_size 15 }
    { -bar_x_size 100 }
    { -perc_x_size 50 }
    { -radius 90 }
    { -bar_distance 5 }
    { -bar_text_limit "" }
    { -outer_distance 20 }
    { -start_color "0080FF" }
    { -end_color "FF8000" }
    { -font_color "000000" }
    { -font_size 8 }
    { -font_style "font-family:Verdana;font-weight:normal;line-height:10pt;" }
} {
    Returns a formatted HTML text to display a piechart
    based on Lutz Tautenhahn' "Javascript Diagram Builder", v3.3.
    @param max_entries Determines the max. number of entries
           in the pie chart. It also determines the Y-size of the diagram.
    @param values A list of {name value} pairs to be displayed.
           Values must be numeric (comparable using the "<" operator).

    Short example:
	<pre>set pie_chart [im_dashboard_pie_chart \
        -max_entries 3 \
	-values {{Abc 10} {Bcde 20} {Cdefg 30} {Defg 25}} \
        -start_color "0080FF" \
	-end_color "80FF80"]</pre>

			       
} {
    if {[llength $values] < $max_entries} { set max_entries [llength $values] }

    set perc_x_start [expr $outer_distance + 2 * $radius + $outer_distance]
    set perc_x_end [expr $perc_x_start + $perc_x_size]

    set bar_x_start [expr $perc_x_end + $bar_distance]
    set bar_x_end [expr $bar_x_start + $bar_x_size]

    set diagram_x_size [expr $bar_x_end + $outer_distance]
    set diagram_y_size [expr $outer_distance + ($max_entries+1) * ($bar_y_size + $bar_distance) + $outer_distance]
    set diagram_y_size_circle [expr $outer_distance + 2*$radius + $outer_distance]
    if {$diagram_y_size_circle > $diagram_y_size} { set diagram_y_size $diagram_y_size_circle }
    
    if {"" == $bar_text_limit} { set bar_text_limit [expr round($bar_x_size / $font_size)] }

    # Get a range of suitable colors
    array set pie_colors [im_dashboard_pie_colors \
	-max_entries $max_entries \
	-start_color $start_color \
	-end_color $end_color \
    ]

    # Sum up the values as a 100% base to calculate percentages
    set pie_sum 0
    foreach value $values {
        set val [lindex $value 1]
        set pie_sum [expr $pie_sum + $val]
    }
    if {0 == $pie_sum} { set pie_sum 0.00001}
    
    # Sort list according to value (2nd element)
    set values [reverse [qsort $values [lambda {s} { lindex $s 1 }]]]
    
    # Format the elements
    set pie_pieces_html ""
    set pie_bars_html ""
    set count 0
    set angle 0
    foreach pie_degree $values {
        if {$count > $max_entries} { continue }

        set key [lindex $pie_degree 0]
        set val [lindex $pie_degree 1]
        set perc [expr round($val * 1000.0 / $pie_sum) / 10.0]
        set degrees [expr $val * 360.0 / $pie_sum]

        if {$count == $max_entries} { 
	    # "Other" section - fill the circle
	    set key "Other"
	    set degrees [expr 360.0 - $angle]
	    set perc [expr round(1000.0 * $degrees / 360.0) / 10.0]
	}

        set col $pie_colors($count)
        append pie_pieces_html "P\[$count\]=new Pie([expr $radius+$outer_distance], [expr $radius+$outer_distance], 0, $radius, [expr round($angle-0.5)], [expr $angle+$degrees+0.5], \"$col\");\n"

        set angle [expr $angle+$degrees]
        set perc_text "${perc}%"
        set pie_text [string range $key 0 $bar_text_limit]

	set perc_y_start [expr $outer_distance + $count * ($bar_y_size + $bar_distance)]
	set perc_y_end [expr $perc_y_start + $bar_y_size]
	set bar_y_start $perc_y_start
	set bar_y_end $perc_y_end

        append pie_bars_html "new Bar(
		$perc_x_start, $perc_y_start, $perc_x_end, $perc_y_end, 
		\"$col\", \"$perc_text\", \"\", \"\",  \"void(0)\", \"MouseOver($count)\", \"MouseOut($count)\"
	);\n"
    
        append pie_bars_html "new Bar(
		$bar_x_start, $bar_y_start, $bar_x_end, $bar_y_end, 
		\"$col\", \"$pie_text\", \"\", \"\",  \"void(0)\", \"MouseOver($count)\", \"MouseOut($count)\"
	);\n"
    
        incr count
    }
    
    set border "border:2px solid blue; "
    set border ""

    return "
        <SCRIPT Language=JavaScript src=/resources/diagram/diagram/diagram.js></SCRIPT> 
        <div style='$border position:relative;top:0px;height:${diagram_y_size}px;width:${diagram_x_size}px;'>
        <SCRIPT Language=JavaScript>
        P=new Array();
        document.open();
        _BFont=\"color:\#$font_color;font-size:${font_size}pt;$font_style\";
    
        $pie_pieces_html
        $pie_bars_html
    
        document.close();
        function MouseOver(i) { P\[i\].MoveTo(\"\",\"\",10); }
        function MouseOut(i) { P\[i\].MoveTo(\"\",\"\",0); }
        </SCRIPT>
        </div>
    "
}


# ----------------------------------------------------------------------
# Get Cube data finance
# ----------------------------------------------------------------------

ad_proc im_dashboard_finance_cube {
    { -start_date "1900-01-01" }
    { -end_date "2099-12-31" }
    { -left_vars "customer_name" }
    { -top_vars "" }
    { -cost_type_id {3700} }
    { -customer_type_id 0 }
    { -customer_id 0 }
} {
    Returns a list containing:
    - An array with the cube data
    - An array for the left dimension
    - An array for the top dimension
} {
    # ------------------------------------------------------------
    # Defaults
    
    set sigma "&Sigma;"
    
    # The complete set of dimensions - used as the key for
    # the "cell" hash. Subtotals are calculated by dropping on
    # or more of these dimensions
    set dimension_vars [concat $top_vars $left_vars]
    
    # ------------------------------------------------------------
    # Conditional SQL Where-Clause
    #
    
    set criteria [list]
    
    if {"" != $customer_id && 0 != $customer_id} {
        lappend criteria "c.customer_id = :customer_id"
    }
    if {1} {
        lappend criteria "c.cost_type_id in ([join [im_sub_categories $cost_type_id] ", "])"
    }
    if {"" != $customer_type_id && 0 != $customer_type_id} {
        lappend criteria "pcust.company_type_id in ([join [im_sub_categories $customer_type_id] ", "])"
    }
    set where_clause [join $criteria " and\n\t\t\t"]
    if { ![empty_string_p $where_clause] } {
        set where_clause " and $where_clause"
    }
    
    
    # ------------------------------------------------------------
    # Define the report - SQL, counters, headers and footers 
    #
    
    # Inner - Try to be as selective as possible and select
    # the relevant data from the fact table.
    set inner_sql "
    		select
    			p.project_name as sub_project_name,
    			p.project_nr as sub_project_nr,
    			p.project_type_id as sub_project_type_id,
    			p.project_status_id as sub_project_status_id,
    			tree_ancestor_key(p.tree_sortkey, 1) as main_project_sortkey,
    			trunc((c.paid_amount * 
    			  im_exchange_rate(c.effective_date::date, c.currency, 'EUR')) :: numeric
    			  , 2) as paid_amount_converted,
    			trunc((c.amount * 
    			  im_exchange_rate(c.effective_date::date, c.currency, 'EUR')) :: numeric
    			  , 2) as amount_converted,
    			c.*
    		from
    			im_costs c
    			LEFT OUTER JOIN im_projects p ON (c.project_id = p.project_id)
    		where
    			1=1
    			and c.cost_type_id in ([join $cost_type_id ", "])
    			and c.effective_date::date >= to_date(:start_date, 'YYYY-MM-DD')
    			and c.effective_date::date < to_date(:end_date, 'YYYY-MM-DD')
    			and c.effective_date::date < to_date(:end_date, 'YYYY-MM-DD')
    "
    
    # Aggregate additional/important fields to the fact table.
    set middle_sql "
    	select
    		c.*,
    		im_category_from_id(c.cost_type_id) as cost_type,
    		im_category_from_id(c.cost_status_id) as cost_status,
    		to_char(c.effective_date, 'YYYY') as year,
    		to_char(c.effective_date, 'MM') as month_of_year,
    		to_char(c.effective_date, 'Q') as quarter_of_year,
    		to_char(c.effective_date, 'IW') as week_of_year,
    		to_char(c.effective_date, 'DD') as day_of_month,
    		substring(c.cost_name, 1, 14) as cost_name_cut,
    
    		im_category_from_id(c.sub_project_type_id) as sub_project_type,
    		im_category_from_id(c.sub_project_status_id) as sub_project_status,
    
    		mainp.project_name as main_project_name,
    		mainp.project_nr as main_project_nr,
    		mainp.project_type_id as main_project_type_id,
    		im_category_from_id(mainp.project_type_id) as main_project_type,
    		mainp.project_status_id as main_project_status_id,
    		im_category_from_id(mainp.project_status_id) as main_project_status,
    
    		cust.company_name as customer_name,
    		cust.company_path as customer_path,
    		cust.company_type_id as customer_type_id,
    		im_category_from_id(cust.company_type_id) as customer_type,
    		cust.company_status_id as customer_status_id,
    		im_category_from_id(cust.company_status_id) as customer_status,
    
    		prov.company_name as provider_name,
    		prov.company_path as provider_path,
    		prov.company_type_id as provider_type_id,
    		im_category_from_id(prov.company_type_id) as provider_type,
    		prov.company_status_id as provider_status_id,
    		im_category_from_id(prov.company_status_id) as provider_status
    
    	from
    		($inner_sql) c
    		LEFT OUTER JOIN im_projects mainp ON (c.main_project_sortkey = mainp.tree_sortkey)
    		LEFT OUTER JOIN im_companies cust ON (c.customer_id = cust.company_id)
    		LEFT OUTER JOIN im_companies prov ON (c.provider_id = prov.company_id)
    	where
    		1 = 1
    		$where_clause
    "
    
    set sql "
    select
    	sum(c.amount_converted) as amount_converted,
    	sum(c.paid_amount) as paid_amount,
    	[join $dimension_vars ",\n\t"]
    from
    	($middle_sql) c
    group by
    	[join $dimension_vars ",\n\t"]
    "

    # ------------------------------------------------------------
    # Create upper date dimension
    
    # Top scale is a list of lists such as {{2006 01} {2006 02} ...}
    # The last element of the list the grand total sum.
    
    # No top dimension at all gives an error...
    if {![llength $top_vars]} { set top_vars [list year] }
    
    set top_scale_plain [db_list_of_lists top_scale "
    	select distinct	[join $top_vars ", "]
    	from		($middle_sql) c
    	order by	[join $top_vars ", "]
    "]
    lappend top_scale_plain [list $sigma $sigma $sigma $sigma $sigma $sigma]

    # ------------------------------------------------------------
    # Create a sorted left dimension
    
    # No top dimension at all gives an error...
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
    
    # ------------------------------------------------------------
    # Execute query and aggregate values into a Hash array
    
    db_foreach query $sql {
    
        # Get all possible permutations (N out of M) from the dimension_vars
        set perms [im_report_take_all_ordered_permutations $dimension_vars]
    
        # Add the invoice amount to ALL of the variable permutations.
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
	    
	    if {"" == $amount_converted} { set amount_converted 0 }
	    set sum [expr $sum + $amount_converted]
	    set hash($key) $sum
        }
    }

    return [list \
	$left_scale_plain \
	$top_scale_plain \
	[array get hash] \
    ]
}


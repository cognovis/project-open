# /packages/intranet-reporting-cubes/tcl/intranet-reporting-cubes-procs.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Cubes Data-Warehouse Reporting Component Library
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com
}

# -------------------------------------------------------
# Package Procs
# -------------------------------------------------------

ad_proc -public im_package_reporting_cubes_id {} {
    Returns the package id of the intranet-reporting-cubes module
} {
    return [util_memoize "im_package_reporting_cubes_id_helper"]
}

ad_proc -private im_package_reporting_cubes_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-reporting-cubes'
    } -default 0]
}


ad_proc -private im_reporting_cube_sort_options { options} {
    Sort options alphabetically
} {
    # Convert options list into list of list
    array set hash $options
    set attribute_list [list]
    foreach attribute [lsort [array names hash]] {
	set name $hash($attribute)
	lappend attribute_list [list $attribute $name]
    }

    # Sort the list of lists
    set sorted_attribute_list [qsort $attribute_list [lambda {s} { lindex $s 1 }]]

    # Convert list of lists into options list
    set result [list]
    foreach tuple $sorted_attribute_list {
	set att [lindex $tuple 0]
	set nam [lindex $tuple 1]
	lappend result $att
	lappend result $nam
    }
    return $result
}


# ----------------------------------------------------------------------
# Get Cube data finance
# ----------------------------------------------------------------------

ad_proc im_reporting_cubes_cube {
    {-output_format "html" }
    {-number_locale "en_US" }
    -cube_name
    { -start_date "1900-01-01" }
    { -end_date "2099-12-31" }
    { -left_vars "customer_name" }
    { -top_vars "" }
    { -cost_type_id {3700} }
    { -customer_type_id 0 }
    { -customer_status_id 0 }
    { -project_type_id 0 }
    { -project_status_id 0 }
    { -ticket_type_id 0 }
    { -ticket_status_id 0 }
    { -customer_id 0 }
    { -survey_id 0 }
    { -creation_user_id 0 }
    { -related_object_id 0 }
    { -related_context_id 0 }
    { -aggregate 0 }
    { -derefs "" }
    { -cache_days 1 }
    { -no_cache_p 0 }
} {
    Returns a DW cube as a list containing:
    - An array with the cube data
    - An array for the left dimension
    - An array for the top dimension
} {
    if {"" == $top_vars} { set top_vars "year" }

    set params(start_date) $start_date
    set params(end_date) $end_date
    set params(cost_type_id) $cost_type_id
    set params(customer_type_id) $customer_type_id
    set params(project_type_id) $project_type_id
    set params(customer_id) $customer_id
    set params_hash [array get params]

    set base_cube_id [db_string cube_id "
		select	cube_id
		from	im_reporting_cubes c
		where	c.cube_name = :cube_name
			and c.cube_params = :params_hash
			and c.cube_left_vars = :left_vars
			and c.cube_top_vars = :top_vars
    " -default ""]

    if {"" != $base_cube_id && !$no_cache_p} {
        set cached_result ""
        set cube_value_sql "
		select	*
		from
			im_reporting_cubes c,
			im_reporting_cube_values v
		where
			c.cube_id = :base_cube_id
			and c.cube_id = v.cube_id
			and v.evaluation_date >= now()-c.cube_update_interval
		order by
			v.evaluation_date DESC
		limit 1
        "
        db_foreach values $cube_value_sql {
	    set cached_result [list \
		cube $cube_name \
		evaluation_date $evaluation_date \
		top_vars $cube_top_vars \
		left_vars $cube_left_vars \
      		top_scale $value_top_scale \
      		left_scale $value_left_scale \
      		hash_array $value_hash_array \
            ]
	}
	if {"" != $cached_result} { 
	    db_dml update_counter "
		update im_reporting_cubes set
			cube_usage_counter = cube_usage_counter + 1
		where cube_id = :base_cube_id
	    "
	    return $cached_result 
	}
    }


    # Calculate the new version of the cube
    set cube_array ""
    switch $cube_name {
	finance {
	    set cube_array [im_reporting_cubes_finance \
		-start_date $start_date \
		-end_date $end_date \
		-left_vars $left_vars \
		-top_vars $top_vars \
		-cost_type_id $cost_type_id \
                -project_status_id $project_status_id \
		-customer_type_id $customer_type_id \
		-customer_id $customer_id \
		-derefs $derefs \
            ]
	}
	price {
	    set cube_array [im_reporting_cubes_price \
		-start_date $start_date \
		-end_date $end_date \
		-left_vars $left_vars \
		-top_vars $top_vars \
		-cost_type_id $cost_type_id \
		-customer_type_id $customer_type_id \
		-customer_id $customer_id \
            ]
	}
        survsimp {
            set cube_array [im_reporting_cubes_survsimp \
                -start_date $start_date \
                -end_date $end_date \
                -left_vars $left_vars \
                -top_vars $top_vars \
                -survey_id $survey_id \
                -creation_user_id $creation_user_id \
                -related_object_id $related_object_id \
                -related_context_id $related_context_id \
	    ]
        }
	project {
	    set cube_array [im_reporting_cubes_project \
		-start_date $start_date \
		-end_date $end_date \
		-left_vars $left_vars \
		-top_vars $top_vars \
		-project_type_id $project_type_id \
		-project_status_id $project_status_id \
		-customer_type_id $customer_type_id \
		-customer_id $customer_id \
		-aggregate $aggregate \
		-derefs $derefs \
            ]
	}
	ticket {
	    set cube_array [im_reporting_cubes_ticket \
		-output_format $output_format \
		-number_locale $number_locale \
		-start_date $start_date \
		-end_date $end_date \
		-left_vars $left_vars \
		-top_vars $top_vars \
		-ticket_type_id $ticket_type_id \
		-ticket_status_id $ticket_status_id \
		-customer_id $customer_id \
		-aggregate $aggregate \
		-derefs $derefs \
            ]
	}
	default {
		ad_return_complaint 1 "Not define yet: Cube $cube_name"
	}
    }
    if {"" == $cube_array} { return "" }

    array set cube $cube_array

    if {"" == $base_cube_id} {
	set base_cube_id [db_nextval "im_reporting_cubes_seq"]
	db_dml insert_cube "
		insert into im_reporting_cubes (
			cube_id,
			cube_name,
			cube_params,
			cube_top_vars,
			cube_left_vars,
			cube_update_interval
		) values (
			:base_cube_id,
			:cube_name,
			:params_hash,
			:top_vars,
			:left_vars,
			'$cache_days days'::interval
		)
	"
    }

    set cube_value_id [db_nextval "im_reporting_cube_values_seq"]

    set top_scale $cube(top_scale)
    set left_scale $cube(left_scale)
    set hash_array $cube(hash_array)

    db_dml insert_value "
	insert into im_reporting_cube_values (
		value_id,
		cube_id,
		evaluation_date,
		value_top_scale,
		value_left_scale,
		value_hash_array
	) values (
		:cube_value_id,
		:base_cube_id,
		now(),
		:top_scale,
		:left_scale,
		:hash_array
	)
    "

    return $cube_array
}


# ----------------------------------------------------------------------
# Uncached version of Finance cube
# ----------------------------------------------------------------------

ad_proc im_reporting_cubes_finance {
    { -start_date "1900-01-01" }
    { -end_date "2099-12-31" }
    { -left_vars "customer_name" }
    { -top_vars "" }
    { -cost_type_id {3700} }
    { -project_status_id 0 }
    { -customer_type_id 0 }
    { -customer_id 0 }
    { -derefs "" }
} {
    Returns a DW cube as a list containing:
    - An array with the cube data
    - An array for the left dimension
    - An array for the top dimension
} {
    # ------------------------------------------------------------
    # Defaults
    
    set sigma "&Sigma;"
    set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

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
        lappend criteria "cust.company_type_id in ([join [im_sub_categories $customer_type_id] ", "])"
    }
    if {"" != $project_status_id && 0 != $project_status_id} {
	lappend criteria "mainp.project_status_id in ([join [im_sub_categories $project_status_id] ", "])"
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
  			  im_exchange_rate(c.effective_date::date, c.currency, :default_currency)) :: numeric
  			  , 2) as paid_amount_converted,
  			trunc((c.amount * 
  			  im_exchange_rate(c.effective_date::date, c.currency, :default_currency)) :: numeric
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
    
    # handle ',' ###  
    if { "" != $derefs} {
        set derefs [concat "," [join $derefs ",\n\t\t"]]
    }

    # Aggregate additional/important fields to the fact table.
    set middle_sql "
  	select
  		c.*,
		im_cost_get_final_customer_name(c.cost_id) as final_customer_name,
  		im_category_from_id(c.cost_type_id) as cost_type,
  		im_category_from_id(c.cost_status_id) as cost_status,
		im_cost_center_name_from_id(c.cost_center_id) as cost_center,
		im_name_from_user_id(inv.company_contact_id) as customer_contact_name,
		im_category_from_id(inv.payment_method_id) as customer_payment_method,
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
                $derefs    
  	from
  		($inner_sql) c
  		LEFT OUTER JOIN im_projects mainp ON (c.main_project_sortkey = mainp.tree_sortkey)
  		LEFT OUTER JOIN im_companies cust ON (c.customer_id = cust.company_id)
  		LEFT OUTER JOIN im_companies prov ON (c.provider_id = prov.company_id)
		LEFT OUTER JOIN im_invoices inv ON (c.cost_id = inv.invoice_id)
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
    
    set top_scale [db_list_of_lists top_scale "
  	select distinct	[join $top_vars ", "]
  	from		($middle_sql) c
  	order by	[join $top_vars ", "]
    "]
    lappend top_scale [list $sigma $sigma $sigma $sigma $sigma $sigma]

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
        ns_write "</table>\n"
        return ""
    }
    
    # Scale is a list of lists. Example: {{2006 01} {2006 02} ...}
    # The last element is the grand total.
    set left_scale [db_list_of_lists left_scale "
  	select distinct	[join $left_vars ", "]
  	from		($middle_sql) c
  	order by	[join $left_vars ", "]
    "]
    set last_sigma [list]
    foreach t [lindex $left_scale 0] {
        lappend last_sigma $sigma
    }
    lappend left_scale $last_sigma
    
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
	cube "finance" \
	evaluation_date [db_string now "select now()"] \
	top_vars $top_vars \
	left_vars $left_vars \
     	top_scale $top_scale \
     	left_scale $left_scale \
     	hash_array [array get hash] \
    ]
}



# ----------------------------------------------------------------------
# Uncached version of Price cube
# ----------------------------------------------------------------------

ad_proc im_reporting_cubes_price {
    { -start_date "1900-01-01" }
    { -end_date "2099-12-31" }
    { -left_vars "uom" }
    { -top_vars "" }
    { -cost_type_id "" }
    { -customer_type_id 0 }
    { -customer_id 0 }
    { -provider_id 0 }
    { -uom_id 0 }
} {
    Returns a DW cube as a list containing:
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
    set inner_criteria [list]
    
    if {"" != $uom_id && 0 != $uom_id} {
	lappend inner_criteria "ii.item_uom_id = :uom_id"
    }
    if {"" != $customer_id && 0 != $customer_id} {
	lappend criteria "c.customer_id = :customer_id"
    }
    if {"" != $provider_id && 0 != $provider_id} {
	lappend criteria "c.provider_id = :provider_id"
    }
    if {"" != $cost_type_id} {
	lappend criteria "c.cost_type_id in ([join [im_sub_categories $cost_type_id] ", "])"
    }
    if {"" != $customer_type_id && 0 != $customer_type_id} {
	lappend criteria "pcust.company_type_id in ([join [im_sub_categories $customer_type_id] ", "])"
    }

    set where_clause [join $criteria " and\n\t\t\t"]
    set inner_where_clause [join $inner_criteria " and\n\t\t\t"]

    if { ![empty_string_p $where_clause] } { set where_clause " and $where_clause" }
    if { ![empty_string_p $inner_where_clause] } { set inner_where_clause " and $inner_where_clause" }
    
    
    # ------------------------------------------------------------
    # Define the report - SQL
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
			trunc((
				ii.price_per_unit * 
				im_exchange_rate(c.effective_date::date, c.currency, 'EUR') *
				(1.0 + i.surcharge_perc/100.0) *
				(1.0 - i.discount_perc/100.0)
			) :: numeric, 2) as price_per_unit_converted,
			c.*,
			i.*,
			ii.item_name,
			ii.item_units,
			ii.item_uom_id,
			ii.price_per_unit,
			ii.item_type_id
		from
			im_costs c
			LEFT OUTER JOIN im_projects p ON (c.project_id = p.project_id),
			im_invoices i,
			im_invoice_items ii
		where
			c.cost_id = i.invoice_id
			and i.invoice_id = ii.invoice_id
			and c.effective_date::date >= to_date(:start_date, 'YYYY-MM-DD')
			and c.effective_date::date < to_date(:end_date, 'YYYY-MM-DD')
			and c.effective_date::date < to_date(:end_date, 'YYYY-MM-DD')
			$inner_where_clause
    "
    
    # Aggregate additional/important fields to the fact table.
    set middle_sql "
	select
		im_category_from_id(item_type_id) as item_type,
		im_category_from_id(item_uom_id) as item_uom,
		c.*,

		im_category_from_id(c.cost_type_id) as cost_type,
		im_category_from_id(c.cost_status_id) as cost_status,
		to_char(c.effective_date, 'YYYY') as year,
		to_char(c.effective_date, 'MM') as month_of_year,
		to_char(c.effective_date, 'Q') as quarter_of_year,
		to_char(c.effective_date, 'IW') as week_of_year,
		to_char(c.effective_date, 'DD') as day_of_month,
    
		im_category_from_id(c.sub_project_type_id) as sub_project_type,
		im_category_from_id(c.sub_project_status_id) as sub_project_status,
    
		mainp.project_name as main_project_name,
		mainp.project_type_id as main_project_type_id,
		im_category_from_id(mainp.project_type_id) as main_project_type,
		mainp.project_status_id as main_project_status_id,
		im_category_from_id(mainp.project_status_id) as main_project_status,
		im_name_from_user_id(mainp.project_lead_id) as main_project_manager,
    
		cust.company_name as customer_name,
		cust.company_type_id as customer_type_id,
		im_category_from_id(cust.company_type_id) as customer_type,
		cust.company_status_id as customer_status_id,
    
		prov.company_name as provider_name,
		prov.company_type_id as provider_type_id,
		im_category_from_id(prov.company_type_id) as provider_type,
		prov.company_status_id as provider_status_id
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
	avg(c.price_per_unit_converted) as price_per_unit_converted,
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
    
    set top_scale [db_list_of_lists top_scale "
	select distinct	[join $top_vars ", "]
	from		($middle_sql) c
	order by	[join $top_vars ", "]
    "]
    lappend top_scale [list $sigma $sigma $sigma $sigma $sigma $sigma]

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
	ns_write "</table>\n"
	return ""
    }
    
    # Scale is a list of lists. Example: {{2006 01} {2006 02} ...}
    # The last element is the grand total.
    set left_scale [db_list_of_lists left_scale "
	select distinct	[join $left_vars ", "]
	from		($middle_sql) c
	order by	[join $left_vars ", "]
    "]
    set last_sigma [list]
    foreach t [lindex $left_scale 0] {
	lappend last_sigma $sigma
    }
    lappend left_scale $last_sigma
    
    # ------------------------------------------------------------
    # Execute query and aggregate values into a Hash array
    
    db_foreach query $sql {

	# Get all possible permutations (N out of M) from the dimension_vars
	set perms [im_report_take_all_ordered_permutations $dimension_vars]
    
	# Add the price to ALL of the variable permutations.
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
	    set count 0
	    if {[info exists hash_sum($key)]} { 
		set sum $hash_sum($key) 
		set count $hash_count($key) 
	    }
	    
	    if {"" != $price_per_unit_converted} { 
		set sum [expr $sum + $price_per_unit_converted]
		set count [expr $count + 1]

		set hash_sum($key) $sum
		set hash_count($key) $count
	    }
	}
    }

    
    # Calculate average hash
    foreach key [array names hash_sum] {
	set sum $hash_sum($key)
        set count $hash_count($key)
	set avg [expr round($sum * 1000.0 / $count) / 1000.0]
	set hash($key) $avg
    }

    return [list \
	cube "price" \
	evaluation_date [db_string now "select now()"] \
	top_vars $top_vars \
	left_vars $left_vars \
   	top_scale $top_scale \
   	left_scale $left_scale \
   	hash_array [array get hash] \
    ]
}





# ----------------------------------------------------------------------
# Uncached version of Survey
# ----------------------------------------------------------------------

ad_proc im_reporting_cubes_survsimp {
    { -start_date "1900-01-01" }
    { -end_date "2099-12-31" }
    { -left_vars "survey" }
    { -top_vars "" }
    { -survey_id 0 }
    { -creation_user_id 0 }
    { -related_object_id 0 }
    { -related_context_id 0 }
} {
    Returns a DW cube as a list containing:
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

    if {"" != $survey_id && 0 != $survey_id} {
        lappend criteria "ss.survey_id = :survey_id"
    }
    if {"" != $creation_user_id && 0 != $creation_user_id} {
        lappend criteria "srot.creation_user = :creation_user_id"
    }
    if {"" != $related_object_id && 0 != $related_object_id} {
        lappend criteria "sr.related_object_id = :related_object_id"
    }
    if {"" != $related_context_id && 0 != $related_context_id} {
        lappend criteria "sr.related_context_id = :related_context_id"
    }
    set where_clause [join $criteria " and\n\t\t\t"]
    if { ![empty_string_p $where_clause] } {
        set where_clause " and $where_clause"
    }

    # ------------------------------------------------------------
    # Define the report - SQL, counters, headers and footers
    # Inner - Try to be as selective as possible and select
    # the relevant data from the fact table.
    set inner_sql "
        select
                1 as unit,
                sqc.label as answer,
                ss.name as survey,
                sq.question_text as question,
                srot.creation_user as creation_user_id,
                srot.creation_date as response_date,
                im_name_from_user_id(srot.creation_user) as creation_user,
                acs_object__name(related_object_id) as object,
                acs_object__name(related_context_id) as context
        from
                survsimp_surveys ss,
                survsimp_questions sq,
                survsimp_responses sr,
                acs_objects srot,
                survsimp_question_responses sqr
                LEFT OUTER JOIN survsimp_question_choices sqc ON (sqr.choice_id = sqc.choice_id)
        where
                ss.survey_id = sq.survey_id and
                sq.survey_id = sr.survey_id and
                sqr.response_id = sr.response_id and
                sqr.question_id = sq.question_id and
                sr.response_id = srot.object_id
                $where_clause
    "

    # Aggregate additional/important fields to the fact table.
    set middle_sql "
        select
                s.*,
                to_char(s.response_date, 'YYYY') as year,
                to_char(s.response_date, 'MM') as month_of_year,
                to_char(s.response_date, 'Q') as quarter_of_year,
                to_char(s.response_date, 'IW') as week_of_year,
                to_char(s.response_date, 'DD') as day_of_month
        from
                ($inner_sql) s
    "

    set sql "
        select
                sum(s.unit) as units,
                [join $dimension_vars ",\n\t"]
        from
                ($middle_sql) s
        group by
                [join $dimension_vars ",\n\t"]
    "


    # ------------------------------------------------------------
    # Create upper date dimension

    # Top scale is a list of lists such as {{2006 01} {2006 02} ...}
    # The last element of the list the grand total sum.

    # No top dimension at all gives an error...
    if {![llength $top_vars]} { set top_vars [list creation_user] }

    set top_scale [db_list_of_lists top_scale "
        select distinct [join $top_vars ", "]
        from            ($middle_sql) c
        order by        [join $top_vars ", "]
    "]
    lappend top_scale [list $sigma $sigma $sigma $sigma $sigma $sigma]

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
        ns_write "</table>\n"
        return ""
    }

    # Scale is a list of lists. Example: {{2006 01} {2006 02} ...}
    # The last element is the grand total.
    set left_scale [db_list_of_lists left_scale "
        select distinct [join $left_vars ", "]
        from            ($middle_sql) c
        order by        [join $left_vars ", "]
    "]
    set last_sigma [list]
    foreach t [lindex $left_scale 0] {
        lappend last_sigma $sigma
    }
    lappend left_scale $last_sigma


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

            if {"" == $units} { set units 0 }
            set sum [expr $sum + $units]
            set hash($key) $sum
        }
    }

    return [list \
        cube "survsimp" \
        evaluation_date [db_string now "select now()"] \
        top_vars $top_vars \
        left_vars $left_vars \
        top_scale $top_scale \
        left_scale $left_scale \
        hash_array [array get hash] \
    ]
}



# ----------------------------------------------------------------------
# Get Cube data finance
# ----------------------------------------------------------------------

ad_proc im_reporting_cubes_display {
    {-output_format "html" }
    {-number_locale "en_US" }
    -hash_array
    -top_vars
    -left_vars
    -top_scale
    -left_scale
} {
    Returns a formatted piece of HTML displying a slice of a cube.
} {
    # ------------------------------------------------------------
    # Extract parameters

    array set hash $hash_array
    set dimension_vars [concat $top_vars $left_vars]

    # ------------------------------------------------------------
    # Defaults
    
    set rowclass(0) "roweven"
    set rowclass(1) "rowodd"
    
    set gray "gray"
    switch $output_format {
	html { set sigma "&Sigma;" }
	csv  { set sigma "Sum"	   }
    }
    
    set company_url "/intranet/companies/view?company_id="
    set project_url "/intranet/projects/view?project_id="
    set invoice_url "/intranet-invoices/view?invoice_id="
    set user_url "/intranet/users/view?user_id="
    set this_url [export_vars -base "/intranet-reporting/finance-cube" {start_date end_date} ]
    
    # ------------------------------------------------------------
    # Create pretty scales

    # Insert subtotal columns whenever a scale changes
    set top_scale_pretty [list]
    set last_item [lindex $top_scale 0]
    foreach scale_pretty_item $top_scale {
	for {set i [expr [llength $last_item]-2]} {$i >= 0} {set i [expr $i-1]} {

	    set last_var [lindex $last_item $i]
	    set cur_var [lindex $scale_pretty_item $i]
	    if {$last_var != $cur_var} {
		set item [lrange $last_item 0 $i]
		while {[llength $item] < [llength $last_item]} { lappend item $sigma }
		lappend top_scale_pretty $item
	    }
	}
	lappend top_scale_pretty $scale_pretty_item
	set last_item $scale_pretty_item
    }
    
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
	return ""
    }
    
    # Add subtotals whenever a "main" (not the most detailed) scale_pretty changes
    set left_scale_pretty [list]
    set last_item [lindex $left_scale 0]
    foreach scale_pretty_item $left_scale {
	
	for {set i [expr [llength $last_item]-2]} {$i >= 0} {set i [expr $i-1]} {
	    set last_var [lindex $last_item $i]
	    set cur_var [lindex $scale_pretty_item $i]
	    if {$last_var != $cur_var} {
		
		set item [lrange $last_item 0 $i]
		while {[llength $item] < [llength $last_item]} { lappend item $sigma }
		lappend left_scale_pretty $item
	    }
	}
	lappend left_scale_pretty $scale_pretty_item
	set last_item $scale_pretty_item
    }


    # ------------------------------------------------------------
    # Display the Table Header
    
    # Determine how many date rows (year, month, day, ...) we've got
    set first_cell [lindex $top_scale_pretty 0]
    set top_scale_pretty_rows [llength $first_cell]
    set left_scale_pretty_size [llength [lindex $left_scale_pretty 0]]
    
    set header ""
    for {set row 0} {$row < $top_scale_pretty_rows} { incr row } {

	switch $output_format {
	    html {
		append header "<tr class=rowtitle>\n"
		append header "<td colspan=$left_scale_pretty_size></td>\n"
	    }
	    csv {
		for {set i 0 } { $i < $left_scale_pretty_size } { incr i} { append header "\"\";" }
	    }
	}
	for {set col 0} {$col <= [expr [llength $top_scale_pretty]-1]} { incr col } {
    
	    set scale_pretty_entry [lindex $top_scale_pretty $col]
	    set scale_pretty_item [lindex $scale_pretty_entry $row]
	    
	    # Check if the previous item was of the same content
	    set prev_scale_pretty_entry [lindex $top_scale_pretty [expr $col-1]]
	    set prev_scale_pretty_item [lindex $prev_scale_pretty_entry $row]
	    
	    # Check for the "sigma" sign. We want to display the sigma
	    # every time (disable the colspan logic)
	    if {$scale_pretty_item == $sigma} { 
		switch $output_format {
		    html { append header "\t<td class=rowtitle>$scale_pretty_item</td>\n" }
		    csv  { append header "\"$scale_pretty_item\";" }
		}
		continue
	    }
	    
	    # Prev and current are same => just skip.
	    # The cell was already covered by the previous entry via "colspan"
	    if {$prev_scale_pretty_item == $scale_pretty_item} { continue }
	    
	    # This is the first entry of a new content.
	    # Look forward to check if we can issue a "colspan" command
	    set colspan 1
	    set next_col [expr $col+1]
	    while {$scale_pretty_item == [lindex [lindex $top_scale_pretty $next_col] $row]} {
		incr next_col
		incr colspan
	    }
	    switch $output_format {
		html { append header "\t<td class=rowtitle colspan=$colspan>$scale_pretty_item</td>\n" }
		csv  { 
		    append header "\"$scale_pretty_item\";" 
		    for {set i 0 } { $i < [expr $colspan-1] } { incr i} { append header "\"\";" }
		}
	    }    
	}
	switch $output_format {
	    html { append header "</tr>\n" }
	    csv  { append header "\"\"\n" }
	}
    }
    
    
    # ------------------------------------------------------------
    # Display the table body
   
    set ctr 0
    set body ""
    foreach left_entry $left_scale_pretty {
    
	set class $rowclass([expr $ctr % 2])
	incr ctr
    
	# Start the row and show the left_scale_pretty values at the left
	switch $output_format {
	    html { append body "<tr class=$class>\n" }
	    csv  { }
	}

	foreach val $left_entry { 
	    switch $output_format {
		html { append body "<td>$val</td>\n"  }
		csv  { append body "\"$val\";" }
	    }
	}
    
	# Write the left_scale_pretty values to their corresponding local 
	# variables so that we can access them easily when calculating
	# the "key".
	for {set i 0} {$i < [llength $left_vars]} {incr i} {
	    set var_name [lindex $left_vars $i]
	    set var_value [lindex $left_entry $i]
	    set $var_name $var_value
	}
	
	foreach top_entry $top_scale_pretty {
    
	    # Write the top_scale_pretty values to their corresponding local 
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

	    
	    switch $output_format {
		html { set val "&nbsp;" }
		csv  { set val "" }
	    }
	    if {[info exists hash($key)]} { 
		set val $hash($key) 
		set val [expr round(1000.0 * $val) / 1000.0]
	    }
    
	    switch $output_format {
		html { append body "<td>$val</td>\n" }
		csv  { append body "\"$val\";" }
	    }
	    
	}
	switch $output_format {
	    html { append body "</tr>\n" }
	    csv  { append body "\"\"\n" }
	}
	
    }

    switch $output_format {
	html { 
	    return "
		<table border=1 cellspacing=1 cellpadding=1 bordercolor=white>
		$header
		$body
		</table>
            "
	}
	csv  { 
	    return "${header}${body}"
	}
    }
    
}



# ----------------------------------------------------------------------
# Uncached version of Projects Cube
# ----------------------------------------------------------------------

ad_proc im_reporting_cubes_project {
    { -start_date "1900-01-01" }
    { -end_date "2099-12-31" }
    { -left_vars "customer_name" }
    { -top_vars "" }
    { -project_type_id "" }
    { -project_status_id "" }
    { -customer_type_id 0 }
    { -customer_id 0 }
    { -constraints {} }
    { -aggregate "one" }
    { -derefs "" }
} {
    Returns a DW cube as a list containing:
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

    set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
    
    # ------------------------------------------------------------
    # Conditional SQL Where-Clause
    #

    set criteria [list]
    
    if {"" != $customer_id && 0 != $customer_id} {
        lappend criteria "p.customer_id = :customer_id"
    }
    if {"" != $project_type_id && 0 != $project_type_id} {
        lappend criteria "p.project_type_id in ([join [im_sub_categories $project_type_id] ", "])"
    }
    if {"" != $project_status_id && 0 != $project_status_id} {
        lappend criteria "p.project_status_id in ([join [im_sub_categories $project_status_id] ", "])"
    }
    if {"" != $customer_type_id && 0 != $customer_type_id} {
        lappend criteria "cust.company_type_id in ([join [im_sub_categories $customer_type_id] ", "])"
    }

    set constraint_hash [array get $constraints]
    foreach key [array names constraint_hash] {
	set value $constraint_hash($key)
	lappend criteria "$key in ([join $value ","])"
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
			p.*,
			1 as one
  		from
  			im_projects p
  		where
			p.parent_id is null
  			and p.start_date::date >= to_date(:start_date, 'YYYY-MM-DD')
  			and p.start_date::date < to_date(:end_date, 'YYYY-MM-DD')
  			and p.start_date::date < to_date(:end_date, 'YYYY-MM-DD')
			$where_clause
    "

    # Aggregate additional/important fields to the fact table.
    set middle_sql "
  	select
  		p.*,
  		im_category_from_id(p.project_type_id) as project_type,
  		im_category_from_id(p.project_status_id) as project_status,


		trunc((
			im_exchange_rate(p.start_date::date, p.project_budget_currency, :default_currency) *
			p.project_budget
                ) :: numeric, 2) as project_budget_converted,

  		to_char(p.end_date, 'YYYY') as end_year,
  		to_char(p.end_date, 'MM') as end_month_of_year,
  		to_char(p.end_date, 'Q') as end_quarter_of_year,
  		to_char(p.end_date, 'IW') as end_week_of_year,
  		to_char(p.end_date, 'DD') as end_day_of_month,

  		substring(p.project_name, 1, 14) as project_name_cut,
		im_name_from_user_id(p.project_lead_id) as project_lead,

  		cust.company_name as customer_name,
  		cust.company_path as customer_path,
  		cust.company_type_id as customer_type_id,
  		im_category_from_id(cust.company_type_id) as customer_type,
  		cust.company_status_id as customer_status_id,
  		im_category_from_id(cust.company_status_id) as customer_status,

                [join $derefs ",\n\t\t"]

  	from
  		($inner_sql) p
  		LEFT OUTER JOIN im_companies cust ON (p.company_id = cust.company_id)
  	where
  		1 = 1
  		$where_clause
    "
    
    set sql "
    select
  	sum($aggregate) as aggregate,
  	[join $dimension_vars ",\n\t"]
    from
  	($middle_sql) p
    group by
  	[join $dimension_vars ",\n\t"]
    "

    # ------------------------------------------------------------
    # Create upper date dimension
    
    # Top scale is a list of lists such as {{2006 01} {2006 02} ...}
    # The last element of the list the grand total sum.
    
    # No top dimension at all gives an error...
    if {![llength $top_vars]} { set top_vars [list year] }
    
    set top_scale [db_list_of_lists top_scale "
  	select distinct	[join $top_vars ", "]
  	from		($middle_sql) c
  	order by	[join $top_vars ", "]
    "]
    lappend top_scale [list $sigma $sigma $sigma $sigma $sigma $sigma]


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
        ns_write "</table>\n"
        return ""
    }

    
    # Scale is a list of lists. Example: {{2006 01} {2006 02} ...}
    # The last element is the grand total.
    set left_scale [db_list_of_lists left_scale "
  	select distinct	[join $left_vars ", "]
  	from		($middle_sql) c
  	order by	[join $left_vars ", "]
    "]
    set last_sigma [list]
    foreach t [lindex $left_scale 0] {
        lappend last_sigma $sigma
    }
    lappend left_scale $last_sigma

    
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
	    if {"" == $aggregate} { set aggregate 0 }
	    set sum [expr $sum + $aggregate]
	    set hash($key) $sum
        }
    }

    return [list \
	cube "finance" \
	evaluation_date [db_string now "select now()"] \
	top_vars $top_vars \
	left_vars $left_vars \
     	top_scale $top_scale \
     	left_scale $left_scale \
     	hash_array [array get hash] \
    ]
}






# ----------------------------------------------------------------------
# Uncached version of Tickets Cube
# ----------------------------------------------------------------------

ad_proc im_reporting_cubes_ticket {
    {-output_format "html" }
    {-number_locale "en_US" }
    { -start_date "1900-01-01" }
    { -end_date "2099-12-31" }
    { -left_vars "customer_name" }
    { -top_vars "" }
    { -ticket_type_id "" }
    { -ticket_status_id "" }
    { -customer_id 0 }
    { -constraints {} }
    { -aggregate "one" }
    { -derefs "" }
} {
    Returns a DW cube as a list containing:
    - An array with the cube data
    - An array for the left dimension
    - An array for the top dimension
} {
    # ------------------------------------------------------------
    # Defaults
    
    switch $output_format {
	html { set sigma "&Sigma;" }
	csv  { set sigma "Sum"	   }
    }

    # The complete set of dimensions - used as the key for
    # the "cell" hash. Subtotals are calculated by dropping on
    # or more of these dimensions
    set dimension_vars [concat $top_vars $left_vars]

    # ------------------------------------------------------------
    # Conditional SQL Where-Clause
    #

    set criteria [list]
    
    if {"" != $customer_id && 0 != $customer_id} {
        lappend criteria "p.customer_id = :customer_id"
    }
    if {"" != $ticket_type_id && 0 != $ticket_type_id} {
        lappend criteria "ticket_type_id in ([join [im_sub_categories $ticket_type_id] ", "])"
    }
    if {"" != $ticket_status_id && 0 != $ticket_status_id} {
        lappend criteria "ticket_status_id in ([join [im_sub_categories $ticket_status_id] ", "])"
    }

    set constraint_hash [array get $constraints]
    foreach key [array names constraint_hash] {
	set value $constraint_hash($key)
	lappend criteria "$key in ([join $value ","])"
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
			t.*,
			p.*,
			p.project_name as ticket_name,
			p.project_nr as ticket_nr,
			o.creation_user as creation_user_id,
			o.creation_date,
			1 as one
  		from
  			im_tickets t,
			im_projects p,
			acs_objects o
  		where
			t.ticket_id = p.project_id
			and t.ticket_id = o.object_id
  			and o.creation_date >= to_date(:start_date, 'YYYY-MM-DD')
  			and o.creation_date < to_date(:end_date, 'YYYY-MM-DD')
  			and o.creation_date::date < to_date(:end_date, 'YYYY-MM-DD')
			$where_clause
    "

    # Aggregate additional/important fields to the fact table.
    set middle_sql "
  	select
  		p.*,
  		substring(p.ticket_name, 1, 14) as ticket_name_cut,
		cust.company_name,
                [join $derefs ",\n\t\t"]
  	from
  		($inner_sql) p
  		LEFT OUTER JOIN im_companies cust ON (p.company_id = cust.company_id)
  	where
  		1 = 1
  		$where_clause
    "
    
    # Select whether to sum or to "avg"
    switch $aggregate {
	"ticket_resolution_time" { 
	    set aggregate_function "round(10.0 * avg($aggregate)) / 10.0" 
	}
	"one" { 
	    # Number of tickets - don't show decimals
	    set aggregate_function "sum($aggregate)" 
	}
	default { 
	    set aggregate_function "round(10.0 * sum($aggregate)) / 10.0" 
	}
    }


    set sql "
    select
  	$aggregate_function as aggregate,
  	[join $dimension_vars ",\n\t"]
    from
  	($middle_sql) p
    group by
  	[join $dimension_vars ",\n\t"]
    "

    # ------------------------------------------------------------
    # Create upper date dimension
    
    # Top scale is a list of lists such as {{2006 01} {2006 02} ...}
    # The last element of the list the grand total sum.
    
    # No top dimension at all gives an error...
    if {![llength $top_vars]} { set top_vars [list year] }
    
    set top_scale [db_list_of_lists top_scale "
  	select distinct	[join $top_vars ", "]
  	from		($middle_sql) c
  	order by	[join $top_vars ", "]
    "]
    lappend top_scale [list $sigma $sigma $sigma $sigma $sigma $sigma]


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
        ns_write "</table>\n"
        return ""
    }

    
    # Scale is a list of lists. Example: {{2006 01} {2006 02} ...}
    # The last element is the grand total.
    set left_scale [db_list_of_lists left_scale "
  	select distinct	[join $left_vars ", "]
  	from		($middle_sql) c
  	order by	[join $left_vars ", "]
    "]
    set last_sigma [list]
    foreach t [lindex $left_scale 0] {
        lappend last_sigma $sigma
    }
    lappend left_scale $last_sigma

    
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
	    if {"" == $aggregate} { set aggregate 0 }
	    set sum [expr $sum + $aggregate]
	    set hash($key) $sum
        }
    }

    return [list \
	cube "finance" \
	evaluation_date [db_string now "select now()"] \
	top_vars $top_vars \
	left_vars $left_vars \
     	top_scale $top_scale \
     	left_scale $left_scale \
     	hash_array [array get hash] \
    ]
}


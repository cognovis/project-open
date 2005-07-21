ad_page_contract {
	testing reports	
} {

}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Invoices Report"
set context_bar [im_context_bar $page_title]
set context ""
set today [db_string today "select to_char(sysdate, 'YYYYMMDD.HHmm') from dual"]

# ------------------------------------------------------------
# Return the page header.
#

ad_return_top_of_page "[im_header]\n[im_navbar]"
ns_write "<H1>$page_title</H1>\n"


set sql "
    select
	ic.*,
	ii.*,
	to_char(ic.effective_date, 'YYYY-MM-DD') as effective_date_formatted,
	cust.company_name as customer_name,
	prov.company_name as provider_name
    from
	im_costs ic,
	im_invoices ii,
	im_companies cust,
	im_companies prov
    where
	ic.cost_id = ii.invoice_id
	and ic.customer_id = cust.company_id
	and ic.provider_id = prov.company_id
    order by
	lower(cust.company_name)

"

# counter_sum - Array with counter sums
# counter_count - Array with count information
# counter_reset - Last reset expression

set amount_counter [list pretty_name Amount var amount_subtotal reset \$customer_id expr \$amount]
set counters [list $amount_counter]

set main_row {"" $customer_name $provider_name $effective_date_formatted $amount $paid_amount}

set main_header {"$customer_name"}
set main_footer {"" "" "" "\$amount_subtotal"}


set amount_subtotal 1

ns_write "<table>\n"
db_foreach sql $sql {

    foreach counter_list $counters {
	array set counter $counter_list
	set pretty_name $counter(pretty_name)
	set reset $counter(reset)
	set var $counter(var)
	set expr $counter(expr)

	# Reset the counter if necessary
	set last_reset ""
	set reset_performed 0
	if {[info exists counter_reset($var)]} { 
	    set last_reset $counter_reset($var) 
	}
	if {$last_reset != [expr $reset]} {
	    set counter_sum($var) 0
	    set counter_count($var) 0
	    set counter_reset($var) [expr $reset]
	    set reset_performed 1
	}

	# Update the counter
	set last_sum ""
	if {[info exists counter_sum($var)]} { set last_sum $counter_sum($var) }
	set last_sum $counter_sum($var)
	set last_count $counter_count($var)
	set last_sum [expr $last_sum + $expr]
	incr last_count
	set counter_sum($var) $last_sum
	set counter_count($var) $last_count


	# Store the counter result in a local variable,
	# so that the row expressions can access it
	set $var $last_sum

    }

    
    if {$reset_performed} {
	ns_write "<tr>\n"
	foreach field $main_header {
	    set value ""
	    if {"" != $field} {
		set value [expr $field]
	    }
	    ns_write "<td>$value</td>\n"
	}
	ns_write "</tr>\n"
    }


    ns_write "<tr>\n"
    foreach field $main_row {
	set value ""
	if {"" != $field} {
	    set value [expr $field]
	}
	
	ns_write "<td>$value</td>\n"
    }
    ns_write "</tr>\n"


    if {$reset_performed} {
	ns_write "<tr>\n"
	foreach field $main_footer {
	    set value ""
	    if {"" != $field} {
		set value [expr $field]
	    }
	    ns_write "<td>$value</td>\n"
	}
	ns_write "</tr>\n"
    }

}
ns_write "<table>\n"

ns_write [im_footer]



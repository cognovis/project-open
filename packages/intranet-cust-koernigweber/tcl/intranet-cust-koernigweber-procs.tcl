# /packages/intranet-cust-koernigweber/tcl/intranet-cust-koernigweber-procs.tcl
#
# Copyright (C) 1998-2011 
 
ad_library {
    
    Customizations implementation KoernigWeber 
    @author klaus.hofeditz@project-open.com
}


# ----------------------------------------------------------------------
# Portlet
# ----------------------------------------------------------------------

ad_proc -public im_project_profitibility_component_weber {
    -user_id 
    -project_id
    -view_name
} {
    Shows WEBER specific Financial Summary
} {

      # Show only on finance 
    if { "finance" != $view_name  } { return "" }
    ns_log NOTICE "im_project_profitibility_component_weber::entering"

    # Make sure project_id is an integer...
    im_security_alert_check_integer -location "im_project_profitibility_component_weber" -value $project_id

    # Show only on main project level 
    set parent_id [db_string get_data "select parent_id from im_projects where project_id = :project_id" -default 0]
    if { "" != $parent_id  } {
	ns_log NOTICE "im_project_profitibility_component_weber::not a parent project:  parent_id found: $parent_id"
	return ""
    }

    # If user is only employee, he needs to be the PM of the project  
    if { 
   	 [im_profile::member_p -profile_id [im_employee_group_id] -user_id $user_id] && \
	 !(
		[im_profile::member_p -profile_id [im_admin_group_id] -user_id $user_id] || \
		[im_profile::member_p -profile_id [im_profile::profile_id_from_name -profile "Senior Managers"] -user_id $user_id] || \
   	        [im_profile::member_p -profile_id [im_profile::profile_id_from_name -profile "Technical Office"] -user_id $user_id] || \
		[im_profile::member_p -profile_id [im_profile::profile_id_from_name -profile "Bereichsleitung"] -user_id $user_id] \
	  )
    } {
	if { $user_id != [db_string get_data "select project_lead_id from im_projects where project_id = :project_id" -default 0] } {
	    ns_log NOTICE "im_project_profitibility_component_weber::returning empty string"
	    return ""
	}
    }

    ns_log NOTICE "im_project_profitibility_component_weber::parsing template"
    set params [list \
                    [list project_id $project_id] \
                    [list output_format "component_html"] \
                    ]
    set result [ad_parse_template -params $params "/packages/intranet-cust-koernigweber/lib/project-profitibility"]
    return [string trim $result]
}


# ---------------------------------------------------------------------
# Show the members of the Admin Group of the current Business Object.
# ---------------------------------------------------------------------

ad_proc find_sales_price {
	user_id
	project_id
	company_id
        cost_object_category_id 
    	calendar_date
} {
    Returns the sales price that has defined for a particular user
    on an arbitrary project level above    
} {

    if { ""==$calendar_date } {	set calendar_date [db_string get_data "select CURRENT_TIMESTAMP" -default 0] }
    if { "" == $project_id  } { set project_id 0 }

    ns_log NOTICE "find_sales_price: Entr: user_id: $user_id, project_id: $project_id, company_id $company_id, cost_object_category_id: $cost_object_category_id"
    
    # Make sure you look for price based on cost_object_category_id of the (sub-)project of level 'n'  
    if { "" == $cost_object_category_id } {
	set cost_object_category_id [db_string get_data "select cost_object_category_id from im_projects where project_id = $project_id" -default 0]

	# check if task -> no prices are defined for tasks 
        ns_log NOTICE "find_sales_price: No cost_object_category_id passed. Found: $cost_object_category_id"
	if { 100 == $cost_object_category_id } {    
	    set cost_object_category_id ""
	}
    }

    set amount_sales_price 0
    if { "" != $cost_object_category_id } {
	ns_log NOTICE "find_sales_price: Looking for price in current project: select amount from im_customer_prices where user_id = $user_id and object_id = $project_id"
	# Check if there's a price defined on the project itself
	set sql "
		select 
			amount 
		from 
			im_customer_prices 
		where 
			user_id = $user_id 
			and object_id = $project_id
    	"

	# Prices on projects are deprecated 
	# set amount_sales_price [db_string get_data $sql -default 0]
	set amount_sales_price 0  
    } 	

    if { 0 != $amount_sales_price} {
        ns_log NOTICE "find_sales_price: Price found: $amount_sales_price"
        ns_log NOTICE "find_sales_price: -----------------------------------------------------------"
	return $amount_sales_price
    } else {
        ns_log NOTICE "find_sales_price: No price found in project: $project_id for user: $user_id and cost_object_category_id: $cost_object_category_id ([im_category_from_id $cost_object_category_id])"
	set parent_project_id [db_string get_data "select parent_id from im_projects where project_id=$project_id" -default 0]
        ns_log NOTICE "find_sales_price: Found parent project: $parent_project_id" 
	if { ""  == $parent_project_id || 0 == $parent_project_id } {
	        # ns_log NOTICE "find_sales_price: No parent project found, now looking for price defined on customer level: user_id: $user_id, project_id: $project_id"
		# This is the super project, if no price is found, lets check if a price is defined on the user level 
		# set sql "
		#        select
		#        	amount
		#        from
	        #        	im_customer_prices
		#        where
        	#        	user_id = $user_id
		#	        and object_id = $user_id
                #		and cost_object_category_id in (select cost_object_category_id from im_projects where project_id = $project_id)
    		# "
            	# Prices on projects are deprecated
	    	# set sales_price [db_string get_data $sql -default 0]

		set sales_price 0
		if { 0 == $sales_price } {
                        ns_log NOTICE "find_sales_price: No price found for customer neither, checking now for price on user level for cost_object_category_id"
                        ns_log NOTICE "find_sales_price: -----------------------------------------------------------" 
                	set sql "
                        	select
                                	amount
	                        from (
        	                        select
                	                        cost_object_category_id,
                        	                (
                                	                select  li
                                        	        from    im_customer_prices li
                                                	where
                                                        	li.cost_object_category_id = dl.cost_object_category_id and
	                                                        user_id = $user_id and
        	                                                start_date <= :calendar_date
                	                                order by
                        	                                cost_object_category_id, start_date DESC
                                	                offset 0 limit 1
                                        	) as mid
	                                from (
        	                                select  cost_object_category_id
                	                        from    im_customer_prices lo
                        	                where   user_id = $user_id
                                	        group by cost_object_category_id
	                                     ) dl
        	                     ) dlo
	                        join    im_customer_prices l
        	                on      l.cost_object_category_id = dlo.cost_object_category_id
                                and row(l.start_date, l.id) = row(start_date, (mid).id)
                	        where
                        	        user_id = $user_id
	                                and dlo.cost_object_category_id = :cost_object_category_id
			"

	                set sales_price [db_string get_data $sql -default 0]
	                if { 0 == $sales_price } {
        	                ns_log NOTICE "find_sales_price: No price found on user level for cost_object_category_id"
                	        ns_log NOTICE "find_sales_price: -----------------------------------------------------------"
				return ""
			} else {
        	                ns_log NOTICE "find_sales_price: price found on user level for cost_object_category_id: $cost_object_category_id: $sales_price"
                	        ns_log NOTICE "find_sales_price: -----------------------------------------------------------"
				return $sales_price
			}
		} else {
                        ns_log NOTICE "find_sales_price: Price found for customer: $sales_price"
                        ns_log NOTICE "find_sales_price: -----------------------------------------------------------" 			
			return $sales_price
		}
    	} else {
                ns_log NOTICE "find_sales_price: Parent project found: $parent_project_id"
                ns_log NOTICE "find_sales_price: Calling: find_sales_price_defined_on_project_level $parent_project_id $user_id $company_id $cost_object_category_id ([im_category_from_id $cost_object_category_id])"
		return [find_sales_price $user_id $parent_project_id $company_id $cost_object_category_id $calendar_date]
	}
     }
}


ad_proc -public im_allowed_project_types { 
    company_id
} {
    Returns an portlet to view and manage prices  
} {

    # ------------------ Defaults ---------------------------------------
    set return_url "/intranet/companies/view?company_id=$company_id"

    # ------------------ Format the table header ------------------------
    set colspan 2
    set add_admin_links 1  
    set header_html "
      <tr> 
	<td class=rowtitle align=middle>[lang::message::lookup "" intranet-core.CostObject "Cost Object"]</td>
      </tr>"

    # ------------------ Format the table footer with buttons ------------
    set footer_html ""
    append footer_html "
		<br><input type=submit value='[lang::message::lookup "" intranet-core.Save "Save"]' name=submit_apply>
    "

    # ------------------ Join table header, body and footer ----------------
    set body_html [im_project_type_table $company_id]

    # ------------------ Join table header, body and footer ----------------
    set html "
	<form method=POST action=/intranet-cust-koernigweber/set-customer-cost-object>
	[export_form_vars return_url company_id]
	    <table bgcolor=white cellpadding=1 cellspacing=1 border=0>
	      $header_html
	      $body_html
	      $footer_html
	    </table>
	</form>
    "
    return $html
}


ad_proc -public im_price_list { 
    {-debug 0}
    object_id 
    user_id
    { add_admin_links 0 } 
    { return_url "" } 
    { limit_to_users_in_group_id "" } 
    { dont_allow_users_in_group_id "" } 
    { also_add_to_group_id "" } 
} {
    Returns an portlet to view and manage prices  
} {

    # include jQuery date picker
    template::head::add_javascript -src "/intranet/js/jquery-ui.custom.min.js" -order "99"
    template::head::add_css -href "/intranet/style/jquery/overcast/jquery-ui.custom.css" -media "screen" -order "99"

    # ------------------ DEFAULTS ------------------------
    set current_user_id [ad_maybe_redirect_for_registration]
    set object_type [util_memoize "db_string otype \"select object_type from acs_objects where object_id=$object_id\" -default \"\""]
    set name_order [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "NameOrder" -default 1]
    set portlet_allocation_costs_p 0

    # ------------------ PERMISSIONS ------------------------
    set admin_p 0
    if { [im_permission $current_user_id "admin_project_price_list"]} { set admin_p 1 }
    if { [im_is_user_site_wide_or_intranet_admin $user_id]} { set admin_p 1 }

    if { !$admin_p && "im_project" == $object_type } {
	# Show price list in projects only when user is a Project Manager of the project or member of Technisches Sekretariat
	if { ![im_biz_object_admin_p $user_id $object_id] && ![im_profile::member_p -profile_id 55437 -user_id $user_id] } {
	    return ""
	    break
	}
    }    

    # ------------------ Allocation costs ------------------------
    set company_type_id [db_string get_data "select company_type_id from im_companies where company_id = :object_id" -default 0]
    set internal_company_id [im_company_internal]
    if { ("im_company" == $object_type && $internal_company_id != $object_id) || ("im_company" == $object_type && 0 == [im_permission $current_user_id "admin_allocation_costs"]) } {
        return ""
        break
    } elseif {"im_company" == $object_type } {
	set portlet_allocation_costs_p 1
    }

    # ------------------ START  ------------------------

    if { "im_project" == $object_type } {
	# set global vars for project_type and budget 
        db_1row sender_get_info_1 "
        	select
                	cost_object_category_id as glob_cost_object_category_id,
                        project_budget_currency as glob_project_budget_currency
                from
                        im_projects
                where
                        project_id=:object_id
                "

	if { ![exists_and_not_null glob_cost_object_category_id] } {
	    set err_mess  [lang::message::lookup "" intranet-cust-koernigweber.CostObjectMissing "No Cost Object found, please contact your System Administrator."]
	    ad_return_complaint 1 $err_mess
	}
    } 

    # ------------------ Format the table header ------------------------
    set colspan 2
    set header_html "<tr>"

    # if { "user" != $object_type && } {
    #		append header_html "<td class=rowtitle align=left>[_ intranet-core.Name]</td>"
    # }

    if { $portlet_allocation_costs_p } {
	append header_html  "<td class=rowtitle align=left>[lang::message::lookup "" intranet-cost.Cost_Center "Cost Center"]</td>"
    } else {
	append header_html  "<td class=rowtitle align=left>[lang::message::lookup "" intranet-cust-koernigweber.CostObjectType "Cost Object Type"]</td>"
    }
    append header_html "
	<td class=rowtitle align=right>[lang::message::lookup "" intranet-core.Price "Price"]</td>
	<td class=rowtitle align=right>[lang::message::lookup "" intranet-cust-koernigweber.From_Date "From"]</td>	
    "
    if { $admin_p || $portlet_allocation_costs_p } {
        incr colspan
        append header_html "<td class=rowtitle align=middle>[im_gif delete]</td>"
    }
    append header_html "
      </tr>"

    # ------------------ Format the table body ----------------
    set td_class(0) "class=roweven"
    set td_class(1) "class=rowodd"
    set found 0
    set count 0
    set body_html ""
    set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

    if { !$portlet_allocation_costs_p } {

	# ### -----------------------------------------------------------------------------------------
	# Set table body for user/projects/companies ()   
	# ### -----------------------------------------------------------------------------------------

	# get all object members  
	if { "im_company" == $object_type } {
            set sql_query "
                select distinct
                        r.object_id_two as user_id,
			im_name_from_user_id(r.object_id_two, $name_order) as name			
                from
                        acs_rels r
                where
                        object_id_one = :object_id 
                	and rel_type = 'im_key_account_rel'
		order by 
			name
             "
	} else {
            set sql_query "
		        select distinct
                		r.object_id_two as user_id,
	                        im_name_from_user_id(r.object_id_two, $name_order) as name
			from
		                acs_rels r
		        where
                		object_id_one = $object_id
		                and rel_type = 'im_biz_object_member'
			order by 
				name
	     "
	}

	set person_list [list]

	# Create lists for Companies & Projects based on member-relationships
	if { "im_company" == $object_type || "im_project" == $object_type } {
	    db_foreach users_in_group $sql_query {
		lappend person_list $user_id
	    }
	} else {
	    lappend person_list $user_id
	}

	foreach project_member_id $person_list {
	    switch $object_type {
		"im_company" {
		    # deprecated
		    return ""
		    break
		    set inner_sql "
			select 
				id as id_price_table,
				user_id, 
				object_id as price_object_id,
				acs_object_util__get_object_type(object_id) as object_type,
				amount,
				currency,
				cost_object_category_id,			
				im_name_from_user_id(user_id, $name_order) as name, 
 				start_date
			from 
				im_customer_prices 
			where 	
				user_id = $project_member_id 
				and object_id = :object_id
				and acs_object_util__get_object_type(object_id) = 'im_company'    
			order by 
				name,
				start_date
    			"
		}

		"im_project" {
		    # Check if we have project related price record for this project_member_id 
		    set sql "
			select count(*) from im_customer_prices 
			where 
				object_id = :object_id and 
				user_id = :project_member_id and 
				currency = :glob_project_budget_currency
		    "	
			set project_related_price_exists [db_string get_data $sql -default 0]
	
			if { $project_related_price_exists } {
				set where_clause "
                        	        object_id = :object_id and
                                	user_id = :project_member_id and
	                                currency = :glob_project_budget_currency
				"
			} else {
                        	set where_clause "
					dlo.cost_object_category_id = $glob_cost_object_category_id and
		                        user_id = :project_member_id and
		                        currency = :glob_project_budget_currency
				"
			}

		    	set filter_records [ns_queryget filter_records]
			if { "" == $filter_records } {set filter_records "current" }

			switch $filter_records {
                        "current_and_future" {
                                set inner_sql "
                                        select
                                                id as id_price_table,
                                                user_id,
                                                object_id as price_object_id,
                                                amount,
                                                currency,
                                                dlo.cost_object_category_id,
                                                im_name_from_user_id(user_id, $name_order) as name,
                                                start_date
                                        from
	                                        im_customer_prices
                                        where
                                                $where_clause

	                                UNION
        	                        (
                	                       select
                        	                 l.id as id_price_table,
                                	         l.user_id,
                                        	 l.object_id as price_object_id,
	                                         l.amount,
        	                                 l.currency,
                	                         l.cost_object_category_id,
                        	                 im_name_from_user_id(l.user_id, $name_order) as name,
                                	         l.start_date
	                                        from (
        	                                        select
                	                                        cost_object_category_id,
                        	                                (
                                	                        select  li
                                        	                from    im_customer_prices li
                                                	        where
                                                        	        li.cost_object_category_id = dl.cost_object_category_id and
	                                                                user_id = $project_member_id and
        	                                                        start_date <= now()
                	                                        order by
                        	                                        cost_object_category_id, start_date DESC
                                	                        offset 0 limit 1
                                        	                ) as mid
	                                               	from    (
        	                                                select  cost_object_category_id
                	                                        from    im_customer_prices lo
                        	                                where   user_id = $project_member_id
                                	                        group by
                                        	                        cost_object_category_id
                                                	        ) dl
	                                        ) dlo
        	                        	join    im_customer_prices l
	                	                on      l.cost_object_category_id = dlo.cost_object_category_id
                        	                	and row(l.start_date, l.id) = row(start_date, (mid).id)
                                	)
                                        order by
                                                name,
                                                start_date
                                "
			}
                        "current" {
		                set inner_sql "
					select 
						id as id_price_table,
		        		        user_id,
        		       			object_id as price_object_id,
	                			amount,
				                currency,
        				        dlo.cost_object_category_id,
						im_name_from_user_id(user_id, $name_order) as name, 
						start_date
					from 
        	                                ( select
                	                                cost_object_category_id,
                        	                        (
                                	                        select  li
                                        	                from    im_customer_prices li
                                                	        where
                                                        	        li.cost_object_category_id = dl.cost_object_category_id and
                                                                	user_id = $project_member_id and
	                                                                start_date <= now()
        	                                                order by
                	                                                li.cost_object_category_id, start_date DESC
                        	                                offset 0 limit 1
                                	                ) as mid
                                        	from (
                                                	select  lo.cost_object_category_id
	                                                from    im_customer_prices lo
        	                                        where   user_id = $project_member_id
                	                                group by cost_object_category_id
                        	                     ) dl
                                	     ) dlo
	                                join    im_customer_prices l
        	                        on      l.cost_object_category_id = dlo.cost_object_category_id
                	                        and row(l.start_date, l.id) = row(start_date, (mid).id)
					where 
						$where_clause 
					order by	 
						name,
						start_date
                 		"
			}
			default {
	                        if { !$project_related_price_exists } {
                                	set where_clause "
                                        	cost_object_category_id = $glob_cost_object_category_id and
	                                        user_id = :project_member_id and
        	                                currency = :glob_project_budget_currency
                	                "
                        	}

                                set inner_sql "
                                        select
                                                id as id_price_table,
                                                user_id,
                                                object_id as price_object_id,
                                                amount,
                                                currency,
                                                cost_object_category_id,
                                                im_name_from_user_id(user_id, $name_order) as name,
                                                start_date
                                        from
						im_customer_prices
                                        where
                                                $where_clause
                                        order by
                                                name,
                                                start_date
                                "
			}
		      }; # switch
	    	}

	        "user"  {
			set filter_records [ns_queryget filter_records]
			if { "" == $filter_records } {set filter_records "current" }

		   	switch $filter_records {
			"current_and_future" {
			    set inner_sql "
        	                select
					id as id_price_table,
                        	        user_id,
                                	object_id as price_object_id,
	                                amount,
        	                        currency,
                	                cost_object_category_id,
					im_name_from_user_id(user_id, $name_order) as name, 
					start_date
	                        from
        	                        im_customer_prices
                	        where
                        	        object_id = $project_member_id and 
					start_date > now()
				UNION 
				(	
 			               select
                		         l.id as id_price_table,
                        		 l.user_id,
		                         l.object_id as price_object_id,
        		                 l.amount,
                		         l.currency,
                        		 l.cost_object_category_id,
	                        	 im_name_from_user_id(l.user_id, $name_order) as name,
	        	                 l.start_date
        	        		from (
                	        		select
                        	        		cost_object_category_id,
	                        	        	(
        	                        	        select  li
                	                        	from    im_customer_prices li
	                        	                where	
        	                        	                li.cost_object_category_id = dl.cost_object_category_id and
                	                        	        user_id = $project_member_id and
                        	                        	start_date <= now()
	                        	                order by
        	                        	                cost_object_category_id, start_date DESC
                	                        	offset 0 limit 1
	                        	        	) as mid
		                        	from    (	
	        		                        select  cost_object_category_id
        	        		                from    im_customer_prices lo
                	        		        where   user_id = $project_member_id
                        	        		group by
                                	        		cost_object_category_id
		                                	) dl
        		                ) dlo
                		join    im_customer_prices l
	                	on      l.cost_object_category_id = dlo.cost_object_category_id
	        	                and row(l.start_date, l.id) = row(start_date, (mid).id)
				)
 				order by 
					cost_object_category_id, 
					start_date
			"
			}
			"current" {
			    set inner_sql "
				select  
        	        	         l.id as id_price_table,
                	        	 l.user_id,
        	                	 l.object_id as price_object_id,
		                         l.amount,
        		                 l.currency,
                		         l.cost_object_category_id,
                        		 im_name_from_user_id(l.user_id, $name_order) as name,
		                         l.start_date
				from (
				        select 
						cost_object_category_id,
                				(
				        		select  li
						        from    im_customer_prices li
						        where   
								li.cost_object_category_id = dl.cost_object_category_id and
								user_id = $project_member_id and 
								start_date <= now()
						        order by
        		                			cost_object_category_id, start_date DESC	
					                offset 0 limit 1
        	        			) as mid
	       		 		from (
        	        			select  cost_object_category_id
			        	        from    im_customer_prices lo
						where   user_id = $project_member_id
	                			group by cost_object_category_id
			                     ) dl
	        		     ) dlo
				join	im_customer_prices l
				on      l.cost_object_category_id = dlo.cost_object_category_id
		        		and row(l.start_date, l.id) = row(start_date, (mid).id)
				order by 
					l.cost_object_category_id
	  		"
			}
	
			default {
			    set inner_sql "
                        	select
					id as id_price_table,
        	                        user_id,
                	                object_id as price_object_id,
                        	        amount,
                                	currency,
	                                cost_object_category_id,
					im_name_from_user_id(user_id, $name_order) as name, 
					start_date
                        	from
                                	im_customer_prices
	                        where
        	                        object_id = $project_member_id
 				order by 
					cost_object_category_id, 
					start_date
				"
			}
    			} ;# Filter_records	
		} ;# end object_type "user"   	

	    default { ad_return_complaint 1 "No object type found, wrong configuration, please contact your System Adminsitrator" }
	   } ;# switch object_type 

	

	db_foreach records_to_list $inner_sql {
		set show_currency_p 1
		set show_user [im_show_user_style $user_id $current_user_id $price_object_id]

		if {$debug} { ns_log Notice "im_group_member_component: user_id=$user_id, show_user=$show_user" }
		if {$show_user == 0} { continue }

		# First Column: user
		append body_html "<tr $td_class([expr $count % 2])>"

		if { "user" != $object_type  } {
			append body_html "<td><input type=hidden name=member_id value=$user_id>"
			if {$show_user > 0} {
				append body_html "<A HREF=/intranet/users/view?user_id=$user_id>$name</A>"
			} else {
				append body_html $name
			}
			append body_html "</td>"
		}


        	# Set Type (Category: Intranet Cost Object)		
		if { ![info exists cost_object_category_id] } { set cost_object_category_id "" }	

		# Decide about mode (view/edit)
        	# if  [im_permission $current_user_id "admin_company_price_matrix"] && "im_company" == $object_type 
		    # User has permission to edit company prices  
        	#    append body_html "
                #	  <td align=middle>
		#		[im_project_type_select "cost_object_category_id.${user_id}_$cost_object_category_id" $cost_object_category_id] 
	        #          </td>
        	#    "
	        #  else 
		#    # user has no permission to edit, show only 

	            append body_html "
        	          <td align=left>
				[im_category_from_id $cost_object_category_id]
	                  </td>
        	    "
        	# end if
	
		# Set price (edit/view)
	        # if [im_permission $current_user_id "admin_company_price_matrix"] && "im_company" == $object_type 
	    
	    	if { ("" != $cost_object_category_id && "im_company" == $object_type) || ("0" == $cost_object_category_id && "im_project" == $object_type ) } {
		    set var_amount "amount.${user_id}_$cost_object_category_id" 
		    set var_currency "currency.${user_id}_$cost_object_category_id"

        	    append body_html "
                	  <td align=right>
	                    <input type=input size=6 maxlength=6 name=\"$var_amount\" value=\"$amount\">&nbsp;[im_currency_select $var_currency $currency]
        	          </td>
	            "
		 } else {
	            if { "" == $amount } { 
			set amount [lang::message::lookup "" intranet-core.Not_Set "Not set"] 
			set show_currency_p 0
		    } 
        	    append body_html "<td align=right>$amount"
		    if { $show_currency_p } {append body_html "&nbsp;$currency "}
        	    append body_html "</td>"
        	 }

		# Column "From"  
		set start_date_loc [lc_time_fmt $start_date "%x" locale]
		append body_html "<td align=right>$start_date_loc</td>"

		if { (("user" == $object_type) || ("" == $cost_object_category_id && "im_project" == $object_type )) && $admin_p } {
		    set var_delete_price "delete_price.$id_price_table"
		    append body_html "
			  <td align=right>
			    <input type=checkbox name='$var_delete_price' value=''>
			  </td>
		    "
		}
		append body_html "</tr>"
		} ; # foreach records_to_list 
	    }; # db_foreach person_list 

	} else {

	        # ### -----------------------------------------------------------------------------------------
        	# Set table body for Allocation Cost Component 
	        # ### -----------------------------------------------------------------------------------------

		# To be improved: 
		# column cost_object_category_id will be used to store the CC  

		# Define inner_sql for "Allocation Costs Portlet" 	
        	set filter_records [ns_queryget filter_records]
	        if { "" == $filter_records } {set filter_records "current" }
	
		set internal_company_id [im_company_internal]

		if { "" == $internal_company_id  } {
 			ad_return_complaint 1 "No internal company found, please contact your System Administrator"
		}	

        	switch $filter_records {
	        	"current_and_future" {
	        		set inner_sql "
		                	select
                		        	id as id_price_table,
		        	                object_id as price_object_id,
                			        amount,
		                        	currency,
	        		                cost_object_category_id,
		        	                im_name_from_user_id(user_id, $name_order) as name,
                			        start_date
			                from
        			                im_customer_prices
		                	where
                		        	object_id = $internal_company_id and
	                        		start_date > now()
		        	        UNION
                			(
			                       select
        			                 l.id as id_price_table,
		                        	 l.object_id as price_object_id,
	        		                 l.amount,
		        	                 l.currency,
                			         l.cost_object_category_id,
                        			 im_name_from_user_id(l.user_id, $name_order) as name,
			                         l.start_date
        		                	from (
                		                	select
                        		                	cost_object_category_id,
                                	        		(
		                                        	select  li
	        		                                from    im_customer_prices li
        	                		                where
                	                        		        li.cost_object_category_id = dl.cost_object_category_id and
		                        	                        object_id = $internal_company_id and
                		                	                start_date <= now()
	                        		                order by
        	                                		        cost_object_category_id, start_date DESC
		                	                        offset 0 limit 1
                		        	                ) as mid
                                			from    (
	                                        		select  cost_object_category_id
		        	                                from    im_customer_prices lo
                			                        where   object_id = $internal_company_id
                        			                group by
                                	        		        cost_object_category_id
			                                        ) dl
        			                ) dlo
		                	join    im_customer_prices l
	        		        on      l.cost_object_category_id = dlo.cost_object_category_id
        	                		and row(l.start_date, l.id) = row(start_date, (mid).id)
		                	)
	        		        order by
        	                		cost_object_category_id,
		                	        start_date
        		"
	        }
        	"current" {
		        set inner_sql "
        		        select
                		         l.id as id_price_table,
                        		 l.user_id,
	                        	 l.object_id as price_object_id,
	        	                 l.amount,
        	        	         l.currency,
                	        	 l.cost_object_category_id,
	                	         im_name_from_user_id(l.user_id, $name_order) as name,
        	                	 l.start_date
	                	from (
        	                	select
                	                	cost_object_category_id,
	                	                (
        	                	                select  li
                	                	        from    im_customer_prices li
                        	                	where
	                                	                li.cost_object_category_id = dl.cost_object_category_id and
        	                                		object_id = $internal_company_id and
	        	                                        start_date <= now()
        	        	                        order by
                	        	                        cost_object_category_id, start_date DESC
                        	        	        offset 0 limit 1
	                                	) as mid
		                        from (
        		                        select  cost_object_category_id
                		                from    im_customer_prices lo
                        		        where   object_id = $internal_company_id
	                                	group by cost_object_category_id
	        	                     ) dl
        	        	     ) dlo
	        	        join    im_customer_prices l
        	        	on      l.cost_object_category_id = dlo.cost_object_category_id
                	        	and row(l.start_date, l.id) = row(start_date, (mid).id)
		                order by
        		                l.cost_object_category_id
	        	"
        	}
	       	"all" {
		        set inner_sql "
        		        select
                		        id as id_price_table,
	                        	user_id,
	        	                object_id as price_object_id,
        	        	        amount,
                	        	currency,
	                	        cost_object_category_id,
	        	                im_name_from_user_id(user_id, $name_order) as name,
        	        	        start_date
	        	        from
        	        	        im_customer_prices
	                	where
        	                	object_id = $internal_company_id
	        	        order by
        	        	        cost_object_category_id,
                	        	start_date
		       	 "	
		} ;# default    
	} ;# switch filter 

	db_foreach records_to_list $inner_sql {

		# First Column: 
		append body_html "<tr $td_class([expr $count % 2])>"
	        append body_html "
        	          <td align=left>
				[im_cost_center_name $cost_object_category_id]
	                  </td>
        	"    
        	append body_html "<td align=right>$amount &nbsp;$currency </td>"

		# Column "From"  
		set start_date_loc [lc_time_fmt $start_date "%x" locale]
		append body_html "<td align=right>$start_date_loc</td>"

		# Column "Delete"
		set var_delete_price "delete_price.$id_price_table"
		append body_html "
			  <td align=right>
			    <input type=checkbox name='$var_delete_price' value=''>
			  </td>
		"

		append body_html "</tr>"
	}

    }; # end build inner HTML for Cost Allocation  

	
    # ------------------ Set decent messages when no record found ------------

    if { [empty_string_p $body_html] } {
	set body_html "<tr><td colspan=$colspan><i>[_ intranet-core.none]</i></td></tr>\n"
    } 

    # ------------------ Add form to create new record ------------

    if { !$portlet_allocation_costs_p } {    

        if { "im_company" == $object_type } {
	    set select_box_user_sql " 
                select distinct
                        r.object_id_two as user_id,
			im_name_from_user_id(r.object_id_two) as name
                from
                        acs_rels r
                where
                        object_id_one = $object_id
                        and rel_type = 'im_key_account_rel'
             "
	} else {
            set select_box_user_sql "
                select distinct
                        r.object_id_two as user_id,
                        im_name_from_user_id(r.object_id_two) as name
                from
                        acs_rels r
                where
                        object_id_one = $object_id
		        and rel_type = 'im_biz_object_member';
           "
	}


	# Temporary deactivated for projects
	if { "im_project" != $object_type } {
	     append body_html "
        	<tr $td_class([expr $count % 2])>
                	<td>
				<br> 
				<b>[lang::message::lookup "" intranet-cust-koernig-weber.CreateNewPriceRecord "Create new price record"]:</b>
        	        </td>
                	<td>
				<br> 
				<b>[lang::message::lookup "" intranet-cust-koernig-weber.Amount "Amount"]:</b>
        	        </td>
                	<td>
                        	<br>
	                        <b>[lang::message::lookup "" intranet-cust-koernig-weber.From_Date "From"]:</b>
        	        </td>
	        </tr>
        	<tr $td_class([expr $count % 2])>
	     " 

	     if { "im_company" == $object_type || "im_project" == $object_type } {
		append body_html "
			<td>
	                      [im_selection_to_select_box "" new_user_id $select_box_user_sql new_user_id ""]
        	        </td>"	
	     }

		append body_html "<td align=middle>"
 
		if { "im_project" == $object_type } {
			 if { ![info exists cost_object_category_id ] } { set cost_object_category_id $glob_cost_object_category_id }
			 append body_html [ im_category_from_id $cost_object_category_id ]
	     	} else {
        		 append body_html [im_category_select "Intranet Cost Object" "new_cost_object_category_id" ""]
     		}

		append body_html "
                 </td>
                 <td align=right>
                    <input type=input size=6 maxlength=6 name=\"new_amount\" value=\"\">[im_currency_select new_currency $currency]
                 </td>
                 <td colspan='2'>
                    <input type=input size=10 maxlength=10 name=\"new_start_date\" id=\"new_start_date\" value=\"\">
                 </td>
		</tr>
     		"
    	}
    } else {
	# Add new price for Portlet Allocation Costs 
             append body_html "
                <tr $td_class([expr $count % 2])>
                        <td>
                                <br>
                                <b>[lang::message::lookup "" intranet-cust-koernig-weber.CreateNewPriceRecord "Create new price record"]:</b>
                        </td>
                        <td>
                                <br>
                                <b>[lang::message::lookup "" intranet-cust-koernig-weber.Amount "Amount"]:</b>
                        </td>
                        <td>
                                <br>
                                <b>[lang::message::lookup "" intranet-cust-koernig-weber.From_Date "From"]:</b>
                        </td>
                </tr>
                <tr $td_class([expr $count % 2])>
             "
		# new_cost_object_category_id holds CC 
		# append body_html "<td align=middle>[im_cost_center_select -include_empty 0 -include_empty_name 0 -department_only_p 0 "new_cost_object_category_id" ]</td>"
		set cc_company_id [im_cost_center_company]
		set cc_company_name [db_string get_data "select cost_center_name from im_cost_centers where cost_center_id = :cc_company_id" -default 0]
                append body_html "<td>$cc_company_name<input type='hidden' name='new_cost_object_category_id' value='$cc_company_id'></td>"

                append body_html "
                 <td align=right>
                    <input type=input size=6 maxlength=6 name=\"new_amount\" value=\"\">[im_currency_select new_currency $currency]
                 </td>
                 <td colspan='2'>
                    <input type=input size=10 maxlength=10 name=\"new_start_date\" id=\"new_start_date\" value=\"\">
                 </td>
                </tr>
                "
    }; # end add new price 

    # ------------------ Format the table footer with button ------------
    set footer_html ""
    if { ("im_project" == $object_type || "user" == $object_type || $portlet_allocation_costs_p) && $admin_p } {
	append footer_html "
	    <tr>
	      <td align=left colspan=$colspan>
		<br><input type=submit value='[lang::message::lookup "" intranet-core.Submit "Submit"]' name=submit_apply></td>
	      </td>
	    </tr>
	    "
    }
    # ------------------ Join table header, body and footer ----------------

   set current_checked "" 
   set current_and_future_checked ""
   set all_checked ""	

   switch [ns_queryget filter_records] {
 	"all" {
		set all_checked checked
	}
 	"current_and_future" {
		set current_and_future_checked checked
	}
 	default {
		set current_checked checked
	}
   }

    set html "
	<script>
	jQuery().ready(function(){
		\$(function() {
	    	\$( \"\#new_start_date\" ).datepicker({ dateFormat: \"yy-mm-dd\" });
		});
	});
	</script>
	<form method=POST action=/intranet-cust-koernigweber/set-emp-cust-price>
	<strong>[lang::message::lookup "" intranet-cust-koernigweber.Filter_Records "Filter Records"]:</strong>
	<input type='radio' name='filter_records' value='current' $current_checked> [lang::message::lookup "" intranet-cust-koernigweber.Current "Current"]
	<input type='radio' name='filter_records' value='current_and_future' $current_and_future_checked> [lang::message::lookup "" intranet-cust-koernigweber.Current_Future "Current and Future"] 
	<!-- <input type='radio' name='filter_records' value='last_year'> [lang::message::lookup "" intranet-cust-koernigweber.Last_Year "Last year"] -->
	<input type='radio' name='filter_records' value='all' $all_checked> [lang::message::lookup "" intranet-cust-koernigweber.All "All"]
	<br>
	<br>
	[export_form_vars object_id return_url]
	    <table bgcolor=white cellpadding=1 cellspacing=1 border=0>
	      $header_html
	      $body_html
	      $footer_html
	    </table>
    "
    if { "user" == $object_type } {
	append html "<input type='hidden' name='new_user_id' value='$user_id' />"
    } else {
	if { $portlet_allocation_costs_p } {
		append html "<input type='hidden' name='new_user_id' value='0' />"
		append html "<input type='hidden' name='project_id' value='0' />"
	}
    }
    append html "</form>"
    return $html
}


ad_proc -public im_koernigweber_next_project_nr {
    {-customer_id 0 }
    {-nr_digits {}}
    {-date_format {}}
} {
    Returns "" if there was an error calculating the number.
    koernigweber project_nr look like: cccc-xx-xxxx with the first 4 digits being
    the customer, four digits indicating the year the project starts and a 4 digit 
    consecutive number 
} {

    set date_format "YY"
    ns_log Notice "im_koernig_weber_next_project_nr: customer_id=$customer_id, nr_digits=$nr_digits, date_format=$date_format"

    if {"none" == $date_format} { set date_format "" }

    set koernigweber_customer_code ""

    catch {
            db_1row koernigweber_cust_code "
                select  company_code,
			company_name
                from    im_companies
                where   company_id = :customer_id
            "
    } errmsg
    ns_log Notice "im_koernigweber_next_project_nr: koernigweber_customer_code=$koernigweber_customer_code"

    if { ![info exists company_code] } { set company_code "" }
    if { ![info exists company_name] } { set company_name "" }
 
    if { "" == $company_code } {
        ad_return_complaint 1 "<b>Unable to find 'Customer Code'</b>:
        <p>
        No Customer Code found for customer: <a href=/intranet/companies/view?company_id=$customer_id>$company_name</a>
        </p>
        <pre>$errmsg</pre>
        "
        ad_script_abort
    }

    # ----------------------------------------------------
    # Calculate the next project nr by finding out the last
    # one +1

    set sql "
                select  project_nr as last_project_nr
                from    im_projects
                where   
			project_nr like '$company_code%' and 
			company_id = :customer_id
		order by project_nr ASC
		limit 1
    "

    if { 0==[db_0or1row max_project_nr $sql] } {
	set last_project_nr 1
    } else {
	set last_project_nr_length [string length $last_project_nr]
	set last_project_nr [string range $last_project_nr [expr $last_project_nr_length-4] $last_project_nr_length]
	set last_project_nr [expr [forceInteger $last_project_nr] + 1]
    }

    # fill up with zeros 
    set zeros ""
    for {set i 0} {$i < [expr 4-[string length $last_project_nr]]} {incr i} {
		append zeros "0"
    }
    set last_project_nr [append zeros $last_project_nr]        

    # code + year code
    set year [db_string today "select to_char(now(), :date_format)"]

    # put everything together
    set project_number ""
    return [append project_number $company_code "_" $year "_" $last_project_nr]
}

	    


# ad_proc im_timesheet_price_component { user_id company_id return_url} {
#     Returns a formatted HTML table representing the 
#     prices for the current company
# } {
# 
#     if {![im_permission $user_id view_costs]} {
#         return ""
#     }
# 
#     set bgcolor(0) " class=roweven "
#     set bgcolor(1) " class=rowodd "
# #    set price_format "000.00"
#     set price_format "%0.2f"
# 
#     set colspan 7
#     set price_list_html "
# <form action=/intranet-timesheet2-invoices/price-lists/price-action method=POST>
# [export_form_vars company_id return_url]
# <table border=0>
# <tr><td colspan=$colspan class=rowtitle align=center>[_ intranet-timesheet2-invoices.Price_List]</td></tr>
# <tr class=rowtitle> 
# 	  <td class=rowtitle>[_ intranet-timesheet2-invoices.UoM]</td>
# 	  <td class=rowtitle>[_ intranet-timesheet2-invoices.Task_Type]</td>
# 	  <td class=rowtitle>[_ intranet-timesheet2-invoices.Material]</td>
# 	  <td class=rowtitle>[_ intranet-timesheet2-invoices.Rate]</td>
# 	  <td class=rowtitle>[im_gif del "Delete"]</td>
# </tr>"
# 
#     set price_sql "
# select
# 	p.*,
# 	c.company_path as company_short_name,
# 	im_category_from_id(uom_id) as uom,
# 	im_category_from_id(task_type_id) as task_type,
# 	im_material_nr_id(material_id) as material
# from
# 	im_timesheet_prices p,
# 	im_companies c
# where 
# 	p.company_id=:company_id
# 	and p.company_id=c.company_id
# order by
# 	currency,
# 	uom_id,
# 	task_type_id desc
# "
# 
#     set price_rows_html ""
#     set ctr 1
#     set old_currency ""
#     db_foreach prices $price_sql {
# 
# 	if {"" != $old_currency && ![string equal $old_currency $currency]} {
# 	    append price_rows_html "<tr><td colspan=$colspan>&nbsp;</td></tr>\n"
# 	}
# 
# 	append price_rows_html "
#         <tr $bgcolor([expr $ctr % 2]) nobreak>
# 	  <td>$uom</td>
# 	  <td>$task_type</td>
# 	  <td>$material</td>
#           <td>[format $price_format $price] $currency</td>
#           <td><input type=checkbox name=price_id.$price_id></td>
# 	</tr>"
# 	incr ctr
# 	set old_currency $currency
#     }
# 
#     if {$price_rows_html != ""} {
# 	append price_list_html $price_rows_html
#     } else {
# 	append price_list_html "<tr><td colspan=$colspan align=center><i>[_ intranet-timesheet2-invoices.No_prices_found]</i></td></tr>\n"
#     }
# 
#     set sample_pracelist_link "<a href=/intranet-timesheet2-invoices/price-lists/pricelist_sample.csv>[_ intranet-timesheet2-invoices.lt_sample_pricelist_CSV_]</A>"
# 
#     append price_list_html "
# <tr>
#   <td colspan=$colspan align=right>
#     <input type=submit name=add_new value=\"[_ intranet-timesheet2-invoices.Add_New]\">
#     <input type=submit name=del value=\"[_ intranet-timesheet2-invoices.Del]\">
#   </td>
# </tr>
# </table>
# </form>
# <ul>
#   <li>
#     <a href=/intranet-timesheet2-invoices/price-lists/upload-prices?[export_url_vars company_id return_url]>
#       [_ intranet-timesheet2-invoices.Upload_prices]</A>
#     [_ intranet-timesheet2-invoices.lt_for_this_company_via_]
#   <li>
#     [_ intranet-timesheet2-invoices.lt_Check_this_sample_pra]
#     [_ intranet-timesheet2-invoices.lt_It_contains_some_comm]
# </ul>\n"
#     return $price_list_html
# }

# ------------------------------------------------------
# The list of hours per project
# ------------------------------------------------------

ad_proc im_timesheet_invoicing_project_hierarchy_kw { 
    { -include_task "" }
    -select_project:required
    -start_date:required
    -end_date:required
    -invoice_hour_type:required
} {
    Returns a formatted HTML table representing the list of subprojects
    and their logged hours.
} {
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"

    set default_material_id [im_material_default_material_id]
    set default_material_name [db_string matname "select acs_object__name(:default_material_id)"]

    set task_table_rows "
    <tr> 
	<td class=rowtitle align=middle>[im_gif help "Include in Invoice"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.Task_Name "Task Name"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.All_br_Reported_br_Units "All<br>Reported<br>Units"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.Reported_br_Units_in_br_Interval "Reported<br>Units in<br>Interval"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.All_Unbilled_Units "All<br>Unbilled<br>Units"]</td>
	<td align=center class=rowtitle>[lang::message::lookup ""  intranet-timesheet2-invoices.UoM "UoM"]<br>[im_gif help "Unit of Measure"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.Status Status]</td>
    </tr>
   "

    set reported_checked ""
    set interval_checked ""
    set new_checked ""
    set unbilled_checked ""
    switch $invoice_hour_type {
	reported { set reported_checked " checked" }
	interval { set interval_checked " checked" }
	new { set new_checked " checked" }
	unbilled { set unbilled_checked " checked" }
    }


    set invoice_radio_disabled ""
    if {"" != $invoice_hour_type} {
        set invoice_radio_disabled "disabled"
    } else {
        set planned_checked " checked"
    }

    # Show a line with with the selected invoicing type
    append task_table_rows "
	<tr>
	  <td colspan=2>Please select the type of hours to use:</td>
	  <td align=center><input type=radio name=invoice_hour_type value=reported $invoice_radio_disabled $reported_checked></td>
	  <td align=center><input type=radio name=invoice_hour_type value=interval $invoice_radio_disabled $interval_checked></td>
	  <td align=center><input type=radio name=invoice_hour_type value=unbilled $invoice_radio_disabled $unbilled_checked></td>
	  <td></td>
	  <td></td>
	</tr>
    "

    set sql "
  	select
                parent.project_id as parent_id,
                parent.project_nr as parent_nr,
                parent.project_name as parent_name,
                children.project_id,
                children.project_name,
                children.project_nr,
                im_category_from_id(children.project_status_id) as project_status,
                im_category_from_id(children.cost_object_category_id) as project_type,
                tree_level(children.tree_sortkey) - tree_level(parent.tree_sortkey) as level,
                t.task_id,
                t.planned_units,
                t.billable_units,
                t.uom_id,
                m.material_name,
                m.material_billable_p,
                im_category_from_id(t.uom_id) as uom_name,
                (select sum(h.hours) from im_hours h where h.project_id = children.project_id) as all_reported_hours,
                (select sum(h.days) from im_hours h where h.project_id = children.project_id) as all_reported_days,
                (select sum(h.hours) from im_hours h where
                        h.project_id = children.project_id
                        and h.day >= to_timestamp(:start_date, 'YYYY-MM-DD')
                        and h.day < to_timestamp(:end_date, 'YYYY-MM-DD')
                ) as hours_in_interval,
                (select sum(h.days) from im_hours h where
                        h.project_id = children.project_id
                        and h.day >= to_timestamp(:start_date, 'YYYY-MM-DD')
                        and h.day < to_timestamp(:end_date, 'YYYY-MM-DD')
                ) as days_in_interval,
                (select sum(h.hours) from im_hours h where
                        h.project_id = children.project_id
                        and h.invoice_id is null
                ) as unbilled_hours,
                (select sum(h.days) from im_hours h where
                        h.project_id = children.project_id
                        and h.invoice_id is null
                ) as unbilled_days
	from
		im_projects parent,
		im_projects children
		LEFT OUTER JOIN im_timesheet_tasks t ON (children.project_id = t.task_id)
		LEFT OUTER JOIN im_materials m ON (t.material_id = m.material_id)
	where
		children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
		and parent.project_id in ([join $select_project ","])
	order by 
		parent.project_name, 
		children.tree_sortkey
    "

    set ctr 0
    set colspan 11
    set old_parent_id 0
    db_foreach select_tasks $sql {
	
	set material_name $default_material_name 
	
	# insert intermediate headers for every project
	if {$old_parent_id != $parent_id} {
	    append task_table_rows "
		<tr><td colspan=$colspan>&nbsp;</td></tr>
		<tr>
		  <td class=rowtitle colspan=$colspan>
		    $parent_nr: $parent_name
		  </td>
		</tr>\n"
	    set old_parent_id $parent_id
	}
	
	set indent ""
	for {set i 0} {$i < $level} {incr i} { 
	    append indent "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" 
	}
	
	set task_checked ""
	set task_disabled ""	
	if {0 == [llength $include_task]} {   
	    # Called from the Wizard Page - Enabled tasks
	    # according to the task's material.
	    if {"f" != $material_billable_p} {
	        set task_checked "checked"
	    }
		
	} else {
	    # View from the Invoice page
	    # disable the checkbox (because it is not editable anymore).
	    if {[lsearch $include_task $project_id] > -1} {
		set task_checked "checked"
	    }
	    set task_disabled "disabled"
	}

	if { "321" == $uom_id } {
		set all_reported_units $all_reported_days
		set units_in_interval $days_in_interval
		set unbilled_units $unbilled_days
	} elseif { "320" == $uom_id } {
		set all_reported_units $all_reported_hours
		set units_in_interval $hours_in_interval
		set unbilled_units $unbilled_hours
	} elseif { "" == $uom_id } {
                # We assume hours logged directly on a project instead of a task
                set all_reported_units $all_reported_hours
                set units_in_interval $hours_in_interval
                set unbilled_units $unbilled_hours
		if { "" != $units_in_interval || "" != $all_reported_hours || "" != $unbilled_hours } {
			set uom_name "<span style='color: red'>" 
			append uom_name [lang::message::lookup "" intranet-core.Hour "Hour"]
                	append uom_name "</span>&nbsp;<img src='/intranet/images/help.gif' title='No UOM provided so we assume HOURS, please verify' 
			         alt='No UOM provided so we assume HOURS, please verify' border='0' height='16' width='16'>
			"
		}
        } else  {
		set all_reported_units "-"
		set units_in_interval "-"
		set unbilled_units "-"
	}

	append task_table_rows "
	<tr $bgcolor([expr $ctr % 2])> 
	  <td align=middle><input type=checkbox name=include_task value=$project_id $task_disabled $task_checked></td>
	  <td align=left><nobr>$indent <A href=/intranet/projects/view?project_id=$project_id>$project_name</a></nobr></td>
	  <td align=right>$all_reported_units</td>
	  <td align=right>$units_in_interval</td>
	  <td align=right>$unbilled_units</td>
	  <td align=left>$uom_name</td>
	  <td>$project_status</td>
	</tr>
	"
	incr ctr
    }

    if {[string equal "" $task_table_rows]} {
	set task_table_rows "<tr><td colspan=$colspan align=center>[lang::message::lookup "" intranet-timesheet2-invoices.No_tasks_found "No tasks found"]</td></tr>"
    }

    return $task_table_rows
}

proc filter_conncontext { conn arg why } {

    set filter_active_p [parameter::get -package_id [apm_package_id_from_key intranet-cust-koernigweber] -parameter "HTTPSFilter" -default 1]
    if { !$filter_active_p } { return filter_ok }
    
    set headers_string ""
    for { set i 0 } { $i < [ns_set size [ns_conn headers]] } { incr i } {
	append headers_string "[ns_set key [ns_conn headers] $i]: [ns_set value [ns_conn headers] $i]"
    }

    set white_listed_base_urls "
        /intranet/js
        /intranet/images
        /intranet/style
        /resources/acs-subsite
        /resources/diagram
        /resources/acs-templating
        /calendar/resources
        /resources/acs-developer-support
        /images
    "
    set white_listed_urls "
        /intranet-timesheet2/hours/index
        /intranet-timesheet2/hours/new
        /intranet-timesheet2/hours/new-2
        /http-block.html
        /register/logout
        /register/recover-password
        /images/logo.kw.gif
        /lock.jpg
    "
    # Is this a HTTP request?
    set http_p [ns_set iget [ns_conn headers] "HTTP"]
    if { [string equal "1" $http_p] } {
        regexp {(/.*)?(/.*)} [ns_conn url] match link
        if { [string first [string tolower [ns_conn url]] $white_listed_urls] != -1 || [string first $link $white_listed_base_urls] != -1 } {
            return filter_ok
        } else {
	    if { "/intranet/"== [ns_conn url]} {
                 ad_returnredirect "/intranet-timesheet2/hours/index"
	    } else {
                    ad_returnredirect "/http-block.html"
	    }
        }
    }
    return filter_ok
}

ad_proc im_project_type_table {
    {-translate_p 1}
    {-package_key "intranet-cust-koernigweber" }
    {-locale "" }
    company_id 
} {
    Returns a formatted HTML table with enabled "Project Types" and a select box  
    Based on "im_category_select_helper"
} {

    set category_type "Intranet Cost Object"

    # Read the categories into the a hash cache
    # Initialize parent and level to "0"
    set sql "
        select
                category_id,
                category,
                category_description,
                parent_only_p,
                enabled_p
        from
                im_categories
        where
                category_type = :category_type
		and (enabled_p = 't' OR enabled_p is NULL)
        order by lower(category)
    "
    db_foreach category_select $sql {
        set cat($category_id) [list $category_id $category $category_description $parent_only_p $enabled_p]
        set level($category_id) 0
    }

    # Get the hierarchy into a hash cache
    set sql "
        select
                h.parent_id,
                h.child_id
        from
                im_categories c,
                im_category_hierarchy h
        where
                c.category_id = h.parent_id
                and c.category_type = :category_type
        order by lower(category)
    "

    # setup maps child->parent and parent->child for
    # performance reasons
    set children [list]
    db_foreach hierarchy_select $sql {
	if {![info exists cat($parent_id)]} { continue}
	if {![info exists cat($child_id)]} { continue}
        lappend children [list $parent_id $child_id]
    }

    set count 0
    set modified 1
    while {$modified} {
        set modified 0
        foreach rel $children {
            set p [lindex $rel 0]
            set c [lindex $rel 1]
            set parent_level $level($p)
            set child_level $level($c)
            if {[expr $parent_level+1] > $child_level} {
                set level($c) [expr $parent_level+1]
                set direct_parent($c) $p
                set modified 1
            }
        }
        incr count
        if {$count > 1000} {
            ad_return_complaint 1 "Infinite loop in 'im_category_select'<br>
            The category type '$category_type' is badly configured and contains
            and infinite loop. Please notify your system administrator."
            return "Infinite Loop Error"
        }
    }

    set base_level 0
    set html "<table>"

    # Sort the category list's top level. We currently sort by category_id,
    # but we could do alphabetically or by sort_order later...
    set category_list [array names cat]
    set category_list_sorted [lsort $category_list]

    # Now recursively descend and draw the tree, starting
    # with the top level
    foreach p $category_list_sorted {
        set p [lindex $cat($p) 0]
        set enabled_p [lindex $cat($p) 4]
	if {"f" == $enabled_p} { continue }
        set p_level $level($p)
        if {0 == $p_level} {
            append html [im_category_select_branch_kw -translate_p $translate_p -package_key $package_key -locale $locale $p "" $base_level [array get cat] [array get direct_parent] $company_id]
        }
    }

    return "$html</table>"

}

ad_proc im_category_select_branch_kw {
    {-translate_p 0}
    {-package_key "intranet-core" }
    {-locale "" }
    parent
    default
    level
    cat_array
    direct_parent_array
    company_id
} {
    Returns a list of html "options" displaying an options hierarchy.
} {

    if {$level > 10} { return "" }

    array set cat $cat_array
    array set direct_parent $direct_parent_array

    set category [lindex $cat($parent) 1]
    if {$translate_p} {
        set category_key "$package_key.[lang::util::suggest_key $category]"
        set category [lang::message::lookup $locale $category_key $category]
    }

    set parent_only_p [lindex $cat($parent) 3]

    set spaces ""
    for {set i 0} { $i < $level} { incr i} {
        append spaces "&nbsp; &nbsp; &nbsp; &nbsp; "
    }

    set selected ""
    if {$parent == $default} { set selected "selected" }
    set html ""
    if {"f" == $parent_only_p} {
	set checked [db_string get_data "select count(*) from im_customer_project_type where company_id = $company_id and project_type_id = $parent" -default 0]
	if { "0" == $checked } {
	    set checked_tag ""
	} else {
	    set checked_tag "checked"
	}
        set html "<tr><td>$spaces $category</td><td><input type='checkbox' $checked_tag name='project_type_id' value='$parent'/></td></tr>\n"
        incr level
    }

    # Sort by category_id, but we could do alphabetically or by sort_order later...
    set category_list [array names cat]
    set category_list_sorted [lsort $category_list]

    foreach cat_id $category_list_sorted {
        if {[info exists direct_parent($cat_id)] && $parent == $direct_parent($cat_id)} {
            append html [im_category_select_branch_kw -translate_p $translate_p -package_key $package_key -locale $locale $cat_id $default $level $cat_array $direct_parent_array $company_id]
        }
    }

    return $html
}


# Helper routine for import
ad_proc get_person_id_from_org_id {
        org_id
} {
    Returns the sales price that has defined for a particular user
    on an arbitrary project level above
} {
    return [db_string get_data "select person_id from persons where organizational_id_number = :org_id" -default 0]
}

ad_proc -public -callback im_project_new_redirect -impl intranet-cust-koernigweber  {
    { 
	{ -object_id ""} 
	{ -status_id ""} 
	{ -type_id ""}
        { -project_id ""}
	{ -parent_id ""}
	{ -company_id ""}
	{ -project_type_id ""} 
	{ -project_name ""}
	{ -project_nr ""}
	{ -workflow_key ""}
	{ -return_url ""}
    }
} {
    - Check if choosen "Cost Object" is selectable
    # -Check if user who tried to create a project has a sales price assigned
} {
    template::head::add_javascript -src "/intranet-cust-koernigweber/js/get_cost_object.js" -order "999"     
#     set log ""
#     foreach uid $user_id {
#       set price [find_sales_price $uid $object_id "" ""]
#       if { "" == $price } {
#           set name [im_name_from_user_id $uid]
#           append log [lang::message::lookup "" intranet-cust-koernigweber.No_Price_Found "User $name can't be assigned to this project: No price record found.<br>"]
#       }
#     }
#     if { "" != $log } {
#       set log "<strong> [lang::message::lookup "" intranet-cust-koernigweber.Operation_Canceled "Operation canceled"]</strong> <br> $log"
#       ad_return_complaint 1 $log
#       break
#     }
}


ad_proc check_logging_project_status {
        project_id
} {
    Checks if one of the parent projects has a project status that prohibits
    TS logging due to parameter 'AllowLoggingForProjectStatusIDs'
} {

	# Check if status of object itself forbidds logging 
	set project_status_id [db_string get_data "select project_status_id from im_projects where project_id = :project_id" -default 0]	

	if { [string first $project_status_id [string tolower [parameter::get -package_id [apm_package_id_from_key intranet-timesheet2] -parameter "AllowLoggingForProjectStatusIDs" -default ""]]] == -1 } {
		return 0 
	}

	# Check for parent element(s)
	set sql "
		select 
			project_status_id, 
			project_id as parent_project_id 
		from 
			im_projects 
		where 
			project_id in (
				select parent_id from im_projects where project_id = :project_id 
			)
	"
	set project_status_id [db_string get_data $sql -default 0]

	if { "" == $project_status_id || "0" == $project_status_id } {
		return 1
	} else {
		if { [string first $project_status_id [string tolower [parameter::get -package_id [apm_package_id_from_key intranet-timesheet2] -parameter "AllowLoggingForProjectStatusIDs" -default ""]]] == -1 } {
			return 0 
		} else {
		    if { ![info exists parent_project_id] || $parent_project_id == "" } {
			return 1 
		    } else {
			return check_logging_project_status($parent_project_id)
		    }
		}
	}
}

ad_proc forceInteger { x } {
    set count [scan $x %d%s n rest]
    if { $count <= 0 || ( $count == 2 && ![string is space $rest] ) } {
        return -code error "not an integer: \"$x\""
    }
    return $n
}


ad_proc im_absence_new_page_wf_perm_edit_button_kw {
    -absence_id:required
} {
    Should we show the "Edit" button in the AbsenceNewPage?
    The button is visible only for the Owner of the absence
    and the Admin, but nobody else during the course of the WF.
    Also, the Absence should not be changed anymore once it has
    started.
} {
    set perm_table [im_absence_new_page_wf_perm_table_kw]
    set perm_set [im_workflow_object_permissions \
                    -object_id $absence_id \
                    -perm_table $perm_table
		  ]

    ns_log Notice "im_absence_new_page_wf_perm_edit_button absence_id=$absence_id => $perm_set"
    return [expr [lsearch $perm_set "w"] > -1]
}

ad_proc im_absence_new_page_wf_perm_delete_button_kw {
    -absence_id:required
} {
    Should we show the "Delete" button in the AbsenceNewPage?
    The button is visible only for the Owner of the absence,
    but nobody else in the WF.
} {
    set perm_table [im_absence_new_page_wf_perm_table_kw]
    set perm_set [im_workflow_object_permissions \
                    -object_id $absence_id \
                    -perm_table $perm_table
		  ]

    ns_log Notice "im_absence_new_page_wf_perm_delete_button absence_id=$absence_id => $perm_set"
    return [expr [lsearch $perm_set "d"] > -1]
}


ad_proc im_absence_new_page_wf_perm_table_kw { } {
    Returns a hash array representing (role x status) -> (v r d w a),
    controlling the read and write permissions on absences,
    depending on the users's role and the WF status.
} {
    set req [im_absence_status_requested]
    set rej [im_absence_status_rejected]
    set act [im_absence_status_active]
    set del [im_absence_status_deleted]
    set acc 10000128

    set perm_hash(owner-$rej) {v r}
    set perm_hash(owner-$req) {v r}
    set perm_hash(owner-$act) {v r}
    set perm_hash(owner-$del) {v r}
    set perm_hash(owner-$acc) {v r}
 

    set perm_hash(assignee-$rej) {v r}
    set perm_hash(assignee-$req) {v r}
    set perm_hash(assignee-$act) {v r}
    set perm_hash(assignee-$del) {v r}
    set perm_hash(assignee-$acc) {v r}


    set perm_hash(hr-$rej) {v r d w a}
    set perm_hash(hr-$req) {v r d w a}
    set perm_hash(hr-$act) {v r d w a}
    set perm_hash(hr-$del) {v r d w a}
    set perm_hash(hr-$acc) {v r d}


    return [array get perm_hash]
}

ad_proc -public -callback im_before_member_add -impl intranet-cust-koernigweber  {
    { -user_id:required }
    { -object_id:required }
} {
    Check if user has sales price VK assigned 
} {

    # Check only for project membership 
    if { "im_project" == [acs_object_type $object_id] } {
    	if { [info exists user_id] } {
		set log ""
		foreach uid $user_id {
		    set price [find_sales_price $uid $object_id "" "" ""]
	   	    if { "" == $price } {
			set name [im_name_from_user_id $uid]
			append log [lang::message::lookup "" intranet-cust-koernigweber.No_Price_Found "User $name can't be assigned to this project: No price record found.<br>"]
	    	    }	       
		}
		if { "" != $log } {
		    set log "<strong> [lang::message::lookup "" intranet-cust-koernigweber.Operation_Canceled "Operation canceled"]</strong> <br> $log"
		    ad_return_complaint 1 $log
		    break
		}
    	}
   }
}
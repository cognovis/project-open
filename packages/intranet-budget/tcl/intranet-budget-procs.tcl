# /packages/intranet-budget/tcl/intranet-budget-procs.tcl
#

ad_library {
    
    Bring together all "components" (=HTML + SQL code)
    related to Budgets

    @author iuri sampaio (iuri.sampaio@gmail.com)

}



ad_proc -public im_cost_type_estimation {} { return 3750 }

###
# Budget Component
###

ad_proc im_budget_component {
    -return_url
    -user_id
} {
    budget component to display budget summary
} {
    
    #-------------------------------------------------------
    # Budget Component
    #-------------------------------------------------------

    #TODO  It is missing to create the recursive code to add subitem of the menu
    ns_log Notice "Running API im_budget_component"

    set parent_menu_sql "select menu_id from im_menus where label= 'budget_summary'"
    set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default ""]]
    
    set menu_select_sql "
	select  m.*
	from    im_menus m
	where   parent_menu_id = :parent_menu_id
	and enabled_p = 't'
	and im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
        order by sort_order
    "
    # Start formatting the menu bar                                                                                                                          
    set provider_menu "<ul>"
    set ctr 0
    db_foreach menu_select $menu_select_sql {
        ns_log Notice "im_sub_navbar: menu_name='$name'"
        regsub -all " " $name "_" name_key
        append provider_menu "<li><a href=\"$url\">[_ intranet-invoices.$name_key]</a></li>\n"
        incr ctr
    }
    append provider_menu "</ul>"


#    set params [list  [list base_url "/intranet-cost/"] [list return_url $return_url]]
    
 #   set result [ad_parse_template -params $params "/packages/intranet-fs/lib/intranet-fs"]
    return $provider_menu    
}





# ---------------------------------------------------------------------
# Budget Summary Component 
# ---------------------------------------------------------------------
ad_proc -public im_budget_summary_component { 
    -project_id
    -user_id
    -return_url
} { 
} {
    
    set params [list  [list base_url "/intranet-budget/"]  [list user_id $user_id] [list project_id $project_id] [list return_url [im_biz_object_url $project_id]]]
    
    set result [ad_parse_template -params $params "/packages/intranet-budget/lib/budget-summary"]
    return [string trim $result]
    
}
    
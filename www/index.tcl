# /packages/intranet-invoices/www/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Offers a menu to create new Invoices, Quotes, POs
    and Bills

    @author frank.bergmann@project-open.com
} {
    { project_id 0 }
    { company_id 0 }
}
set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-cost.Finance_Home]"
set context_bar [im_context_bar $page_title]

if {![im_permission $user_id view_costs]} {
    ad_return_complaint 1 "<li>You have insufficiente privileges to view this page"
    return
}

if {"" == $project_id} { set project_id 0}
if {"" == $company_id} { set company_id 0}

# select the "Finance" Menu
set parent_menu_sql "select menu_id from im_menus where label='finance'"
set parent_menu_id [db_string parent_admin_menu $parent_menu_sql -default 0]

set menu_select_sql "
        select  m.*
        from    im_menus m
        where   parent_menu_id = :parent_menu_id
                and im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
        order by sort_order"

# Start formatting the menu bar
set new_list_html ""
set ctr 0

db_foreach menu_select $menu_select_sql {

    ns_log Notice "im_sub_navbar: menu_name='$name'"
    if {$company_id} { append url "&company_id=$company_id" }
    if {$project_id} { append url "&project_id=$project_id" }
    regsub -all " " $name "_" name_key
    append new_list_html "<li><a href=\"$url\">[_ intranet-cost.$name_key]</a></li>\n"
}


# ---------------------------------------------------------------
# Format the admin menu
# ---------------------------------------------------------------


    set parent_menu_sql "select menu_id from im_menus where label= 'invoices_providers'"
    set parent_menu_id [db_string parent_admin_menu $parent_menu_sql -default ""]

    set menu_select_sql "
        select  m.*
        from    im_menus m
        where   parent_menu_id = :parent_menu_id
                and im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
        order by sort_order"

    # Start formatting the menu bar
    set provider_menu ""
    set ctr 0
    db_foreach menu_select $menu_select_sql {
	
	ns_log Notice "im_sub_navbar: menu_name='$name'"
	regsub -all " " $name "_" name_key
	append provider_menu "<li><a href=\"$url\">[_ intranet-invoices.$name_key]</a></li>\n"
    }



    set parent_menu_sql "select menu_id from im_menus where label= 'invoices_customers'"
    set parent_menu_id [db_string parent_admin_menu $parent_menu_sql -default ""]

    set menu_select_sql "
        select  m.*
        from    im_menus m
        where   parent_menu_id = :parent_menu_id
                and im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
        order by sort_order"

    # Start formatting the menu bar
    set customers_menu ""
    set ctr 0
    db_foreach menu_select $menu_select_sql {
	
	ns_log Notice "im_sub_navbar: menu_name='$name'"
	regsub -all " " $name "_" name_key
	append customers_menu "<li><a href=\"$url\">[_ intranet-invoices.$name_key]</a></li>\n"
    }



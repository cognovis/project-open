# /packages/intranet-invoices/www/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Offers a menu to create new Invoices, Quotes, POs
    and Bills

    @author frank.bergmann@project-open.com
} {
    { project_id ""}
    {-plugin_id:integer 0}
    {-return_url ""}
    {-user_id ""}
}
set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-budget.Budget_Home]"
set context_bar [im_context_bar $page_title]

## ++ added page parameter return_url and line bellow by iuri 2010-08-27
set return_url [ad_conn url]

if {![im_permission $user_id view_costs]} {
    ad_return_complaint 1 "<li>You have insufficiente privileges to view this page"
    return
}

if {"" == $project_id} { set project_id 0}



# ---------------------------------------------------------------
# Format the admin menu
# ---------------------------------------------------------------


    set parent_menu_sql "select menu_id from im_menus where label= 'budget'"
    set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default ""]]

    set menu_select_sql "
        select  m.*
        from    im_menus m
        where   parent_menu_id = :parent_menu_id
		and enabled_p = 't'
                and im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
        order by sort_order"

    # Start formatting the menu bar
    set budget_menu "<ul>"
    set ctr 0
    db_foreach menu_select $menu_select_sql {
	ns_log Notice "im_sub_navbar: menu_name='$name'"
	regsub -all " " $name "_" name_key
	append budget_menu "<li><a href=\"${url}&project_id=$project_id&return_url=$return_url\">[_ intranet-budget.$name_key]</a></li>\n"
	incr ctr
    }
    append budget_menu "</ul>"
    set budget_ctr $ctr

# -----------------------------------------------------------------
# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id

set parent_menu_id [util_memoize [list db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]]

set menu_label "budget_summary"

set sub_navbar [im_sub_navbar \
		    -components \
		    -base_url "/intranet/projects/view?project_id=4project_id" \
		    $parent_menu_id \
		    $bind_vars "" "pagedescriptionbar" $menu_label]





# /packages/intranet-nagios/www/index.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Main page for Nagios integration
    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet-nagios/" }
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-nagios.Nagios]"
set context_bar [im_context_bar $page_title]

# ToDo: Permissions
#if {![im_permission $user_id view_costs]} {
#    ad_return_complaint 1 "<li>You have insufficiente privileges to view this page"
#    return
#}

set nagios_package_id [db_string nagios_package_id "
	select	min(package_id)
	from	apm_packages
	where	package_key = 'intranet-nagios'
"]


# select the Nagios Menu
set parent_menu_sql "select menu_id from im_menus where label='nagios'"
set parent_menu_id [db_string parent_admin_menu $parent_menu_sql -default 0]

set menu_select_sql "
        select  m.*
        from    im_menus m
        where   parent_menu_id = :parent_menu_id
		and enabled_p = 't'
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
    append new_list_html "<li><a href=\"$url\">[_ $package_name.$name_key]</a></li>\n"
}



set sub_navbar [im_costs_navbar "none" "/intranet/invoices/index" "" "" [list] "costs_home"] 





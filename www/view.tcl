# /packages/intranet-reporting/www/view.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# frank.bergmann@project-open.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Show the results of a single "dynamic" report or indicator
    @author frank.bergmann@project-open.com
} {
    report_id:integer,optional
    {return_url "/intranet-reporting/index"}
}


# ---------------------------------------------------------------
# Defaults & Security

set current_user_id [ad_maybe_redirect_for_registration]
set menu_id [db_string menu "select report_menu_id from im_reports where report_id = :report_id" -default 0]
set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.menu_id = :menu_id
" -default 'f']
if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

# ---------------------------------------------------------------
# Get Report Info

db_1row report_info "
	select	r.*,
		im_category_from_id(report_type_id) as report_type
	from	im_reports r
	where	report_id = :report_id
"

set page_title "$report_type: $report_name"
set context [im_context_bar $page_title]


set page_body [im_ad_hoc_query -format html $report_sql]


#set page_body "$bind_rows<p><hr>[join $result "<br>"]<p><hr>err:$err_msg<p><hr><pre>$report_sql</pre>"




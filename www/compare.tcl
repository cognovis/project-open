# /packages/intranet-reporting/www/compare.tcl
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
    Start benchmarking local numbers vs. global numbers
    @author frank.bergmann@project-open.com
} {
    {return_url "/intranet-reporting-indicators/index"}
}

# ---------------------------------------------------------------
# Defaults & Security

set current_user_id [ad_maybe_redirect_for_registration]
if {![im_permissions $current_user_id "add_finance"]} { 
    ad_return_complaint 1 "Insufficient Permissions"
    ad_script_abort
}

set page_title [lang::message::lookup "" intranet-reporting-indicators.Compare_Your_Company "Compare Your Company"]
set context [im_context_bar $page_title]


set sector [parameter::get_from_package_key -package_key "intranet-reporting-indicators" -parameter "CompanySector" -default ""]
set location [parameter::get_from_package_key -package_key "intranet-reporting-indicators" -parameter "CompanyLocation" -default ""]
set employees [parameter::get_from_package_key -package_key "intranet-reporting-indicators" -parameter "CompanyEmployees" -default ""]

if {"" == $sector || "" == $location} {
    ad_return_complaint 1 "
	<b>Sector or Location not set yet</b>:<br>
	Please go to your 
    "
}

if {"" == $employees} {
    set employees [db_string emps "
	select	count(*) 
	from	users_active u, group_distinct_member_map gm
	where	u.user_id = gm.member_id and 
		gm.group_id = (select group_id from groups where group_name = 'Employees')
    "
}

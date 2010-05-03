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
    @param format One of {html|csv|xml}

    @author frank.bergmann@project-open.com
} {
    report_id:integer,optional
    report_code:optional
    {format "html" }
    {return_url "/intranet-reporting/index"}
    { user_id:integer 0}
    { auto_login "" }
}


# ---------------------------------------------------------------
# Defaults & Security

# Accept a report_code as an alternative to the report_id parameter.
# This allows us to access this page via a REST interface more easily,
# because the object_id of a report may vary across systems.
if {[info exists report_code]} { 
    set id [db_string code_id "select report_id from im_reports where report_code = :report_code" -default ""]
    if {"" != $id} { set report_id $id }
}



# --------------------------------------------------------
# Check for HTTP "basic" authorization
# Example: Authorization=Basic cHJvam9wOi5mcmFiZXI=
#
set header_vars [ns_conn headers]
set basic_auth [ns_set get $header_vars "Authorization"]
set basic_auth_userpass ""
set basic_auth_username ""
set basic_auth_password ""
if {[regexp {^([a-zA-Z_]+)\ (.*)$} $basic_auth match method userpass_base64]} {
    set basic_auth_userpass [base64::decode $userpass_base64]
    regexp {^([^\:]+)\:(.*)$} $basic_auth_userpass match basic_auth_username basic_auth_password
}
set basic_auth_user_id [db_string userid "select user_id from users where lower(username) = lower(:basic_auth_username)" -default ""]
if {"" == $basic_auth_user_id} {
    set basic_auth_user_id [db_string userid "select party_id from parties where lower(email) = lower(:basic_auth_username)" -default ""]
}
set basic_auth_password_ok_p undefined
if {"" != $basic_auth_user_id} {
    set basic_auth_password_ok_p [ad_check_password $basic_auth_user_id $basic_auth_password]
    if {!$basic_auth_password_ok_p} { set basic_auth_user_id "" }
}

ns_log Notice "intranet-reporting/view: basic_auth_user_id=$basic_auth_user_id"


# Allows for auto_login authentication
if {$user_id != 0} {

    # Auth-Token based authentication
    set current_user_id $user_id
    set valid_login [im_valid_auto_login_p -user_id $user_id -auto_login $auto_login]
    if {!$valid_login} {
        ad_return_complaint 1 "<b>Wrong Security Token</b>:<br>
        Your security token is not valid. Please contact the system owner.<br>"
	ad_script_abort
    }

} elseif {"" != $basic_auth_user_id} {
    
    set current_user_id $basic_auth_user_id

} else {

    # OpenACS based authentication
    set current_user_id [ad_maybe_redirect_for_registration]

}

# ---------------------------------------------------------------
# Check security 
set menu_id [db_string menu "select report_menu_id from im_reports where report_id = :report_id" -default 0]
set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.menu_id = :menu_id
" -default 'f']
if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    ad_script_abort
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
set page_title $report_name
set context [im_context_bar $page_title]


set page_body [im_ad_hoc_query \
	-package_key "intranet-reporting" \
	-report_name $report_name \
	-format $format \
	$report_sql \
]

switch $format {
    "csv" {
	# Return file with ouput header set
	set report_key [string tolower $report_name]
	regsub -all {[^a-zA-z0-9_]} $report_key "_" report_key
	regsub -all {_+} $report_key "_" report_key
	set outputheaders [ns_conn outputheaders]
	ns_set cput $outputheaders "Content-Disposition" "attachment; filename=${report_key}.csv"
	doc_return 200 "application/csv" $page_body
	ad_script_abort
    }
    "xml" {
	# Return plain file
	doc_return 200 "application/xml" $page_body
	ad_script_abort
    }
    "plain" {
	ad_return_complaint 1 "Not Defined Yet"
    }
    default {
	# just continue with the page to format output using template
    }
}


# ---------------------------------------------------------------
# Format the Filter
# ---------------------------------------------------------------

set filter_html "
	<form method=get name=filter action='/intranet-reporting/view'>
	[export_form_vars report_id]
	<table border=0 cellpadding=0 cellspacing=1>
	<tr>
	    <td class=form-label>[lang::message::lookup "" intranet-reporting.Format "Format"]</td>
	    <td class=form-widget>[im_report_output_format_select format "" $format]</td>
	</tr>
<!-- im_ad_hoc_query doesn't understand number format...
	<tr>
	    <td class=form-label>[lang::message::lookup "" intranet-reporting.Number_Format "Number Format"]</td>
	    <td class=form-widget>[im_report_number_locale_select number_format]</td>
	</tr>
-->
	<tr>
	    <td class=form-label></td>
	    <td class=form-widget>
		  <input type=submit value='[lang::message::lookup "" intranet-core.Action_Go "Go"]' name=submit>
	    </td>
	</tr>
	</table>
	</form>
"

# Left Navbar is the filter/select part of the left bar
set left_navbar_html "
	<div class='filter-block'>
        	<div class='filter-title'>
	           [lang::message::lookup "" intranet-reporting.Report_Options "Report Options"]
        	</div>
            	$filter_html
      	</div>
      <hr/>
"

append left_navbar_html "
      	<div class='filter-block'>
        <div class='filter-title'>
            [lang::message::lookup "" intranet-reporting.Description "Description"]
        </div>
	    [ns_quotehtml $report_description]
      	</div>
"

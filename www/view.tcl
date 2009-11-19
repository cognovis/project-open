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
    {output_format "html" }
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
set page_title $report_name
set context [im_context_bar $page_title]


set page_body [im_ad_hoc_query \
	-package_key "intranet-reporting" \
	-report_name $report_name \
	-format $output_format \
	$report_sql \
]

if {"csv" == $output_format} {
    set report_key [string tolower $report_name]
    regsub -all {[^a-zA-z0-9_]} $report_key "_" report_key
    regsub -all {_+} $report_key "_" report_key
    set outputheaders [ns_conn outputheaders]
    ns_set cput $outputheaders "Content-Disposition" "attachment; filename=${report_key}.csv"
    doc_return 200 "application/csv" $page_body
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
	    <td class=form-widget>[im_report_output_format_select output_format "" $output_format]</td>
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

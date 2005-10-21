# /packages/intranet-reporting/www/admin/reports/new.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Create a new report or edit an existing one.

    @param form_mode edit or display

    @author juanjoruizx@yahoo.es
} {
    report_id:integer,optional
    {return_url "/intranet/"}
    edit_p:optional
    message:optional
    { form_mode "display" }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set user_ip [ad_conn peeraddr]
set action_url ""
set focus "report.report_name"
set page_title "[_ intranet-reporting.New_report]"
set context $page_title

if {![info exists report_id]} { set form_mode "edit" }


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set view_options [db_list_of_lists get_views {
	select view_name, view_id
	from IM_VIEWS
	order by view_name 
}]
set view_options [linsert $view_options 0 {" " ""}]

ad_form \
    -name report \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {user_id return_url} \
    -form {
		report_id:key
		{report_name:text(text) {label #intranet-reporting.Report_Name#} }
		{view_id:integer(select) {label #intranet-reporting.View#} {options $view_options}}
		{report_type_id:text(im_category_tree),optional {label #intranet-reporting.Report_Type#} {custom {category_type "Intranet Report Type"}} {value ""} }
		{report_status_id:text(im_category_tree),optional {label #intranet-reporting.Report_Status#} {custom {category_type "Intranet Report Status"}} {value ""} }
		{description:text(textarea),optional {label #intranet-reporting.Description#} {html {cols 50 rows 5}}}
    }


ad_form -extend -name report -on_request {
    # Populate elements from local variables
    

} -select_query {

	select	r.report_id,
			r.report_name,
			r.report_type_id,
			r.report_status_id,
			r.view_id,
			r.description
	from	im_reports r
	where	r.report_id = :report_id

} -validate {

        {report_name
            {![db_string unique_name_check "select count(*) from im_reports 
                                            where report_name = :report_name and report_id != :report_id"]}
            "Duplicate Report Name. Please use a new name."
        }

} -new_data {

    db_exec_plsql report_insert { }

} -edit_data {

    db_dml report_update "
	update im_reports set
	        report_name    = :report_name,
	        view_id  = :view_id,
	        report_status_id  = :report_status_id,
	        report_type_id    = :report_type_id,
	        description  = :description
	where
		report_id = :report_id
"
} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}


# ------------------------------------------------------
# List creation
# ------------------------------------------------------

if { [exists_and_not_null report_id] } {
	set action_list [list "[_ intranet-reporting.Add_new_Variable]" "[export_vars -base "new-variable" {report_id return_url}]" "[_ intranet-reporting.Add_new_Variable]"]

	set elements_list {
	  variable_id {
		label "[_ intranet-reporting.Variable_Id]"
	  }
	  variable_name {
		label "[_ intranet-reporting.Variable_Name]"
		display_template {
			<a href="@variables.variable_url@">@variables.variable_name@</a>
		}
	  }
	  pretty_name {
		label "[_ intranet-reporting.Pretty_Name]"
	  }
	  widget_name {
		label "[_ intranet-reporting.Widget_Name]"
	  }
	}

	list::create \
			-name variable_list \
			-multirow variables \
			-key variable_id \
			-actions $action_list \
			-elements $elements_list \
			-filters {
				return_url
			}

	db_multirow -extend {variable_url} variables get_variables { 
		select rv.variable_id,
			rv.variable_name,
			rv.pretty_name,
			rv.widget_name
		from im_report_variables rv
		where rv.report_id = :report_id
		order by rv.variable_name
	} {
		set variable_url [export_vars -base "new-variable" {report_id variable_id return_url}]
	}
}
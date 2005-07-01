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
    return_url
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

set action_url ""
set focus "report.report_name"
set page_title "[_ intranet-reporting.New_report]"
set context $page_title

if {![info exists report_id]} { set form_mode "edit" }


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------


ad_form \
    -name report \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {user_id return_url} \
    -form {
		report_id:key(im_reports_seq)
		{report_name:text(text) {label #intranet-reporting.Report_Name#} }
		{report_type_id:text(im_category_tree),optional {label #intranet-reporting.Report_Type#} {custom {category_type "Intranet DynReport Type"}} {value ""} }
		{report_status_id:text(im_category_tree),optional {label #intranet-reporting.Report_Status#} {custom {category_type "Intranet DynReport Status"}} {value ""} }
		{sort_order:integer(text),optional {label #intranet-reporting.Sort_Order#} {html {size 10 maxlength 15}}}
		{report_sql:text(textarea),optional {label #intranet-reporting.Report_sql#} {html {cols 50 rows 5}}}
    }


ad_form -extend -name report -on_request {
    # Populate elements from local variables
    

} -select_query {

	select	v.report_id,
			v.report_name,
			v.report_type_id,
			v.report_status_id,
			v.sort_order,
			v.report_sql
	from	im_reports v
	where	v.report_id = :report_id

} -validate {

        {report_name
            {![db_string unique_name_check "select count(*) from im_reports 
                                            where report_name = :report_name and report_id != :report_id"]}
            "Duplicate Report Name. Please use a new name."
        }

} -new_data {

    db_dml report_insert "
    insert into IM_VIEWS
    (report_id, report_name, report_status_id, report_type_id, sort_order, report_sql)
    values
    (:report_id, :report_name, :report_status_id, :report_type_id, :sort_order, :report_sql)
    "

} -edit_data {

    db_dml report_update "
	update im_reports set
	        report_name    = :report_name,
	        report_status_id  = :report_status_id,
	        report_type_id    = :report_type_id,
	        sort_order      = :sort_order,
	        report_sql  = :report_sql
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
	set action_list [list "[_ intranet-reporting.Add_new_Column]" "[export_vars -base "new-column" {report_id return_url}]" "[_ intranet-reporting.Add_new_Column]"]

	set elements_list {
	  column_id {
		label "[_ intranet-reporting.Column_Id]"
	  }
	  column_name {
		label "[_ intranet-reporting.Column_Name]"
		display_template {
			<a href="@columns.column_url@">@columns.column_name@</a>
		}
	  }
	  group_id {
		label "[_ intranet-reporting.Group_Id]"
	  }
	  sort_order {
		label "[_ intranet-reporting.Sort_Order]"
	  }
	}

	list::create \
			-name column_list \
			-multirow columns \
			-key column_id \
			-actions $action_list \
			-elements $elements_list \
			-filters {
				return_url
			}

	db_multirow -extend {column_url} columns get_columns { 
		select vc.column_id,
			vc.column_name,
			vc.group_id,
			vc.sort_order
		from im_report_columns vc
		where vc.report_id = :report_id
		order by vc.column_name
	} {
		set column_url [export_vars -base "new-column" {report_id column_id return_url}]
	}
}
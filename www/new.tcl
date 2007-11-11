# /packages/intranet-reporting-indicators/www/new.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# all@devcon.project-open.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    New page is basic...
    @author frank.bergmann@project-open.com
} {
    indicator_id:integer,optional
    {return_url "/intranet-reporting-indicators/index"}
    {form_mode "edit"}
}

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-reporting.New_Indicator "New Indicator"]
set context [im_context_bar $page_title]

set action_url "/intranet-reporting-indicators/new"


# ---------------------------------------------------------------
# Options


# ---------------------------------------------------------------
# Setup the form


set actions [list {"Edit" edit} ]
if {[im_permission $user_id add_materials]} {
    lappend actions {"Delete" delete}
}


set form_id "form"
ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action $action_url \
    -actions $actions \
    -mode $form_mode \
    -export {return_url} \
    -form {
	indicator_id:key
	{report_name:text(text) {label "[lang::message::lookup {} intranet-reporting.Indicator_Name {Indicator Name}]"} {html {size 60}}}
	{report_code:text(text) {label "[lang::message::lookup {} intranet-reporting.Indicator_Code {Indicator Code}]"} {html {size 10}}}

	{indicator_widget_min:text(text) {label "[lang::message::lookup {} intranet-reporting.Indicator_Widget_Min {Widget Min}]"} {html {size 10}}}
	{indicator_widget_max:text(text) {label "[lang::message::lookup {} intranet-reporting.Indicator_Widget_Max {Widget Max}]"} {html {size 10}}}
	{indicator_widget_bins:integer(text) {label "[lang::message::lookup {} intranet-reporting.Indicator_Widget_Bins {Widget Bins}]"} {html {size 10}}}

	{report_sql:text(textarea) {label "[lang::message::lookup {} intranet-reporting.Reports_SQL {Report SQL}]"} {html {cols 60 rows 10} }}
	{report_description:text(textarea),optional {label "[lang::message::lookup {} intranet-reporting.Reports_Description {Description}]"} {html {cols 60 rows 4} }}
    }

ad_form -extend -name $form_id \
    -select_query {

	select	r.*,
		i.*
	from	im_reports r,
		im_indicators i
	where	i.indicator_id = :indicator_id
		and i.indicator_id = r.report_id

    } -new_data {

	set indicator_id [db_nextval "acs_object_id_seq"]

	db_exec_plsql create_report "
		SELECT im_indicator__new(
			:indicator_id,
			'im_report',
			now(),
			:user_id,
			'[ad_conn peeraddr]',
			null,

			:indicator_name,
			:indicator_code,
			[im_report_type_indicator],
			[im_report_status_active],
			:report_sql::text,

			:indicator_min::double precision,
			:indicator_max::double precision,
			:indicator_bins::integer
		)
        "

	db_dml edit_report "
		update im_reports set 
			report_description = :indicator_description
		where report_id = :indicator_id
	"

    } -edit_data {

	db_dml edit_report "
		update im_reports set 
			report_name = :report_name,
			report_code = :report_code,
			report_status_id = [im_report_status_active],
			report_type_id = [im_report_type_indicator],
			report_menu_id = null,
			report_sql = :report_sql,
			report_description = :report_description
		where report_id = :indicator_id
	"

	db_dml edit_indicator "
		update im_indicators set 
			indicator_widget_min = :indicator_widget_min::double precision,
			indicator_widget_max = :indicator_widget_max::double precision,
			indicator_widget_bins = :indicator_widget_bins::integer
		where indicator_id = :indicator_id
	"

    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }


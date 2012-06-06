# /packages/intranet-reporting/www/new.tcl
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
    report_id:integer,optional
    {return_url "/intranet-reporting/index"}
    {form_mode "display"}
}

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-reporting.Edit_Report "Edit Report"]
set context [im_context_bar $page_title]
if {![im_permission $user_id "add_reports"]} { 
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.No_ermissions_to_add_or_modify_reports "
	You don't have the necessary permission to add or modify dynamic reports.
    "]
}



# ----------------------------------------------
# Calculate form_mode
if {![info exists report_id]} { set form_mode "edit" }

# ---------------------------------------------------------------
# Options

set report_type_options [db_list_of_lists report_type_options "
	select	report_type, report_type_id
	from	im_report_types
	order by report_type_id
"]

set parent_menu_options [db_list_of_lists parent_menu_options "
	select	m.name, m.menu_id
	from	im_menus m
	where	parent_menu_id in (
			select	menu_id
			from	im_menus
			where 	label = 'reporting'
		)
		and (m.enabled_p is null OR m.enabled_p = 't')
"]



# ---------------------------------------------------------------
# "Delete" Pressed?

set button_pressed [template::form get_action form]
if {"delete" == $button_pressed} {

    if {[catch {
	db_transaction {
	    set menu_id [db_string menu_id "select report_menu_id from im_reports where report_id = :report_id" -default 0]
	    db_string del_report "select im_report__delete(:report_id)"
	    db_string del_report "select im_menu__delete(:menu_id)"
	}
    } err_msg]} {

        ad_return_complaint 1 "<b>Error Deleting Report</b>:<p>
        There are probably still references to this report:<br>
	<pre>$err_msg</pre>
	"
	ad_script_abort
    }

    ad_returnredirect $return_url

}



# ---------------------------------------------------------------
# Setup the form


set actions [list [list [_ intranet-core.Edit] edit] ]
lappend actions [list [_ intranet-core.Delete] delete]

set form_id "form"
ad_form \
    -name $form_id \
    -actions $actions \
    -mode $form_mode \
    -export {next_url user_id return_url} \
    -form {
	report_id:key
	{report_name:text(text) {label "[lang::message::lookup {} intranet-reporting.Report_Name {Report Name}]"} {html {size 60}}}
	{report_code:text(text) {label "[lang::message::lookup {} intranet-reporting.Report_Code {Report Code}]"} {html {size 10}}}
	{parent_menu_id:text(select) {label "[lang::message::lookup {} intranet-reporting.Report_Group {Report Group}]"} {options $parent_menu_options} }
	{report_sort_order:integer(text),optional {label "[lang::message::lookup {} intranet-reporting.Report_Sort_Order {Sort Order}]"}}
	{report_sql:text(textarea) {label "[lang::message::lookup {} intranet-reporting.Reports_SQL {Report SQL}]"} {html {cols 80 rows 20} }}
	{report_description:text(textarea),optional {label "[lang::message::lookup {} intranet-reporting.Reports_Description {Description}]"} {html {cols 80 rows 5} }}
    }

ad_form -extend -name $form_id \
    -select_query {

	select
		r.*,
		m.parent_menu_id
	from
		im_reports r,
		im_menus m
	where
		r.report_id = :report_id
		and m.menu_id = r.report_menu_id

    } -new_data {

	set report_id [db_nextval "acs_object_id_seq"]
#	ad_return_complaint 1 $report_id
	set package_name "intranet-reporting"
	set label [im_mangle_user_group_name $report_name]
	set name $report_name
	set url "/intranet-reporting/view?report_id=$report_id"
	if {![info exists report_sort_order] || "" == $report_sort_order} { set report_sort_order 100 }

	set report_menu_id [db_exec_plsql menu_new "
        	SELECT im_menu__new (
        	        null,                   -- p_menu_id
        	        'im_menu',              -- object_type
        	        now(),                  -- creation_date
        	        null,                   -- creation_user
        	        null,                   -- creation_ip
        	        null,                   -- context_id

        	        :package_name,          -- package_name
        	        :label,                 -- label
        	        :name,                  -- name
        	        :url,                   -- url
        	        :report_sort_order,	-- sort_order
        	        :parent_menu_id,	-- parent_menu_id
        	        null                    -- p_visible_tcl
        	)
	"]

	db_exec_plsql create_report "
		SELECT im_report__new(
			:report_id,
			'im_report',
			now(),
			:user_id,
			'[ad_conn peeraddr]',
			null,

			:report_name,
			:report_code,
			[im_report_type_indicator],
			[im_report_status_active],
			:report_menu_id,
			:report_sql::text
		)
        "

	db_dml edit_report "
		update im_reports set 
			report_sort_order = :report_sort_order,
			report_status_id = [im_report_status_active],
			report_type_id = [im_report_type_simple_sql],
			report_description = :report_description
		where report_id = :report_id
	"

	im_menu_update_hierarchy

    } -edit_data {

	db_dml edit_report "
		update im_reports set 
			report_name = :report_name,
			report_code = :report_code,
			report_sort_order = :report_sort_order,
			report_status_id = [im_report_status_active],
			report_type_id = [im_report_type_simple_sql],
			report_sql = :report_sql,
			report_description = :report_description
		where report_id = :report_id
	"

	set url "/intranet-reporting/view?report_id=$report_id"
	set report_menu_id [db_string report_menu "select report_menu_id from im_reports where report_id = :report_id" -default 0]
	set old_parent_menu_id [db_string report_menu "select parent_menu_id from im_menus where menu_id = :report_menu_id" -default 0]

	db_dml edit_menu "
		update im_menus set
			parent_menu_id = :parent_menu_id,
			url = :url
		where menu_id = :report_menu_id
	"

	im_menu_update_hierarchy


    } -after_submit {


	# Remove all permission related entries in the system cache
	im_permission_flush
	
	# Recalculate the menu hierarchy
	# That's necessary because the reports list is implemented as menus.
	im_menu_update_hierarchy

	ad_returnredirect $return_url
	ad_script_abort
    }



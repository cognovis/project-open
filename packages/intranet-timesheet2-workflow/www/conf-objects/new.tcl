# /packages/intranet-timesheet2-workflow/www/conf-objects/new.tcl
#
# Copyright (C) 2003-2006 ]project-open[
# all@devcon.project-open.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

# Use the page contract only if called as a normal page...
# As a panel, the calling script needs to provide the necessary
# variables.
if {![info exists panel_p]} {

    ad_page_contract {
	New page is basic...
	@author all@devcon.project-open.com
    } {
	conf_id:integer,optional
	{return_url "/intranet-timesheet2-workflow/conf-objects/index"}
	form_mode:optional
	enable_master_p:integer,optional
    }
}

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-timesheet2-workflow.Timesheet_Conf_Object "Timesheet Confirmation"]
set context_bar [im_context_bar $page_title]

if {![info exists enable_master_p]} { set enable_master_p 1}
if {![info exists form_mode]} { set form_mode "display" }
if {![info exists message]} { set message "" }

# ---------------------------------------------------------------
# Options
# ---------------------------------------------------------------

set conf_project_options [im_project_options]
set conf_project_nr ""

if {[info exists conf_id]} {
    # Add the conf_item's project to the options, if not already there
    # Otherwise the component can't show the project's name
    set conf_project_id [db_string conf_pid "select conf_project_id from im_timesheet_conf_objects where conf_id = :conf_id" -default ""]

    set found_p 0
    foreach ptuple $conf_project_options {
	set pid [lindex $ptuple 1]
	if {$pid == $conf_project_id} { set found_p 1 }
    }
    if {!$found_p} {
	set conf_project_name [db_string conf_pid "select project_name from im_projects where project_id = :conf_project_id" -default ""]
	lappend conf_project_options [list $conf_project_name $conf_project_id]
    }
    set conf_project_nr [db_string conf_pid "select project_nr from im_projects where project_id = :conf_project_id" -default ""]
}

set conf_type_options [db_list_of_lists conf_type_options "
	select	conf_type, conf_type_id
	from	im_timesheet_conf_object_types
	order by conf_type_id
"]
set conf_status_options [db_list_of_lists conf_status_options "
	select	conf_status, conf_status_id
	from	im_timesheet_conf_object_status
	order by conf_status_id
"]

set conf_user_options [db_list_of_lists conf_user_options "
	select	im_name_from_user_id(p.person_id), p.person_id
	from	persons p
	-- where	p.person_id = :user_id
"]



# ------------------------------------------------------------------
# Actions & Their Permissions
# ------------------------------------------------------------------

set actions [list]

if {[info exists conf_id]} {

    if {![ad_form_new_p -key conf_id]} {
	set conf_exists_p [db_string count "select count(*) from im_timesheet_conf_objects where conf_id=:conf_id"]
	if {!$conf_exists_p} {
	    ad_return_complaint 1 "<b>Error: The selected Confirmation Object (#$conf_id) does not exist</b>:<br>
	The object has probably been deleted by its owner recently."
	    ad_script_abort
	}
    }

    set edit_perm_func [parameter::get_from_package_key -package_key intranet-timesheet2-workflow -parameter TimesheetConfNewPageWfEditButtonPerm -default "im_timesheet_conf_new_page_wf_perm_edit_button"]
    set delete_perm_func [parameter::get_from_package_key -package_key intranet-timesheet2 -parameter TimesheetConfNewPageWfDeleteButtonPerm -default "im_timesheet_conf_new_page_wf_perm_delete_button"]

    if {[eval [list $edit_perm_func -conf_id $conf_id]]} {
        lappend actions [list [lang::message::lookup {} intranet-timesheet2.Edit Edit] edit]
    }
    if {[eval [list $delete_perm_func -conf_id $conf_id]]} {
        lappend actions [list [lang::message::lookup {} intranet-timesheet2.Delete Delete] delete]
    }
}

# ------------------------------------------------------------------
# Delete pressed?
# ------------------------------------------------------------------

set button_pressed [template::form get_action form]
if {"delete" == $button_pressed} {
    db_string conf_delete "select im_timesheet_conf_object__delete(:conf_id)"
    ad_returnredirect $return_url
}

# ---------------------------------------------------------------
# The Form
# ---------------------------------------------------------------

set form_id "form"
ad_form \
    -name $form_id \
    -mode $form_mode \
    -export "object_id return_url" \
    -actions $actions \
    -has_edit 1 \
    -action "/intranet-timesheet2-workflow/conf-objects/new" \
    -form {
	conf_id:key
	{conf_project_id:text(select) {label "[lang::message::lookup {} intranet-timesheet2-workflow.Conf_Project Project]"} {options $conf_project_options} {before_html $conf_project_nr} }
	{conf_user_id:text(select) {label "[lang::message::lookup {} intranet-timesheet2-workflow.Conf_User User]"} {options $conf_user_options} }
	{start_date:date(date),optional {label "[_ intranet-timesheet2.Start_Date]"} {}}
	{end_date:date(date),optional {label "[_ intranet-timesheet2.End_Date]"} {}}
	{conf_type_id:text(select) {label "[lang::message::lookup {} intranet-timesheet2-workflow.Conf_Type Type]"} {options $conf_type_options} }
	{conf_status_id:text(select) {label "[lang::message::lookup {} intranet-timesheet2-workflow.Conf_Status Status]"} {options $conf_status_options} }
    }

ad_form -extend -name $form_id \
    -select_query {

	select	*
	from	im_timesheet_conf_objects
	where	conf_id = :conf_id

    } -new_data {
	db_exec_plsql create_conf "
		SELECT im_conf__new(
			:conf_id,
			'im_conf',
			now(),
			:user_id,
			'[ad_conn peeraddr]',
			null,
			:conf,
			:object_id,
			:conf_type_id,
			[im_conf_status_active]
		)
        "
    } -edit_data {
	db_dml edit_conf "
		update im_confs
		set conf = :conf
		where conf_id = :conf_id
	"
    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }


# ---------------------------------------------------------------
# Show comments made during the approval process
# ---------------------------------------------------------------

set show_comment_p [parameter::get -package_id [apm_package_id_from_key intranet-timesheet2-workflow] -parameter "ShowCommentsInPanel" -default 1]

if { $show_comment_p } {
    set comment [db_string get_comment "select comment from im_timesheet_conf_objects where conf_id = :conf_id" -default 0]
}

# ---------------------------------------------------------------
# Format the link to modify hours
# ---------------------------------------------------------------


set modify_hours_link ""
if {[info exists conf_id]} {
   set conf_user_id [db_string conf_user "select conf_user_id from im_timesheet_conf_objects where conf_id = :conf_id" -default 0]
   if {$conf_user_id == $user_id} {

       set julian_date [db_string ts_date "
		select	to_char(co.start_date, 'J')
		from	im_timesheet_conf_objects co
		where	conf_id = :conf_id
       " -default ""]

       set modify_hours_msg [lang::message::lookup "" intranet-timesheet2-workflow.Modify_Included_Hours "Modify Included Hours"]
       set modify_hours_url [export_vars -base "/intranet-timesheet2/hours/new" {julian_date {show_week_p 1}}]
       set modify_hours_link "<a href='$modify_hours_url'>$modify_hours_msg</a>"
       set modify_hours_link "<ul>\n<li>$modify_hours_link</li>\n</ul><br>\n"
   }
}


# ---------------------------------------------------------------
# Show the included hours
# ---------------------------------------------------------------

set included_hours_msg [lang::message::lookup "" intranet-timesheet2-workflow.Included_Hours "Included Hours"]

set export_var_list [list]
set bulk_actions_list [list]
set list_id "included_hours"

template::list::create \
    -name $list_id \
    -multirow multirow \
    -key conf_id \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {	object_id } \
    -row_pretty_plural "[_ intranet-timesheet2-workflow.Included_Hours]" \
    -elements {
	date_pretty {
	    label "[lang::message::lookup {} intranet-timesheet2-workflow.Date Date]"
	}
	project_name {
	    label "[_ intranet-timesheet2.Project]"
	    link_url_eval {[export_vars -base "/intranet/projects/view" {project_id}]}
	}
        conf_user_name {
	    label "[_ intranet-timesheet2.User]"
	    link_url_eval "/intranet/users/view?user_id=$user_id"
	}
	hours {
	    label "[lang::message::lookup {} intranet-timesheet2-workflow.Hours Hours]"
	}
	note {
	    label "[lang::message::lookup {} intranet-timesheet2-workflow.Note Note]"
	}
    }

set ttt {
	conf_chk {
	    label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('confs_list', this.checked)\" 
                          title=\"Check/uncheck all rows\" disabled>"
	    display_template {
		@multirow.conf_chk;noquote@
	    }
	}
}


if {![info exists conf_id]} { ad_return_complaint 1 "Error: conf_id doesn't exist" }


# ad_return_complaint 1 $conf_id


db_multirow -extend {conf_chk return_url period} multirow multirow "
	select
		h.*,
		co.*,
		p.project_name,
		im_name_from_user_id(co.conf_user_id) as conf_user_name,
		to_char(h.day, 'YYYY-MM-DD') as date_pretty
	from
		im_hours h,
		im_projects p,
		im_timesheet_conf_objects co
	where
		h.project_id = p.project_id
		and co.conf_id = :conf_id
		and h.conf_object_id = co.conf_id
	order by
		h.day,
		lower(p.project_name)
" {
    set return_url [im_url_with_query]
    set conf_chk "<input type=\"checkbox\" name=\"conf_id\" value=\"$conf_id\" id=\"confs_list,$conf_id\" disabled>"
}




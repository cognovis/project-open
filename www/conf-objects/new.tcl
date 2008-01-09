# /packages/intranet-timesheet2-workflow/www/new.tcl
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

# ---------------------------------------------------------------
# Options
# ---------------------------------------------------------------

set conf_project_options [im_project_options]
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
	where	p.person_id = :user_id
"]



# ------------------------------------------------------------------
# Delete pressed?
# ------------------------------------------------------------------

set actions [list [list [lang::message::lookup {} intranet-timesheet2.Edit Edit] edit] ]

# You need to be the owner of the conf in order to delete it.
if {[info exists conf_id]} {
    set owner_id [db_string owner "select creation_user from acs_objects where object_id = :conf_id" -default 0]
    if {$user_id == $owner_id} {
        lappend actions {"Delete" delete}
    }
}

set button_pressed [template::form get_action form]
if {"delete" == $button_pressed} {
    db_dml del_tokens "delete from wf_tokens where case_id in (select case_id from wf_cases where object_id = :conf_id)"
    db_dml del_case "delete from wf_cases where object_id = :conf_id"
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
    -action "/intranet-timesheet2-workflow/conf-objects/new" \
    -form {
	conf_id:key
	{conf_project_id:text(select) {label "[lang::message::lookup {} intranet-timesheet2-workflow.Conf_Project Project]"} {options $conf_project_options} }
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
# Format the link to modify hours
# ---------------------------------------------------------------


set modify_hours_link ""
if {[info exists conf_id]} {
   set conf_user_id [db_string conf_user "select conf_user_id from im_timesheet_conf_objects where conf_id = :conf_id" -default 0]
   if {$conf_user_id == $user_id} {
       set modify_hours_msg [lang::message::lookup "" intranet-timesheet2-workflow.Modify_Included_Hours "Modify Included Hours"]
       set modify_hours_url [export_vars -base "/intranet-timesheet2/hours/new" {julian_date}]
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




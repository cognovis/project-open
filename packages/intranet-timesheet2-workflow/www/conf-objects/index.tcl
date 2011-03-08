# /packages/intranet-timesheet2-workflow/www/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author frank.bergmann@project-open.com
} {
    { object_id 0}
    { form_mode "edit" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set page_focus "im_header_form.keywords"
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set date_format "YYYY-MM-DD"
set object_name [db_string object_name "select acs_object__name(:object_id)" -default [lang::message::lookup "" intranet-expenes.Unassigned "Unassigned"]]
set page_title [_ intranet-timesheet2-workflow.Timesheet_Approval]
set context_bar [im_context_bar $page_title]

set return_url [im_url_with_query]
set current_url [ns_conn url]



# ---------------------------------------------------------------
# Admin Links
# ---------------------------------------------------------------

set admin_links ""
append admin_links " <li><a href=\"new?[export_url_vars object_id return_url]\">[_ intranet-timesheet2-workflow.Add_a_new_Conf]</a>\n"
if {"" != $admin_links} { set admin_links "<ul>\n$admin_links</ul>\n" }

set bulk_actions_list "[list]"
#[im_permission $user_id "delete_expense"]
set delete_expense_p 1 
if {$delete_expense_p} {
    lappend bulk_actions_list "[_ intranet-timesheet2-workflow.Delete]" "confs-del" "[_ intranet-timesheet2-workflow.Remove_checked_items]"
}
#[im_permission $user_id "add_expense_bundle"]
set create_invoice_p 1
if {$create_invoice_p} {
}

# ---------------------------------------------------------------
# Expenses info
# ---------------------------------------------------------------

# Variables of this page to pass through the expenses_page

set export_var_list [list]

# define list object
set list_id "confs_list"


template::list::create \
    -name $list_id \
    -multirow conf_lines \
    -key conf_id \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {
	object_id
    } \
    -row_pretty_plural "[_ intranet-timesheet2-workflow.Confs_Items]" \
    -elements {
	conf_chk {
	    label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('confs_list', this.checked)\" 
                          title=\"Check/uncheck all rows\">"
	    display_template {
		@conf_lines.conf_chk;noquote@
	    }
	}
	period {
	    label "[lang::message::lookup {} intranet-timesheet2-workflow.Period Period]"
	    link_url_eval {[export_vars -base "/intranet-timesheet2-workflow/conf-objects/new" {conf_id {form_mode display}}]}
	}
	project_name {
	    label "[_ intranet-timesheet2-workflow.Project]"
	    link_url_eval {[export_vars -base "/intranet/projects/view" {project_id}]}
	}
        conf_user_name {
	    label "[_ intranet-timesheet2-workflow.Conf_User]"
	    link_url_eval "/intranet/users/view?user_id=$conf_user_id"
	}
    }


set owner_where "and co.conf_user_id = :user_id"
if {[im_permission $user_id "view_timesheet_conf_all"]} { set owner_where ""}

db_multirow -extend {conf_chk return_url period} conf_lines confs_lines "
	select	co.*,
		p.project_name,
		im_name_from_user_id(co.conf_user_id) as conf_user_name
	from	im_timesheet_conf_objects co
		LEFT OUTER JOIN im_projects p ON (co.conf_project_id = p.project_id)
	where
		1=1
		$owner_where
" {
    set return_url [im_url_with_query]
    set conf_chk "<input type=\"checkbox\" name=\"conf_id\" value=\"$conf_id\" id=\"confs_list,$conf_id\">"
    set period "$start_date - $end_date"
}


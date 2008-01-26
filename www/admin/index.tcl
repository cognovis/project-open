# /packages/intranet-simple-survey/www/admin/index.tcl
#
#
# Copyright (C) 2003-2006 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Show the permissions for all menus in the system

    @author frank.bergmann@project-open.com
} {
    { return_url "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

if {"" == $return_url} { set return_url [ad_conn url] }

set page_title [lang::message::lookup "" intranet-simple-survey.Survey_Schedules "Survey Schedules"]
set context_bar [im_context_bar [list /intranet-simple-survey/ "Simple Surveys"] $page_title]

set survsimp_url "/intranet-simple-survey/admin/new"
set toggle_url "/intranet/admin/toggle"
set group_url "/admin/groups/one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

set survsimp_package_id [im_package_survsimp_id]

# ------------------------------------------------------
#
# ------------------------------------------------------

set bulk_actions_list "[list]"
#[im_permission $user_id "delete_expense"]
set delete_expense_p 1 
if {$delete_expense_p} {
    lappend bulk_actions_list "[_ intranet-simple-survey.Delete]" "confs-del" "[_ intranet-simple-survey.Remove_checked_items]"
}
#[im_permission $user_id "add_expense_bundle"]
set create_invoice_p 1
if {$create_invoice_p} {
}

lappend action_list "[lang::message::lookup {} intranet-simple-survey.Create_New_Schedule {Create New Schedule}]" "new" "[lang::message::lookup {} intranet-simple-survey.New_Schedule_Help {New Schedule Help}]"


# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

set export_var_list [list]
set list_id "confs_list"

set elements {
	conf_chk {
	    label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('confs_list', this.checked)\" 
                          title=\"Check/uncheck all rows\">"
	    display_template {
		@conf_lines.conf_chk;noquote@
	    }
	}
	object_type {
	    label "[lang::message::lookup {} intranet-simple-survey.Object_Type {Object Type}]"
	}
	survey_name {
	    label "[lang::message::lookup {} intranet-simple-survey.Survey_Name {Survey Name}]"
	    link_url_eval {[export_vars -base "/simple-survey/one" {survey_id}]}
	}
        conf_user_name {
	    label "[_ intranet-simple-survey.Conf_User]"
	    link_url_eval "/intranet/users/view?user_id=$conf_user_id"
	}
}

# ---------------------------------------------------------------
# Extend the "elements" list by profiles
# ---------------------------------------------------------------

set group_list_sql {
	select DISTINCT
		g.group_name,
		g.group_id,
		p.profile_gif
	from
		acs_objects o,
		groups g,
		im_profiles p
	where
		g.group_id = o.object_id
		and g.group_id = p.profile_id
		and o.object_type = 'im_profile'
}

db_foreach group_list $group_list_sql {

    # Select out an additional permission
    append main_sql_select "\tim_object_permission_p(ss.survey_id, $group_id, 'read') as p${group_id}_read_p,\n"

    # Add the colum to the list
    regsub { } $group_name "_" group_name_key
    set group_name_l10n [lang::message::lookup {} intranet-simple-survey.$group_name_key $group_name]
    lappend elements p${group_id}_read_p
    lappend elements [list \
		      label [im_gif $profile_gif $group_name_l10n] \
		      link_url_eval {[export_vars -base "/simple-survey/one" {survey_id}]} \
    ]
    
}


template::list::create \
    -name $list_id \
    -multirow conf_lines \
    -key conf_id \
    -has_checkboxes \
    -actions $action_list \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {
	object_id
    } \
    -row_pretty_plural "[_ intranet-simple-survey.Confs_Items]" \
    -elements $elements


db_multirow -extend {conf_chk return_url period} conf_lines confs_lines "
	select
		${main_sql_select}
		s.*,
		ss.*,
		aot.pretty_name as object_type_pretty_name
	from
		im_survsimp_schedules s,
		survsimp_surveys ss,
		acs_object_types aot
	where
		s.schedule_survey_id = ss.survey_id
		and s.schedule_context_object_type = aot.object_type
" {
    set return_url [im_url_with_query]
    set conf_chk "<input type=\"checkbox\" name=\"conf_id\" value=\"$conf_id\" id=\"confs_list,$conf_id\">"
    set period "$start_date - $end_date"
}

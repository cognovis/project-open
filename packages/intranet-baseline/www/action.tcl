# /packages/intranet-baseline/www/action.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Takes commands from the /intranet-baseline/index page or 
    the baselines-list-compomponent and perform the selected 
    action an all selected baselines.
    @author frank.bergmann@project-open.com
} {
    action
    baseline:array,optional
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

set baseline_list [array names baseline]
if {0 == [llength $baseline_list]} { ad_returnredirect $return_url }

switch $action {
    del_baselines {
	foreach baseline_id $baseline_list {

	    set project_id [db_string baseline_pid "select baseline_project_id from im_baselines where baseline_id = :baseline_id" -default 0]
	    im_project_permissions $user_id $project_id view read write admin
	    set del_baselines_p [im_permission $user_id "del_baselines"]
	    if {!$admin || !$del_baselines_p} {
		ad_return_complaint 1 "You don't have permissions to delete this baseline"
		ad_script_abort
	    }

	    db_transaction {
		db_dml del_audit "delete from im_audits where audit_id in (select audit_id from im_projects_audit where baseline_id = :baseline_id)"
		db_dml del_projects_audit "delete from im_projects_audit where baseline_id = :baseline_id"
		db_string del_baselines "select im_baseline__delete(:baseline_id)"
	    }
	}
    }
    default {
	ad_return_complaint 1 "<li>Unknown action: '$action'"
    }
}

ad_returnredirect $return_url


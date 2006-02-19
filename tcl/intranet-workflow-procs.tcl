# /packages/intranet-workflow/tcl/intranet-workflow-procs.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_package_workflow_id {} {
    Returns the package id of the intranet-workflow module
} {
    return [util_memoize "im_package_workflow_id_helper"]
}

ad_proc -private im_package_workflow_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-workflow'
    } -default 0]
}



# ----------------------------------------------------------------------
# Workflow Task List Component
# ---------------------------------------------------------------------

ad_proc -public im_workflow_home_component {
} {
    Creates a HTML table showing all currently active tasks
} {
    set user_id [ad_get_user_id]
    set admin_p [ad_permission_p [ad_conn package_id] "admin"]

    set template_file "packages/acs-workflow/www/task-list"
    set template_path [get_server_root]/$template_file
    set template_path [ns_normalizepath $template_path]

    set package_url "/workflow/"

    set own_tasks [template::adp_parse $template_path [list package_url $package_url type own]]
    set all_tasks [template::adp_parse $template_path [list package_url $package_url]]

    if {[string length own_tasks] < 50} { set own_tasks "" }
    if {[string length unassigned_tasks] < 50} { set unassigned_tasks "" }

    set component_html "
<table cellspacing=1 cellpadding=0>
<tr><td>
$own_tasks
$all_tasks
</td></tr>
</table>
"

    return $component_html
}


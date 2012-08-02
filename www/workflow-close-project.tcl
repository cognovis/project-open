# /packages/intranet-cust-kw/www/workflow-close-project.tcl
#
# Copyright (C) 2003 - 2012 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.
#
#
# -----------------------------------------------------------

# Trigger WF 
# Create a new workflow case (instance)

ad_page_contract {
    View all the info about a specific project.

    @param project_id the group id
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
} {
    { project_id:integer 0}
    { close_projects_p ""}
}

set project_id_bak $project_id
	
if { "" == $close_projects_p } {
	# First call, add validation  
	ns_returnredirect "workflow-close-project-prestep?project_id=$project_id"
} else {
	set output_html ""

	if { $close_projects_p } {
		
	    	set sql "
		        select
                		p_child.project_id,
		                p_child.project_name,
				p_child.project_status_id
		        from
                		im_projects p_parent,
		                im_projects p_child
		        where
                		p_child.tree_sortkey between p_parent.tree_sortkey and tree_right(p_parent.tree_sortkey)
		                and p_parent.project_id = :project_id
		                and p_child.project_status_id <> [im_project_status_closed]
				and p_child.project_id <> :project_id
		"
		db_foreach sql $sql {
			im_project_audit -project_id $project_id
		        append output_html "$project_id $project_name <br>"
			db_dml project_update "update im_projects set project_status_id = [im_project_status_closed] where project_id = :project_id"
		    	im_audit -object_type im_project -action after_update -object_id $project_id -status_id $project_status_id
		}

		if { "" != $output_html } {
			set output_html "Folgende Projekte wurden geschlossen:<br>$output_html"
		}

		set context_key ""
		set case_id [wf_case_new \
		     [parameter::get -package_id [apm_package_id_from_key intranet-cust-koernigweber] -parameter "WorkflowCloseProject" -default ""] \
                     $context_key \
                     $project_id \
		]
		# Determine the first task in the case to be executed and start+finisch the task.
		im_workflow_skip_first_transition -case_id $case_id
		set project_name [db_string get_project_name "select project_name where project_id = :project_id_bak" -default 0]
		append output_html "<br><br>Ein Workflow zum Schliessen des Projekts:"
		append output_html "<a href="/intranet/projects/view?project_id=$project_id_bak">$project_name</a> wurde gestarted."
		append output_html "<br>Mitglieder der Gruppe 'Gesch&auml;ftsleitung' wurden informiert."
	} else {
		set output_html "Der Workflow konnte nicht gestarted werden da nicht alle Unterprojekte geschlossen sind"		
	}
}







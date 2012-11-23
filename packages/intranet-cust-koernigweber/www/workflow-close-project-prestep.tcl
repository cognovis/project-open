# /packages/intranet-cust-kw/www/workflow-close-project-prestep.tcl
#
# Copyright (C) 2003 - 2011 ]project-open[
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
}

set project_id_bak $project_id

# Check for subprojects not closed 
set sql "
	select
		p_child.project_id, 
		p_child.project_name
	from
		im_projects p_parent,
		im_projects p_child
	where
		p_child.tree_sortkey between p_parent.tree_sortkey and tree_right(p_parent.tree_sortkey)
		and p_parent.project_id = :project_id 
		and p_child.project_status_id <> [im_project_status_closed]
		and p_child.project_id <> :project_id 
"

set projects_not_closed_html ""

db_foreach sql $sql {
	append projects_not_closed_html "<a href='/intranet/projects/view?project_id=$project_id'>$project_id $project_name</a> <br>"
}

if { "" == $projects_not_closed_html } {
	ns_returnredirect "workflow-close-projects?project_id=$project_id_bak&close_projects_p=0"
} 







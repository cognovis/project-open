# /packages/intranet-cust-kw/www/workflow-close-project.tcl
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

set context_key ""
set case_id [wf_case_new \
                     project_approval2_wf \
                     $context_key \
                     $project_id \
		 ]
# Determine the first task in the case to be executed and start+finisch the task.
im_workflow_skip_first_transition -case_id $case_id






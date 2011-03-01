# /packages/intranet-expenses-workflow/tcl/intranet-expenses-workflow-procs.tcl
#
# Copyright (C) 1998-2007 ]project-open[
# All rights reserved

ad_library {
    Definitions for the intranet expenses workflow
    @author frank.bergmann@project-open.com
}

# ---------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------

ad_proc -public im_expenses_workflow_installed_p {} { return 1 }


# ---------------------------------------------------------------------
# Create a new workflow after logging hours
# ---------------------------------------------------------------------

ad_proc -public im_expenses_workflow_spawn_workflow {
    -expense_bundle_id:required
    -user_id:required
    {-workflow_key "expense_approval_wf" }
} {
    Check if there is already a WF running for that expense bundle
    and either reset this WF or create a new one if there wasn't one before.
    @author frank.bergmann@project-open.com
} {
    # ---------------------------------------------------------------
    # Setup & Defaults

    set wf_user_id $user_id
    set user_id [ad_maybe_redirect_for_registration]

    # ---------------------------------------------------------------
    # Check if the WF-Key is valid

    set wf_valid_p [db_string wf_valid_check "
	select count(*)
	from acs_object_types
	where object_type = :workflow_key
    "]
    if {!$wf_valid_p} {
	ad_return_complaint 1 "Workflow '$workflow_key' does not exist"
	ad_script_abort
    }

    # ---------------------------------------------------------------
    # Determine the case for the object or create it.

    set context_key ""
    set case_ids [db_list case "
    	select	case_id
	from	wf_cases
	where	object_id = :expense_bundle_id
		and workflow_key = :workflow_key
    "]
    ns_log Notice "spawn_update_workflow: case_ids = $case_ids"

    if {[llength $case_ids] == 0} {
        ns_log Notice "spawn_update_workflow: new case: wf_case_new $workflow_key $context_key $expense_bundle_id"
	set case_id [wf_case_new \
		$workflow_key \
		$context_key \
		$expense_bundle_id
        ]
	ns_log Notice "spawn_update_workflow: case_id = $case_id"

	# Determine the first task in the case to be executed and start+finisch the task.
	im_workflow_skip_first_transition -case_id $case_id

	# Set the default value for "sign_off_ok" to "t"
	set attrib "approve_approve_this_expense_bundle_p"
	db_string set_attribute_value "select acs_object__set_attribute (:case_id,:attrib,'t')"

    } else {
        set case_id [lindex $case_ids 0]
    }

    return $case_id
}


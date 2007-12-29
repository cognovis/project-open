# /intranet-workflow/www/inbox-action.tcl

ad_page_contract {
    Delete a specific task from an inbox
    @author Frank Bergmann <frank.bergmann@project-open.com>
} {
    action:multiple,optional
    { operation "" }
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
if {![info exists action]} { set action [list] }


foreach object_id $action {
    switch $operation {
	delete_membership {

	    # Delete a membership-rel between the user and the object
	    # (if exists, this is the case of a project or a company).
	    im_exec_dml delete_user "user_group_member_del (:object_id, :user_id)"
	    
	    # Delete the assignation to all tasks in state "enabled".
	    db_dml del_task_assignments "
		delete from wf_task_assignments
		where	party_id = :user_id
			and task_id in (
				select	wft.task_id
				from	wf_tasks wft,
					wf_cases wfc
				where
					wfc.object_id = :object_id
					and wft.case_id = wfc.case_id
					and wft.state in ('enabled')
			)
	    "
	}
	default {
	    # nada...
	}
    }
}

ad_returnredirect $return_url





# /intranet-workflow/www/inbox-action.tcl

ad_page_contract {
    Delete a specific task from an inbox
    @author Frank Bergmann <frank.bergmann@project-open.com>
} {
    action:multiple,optional
    task_id:multiple,optional
    { operation "" }
    return_url
}

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

if {![info exists action]} { set action [list] }
if {![info exists task_id]} { set task_id [list] }

foreach object_id $action {
    switch $operation {
	delete_membership {

	    # Delete a membership-rel between the user and the object
	    # (if exists, this is the case of a project or a company).
	    im_exec_dml delete_user "user_group_member_del (:object_id, :current_user_id)"
	    
	    # Delete the assignation to all tasks in state "enabled".
	    db_dml del_task_assignments "
		delete from wf_task_assignments
		where	party_id = :current_user_id
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
	nuke {
	    ad_return_complaint 1 "nuke"	    
	}
	default {
	    ad_return_complaint 1 "Unknown inbox action: '$operation'"
	}
    }
}

foreach tid $task_id {

    set object_id ""
    set object_type ""
    db_0or1row task_info "
		select
			wfc.object_id,
			o.object_type
		from
			wf_tasks wft,
			wf_cases wfc,
			acs_objects o
		where
			wft.task_id = :tid and
			wft.case_id = wfc.case_id and
			wfc.object_id = o.object_id
    "

    switch $operation {
	delete_membership {
	    ad_return_complaint 1 "Unknown inbox action: '$operation'"
	}
	nuke {
	    switch $object_type {
		im_ticket - im_project {
		    if {!$user_is_admin_p} { ad_return_complaint 1 "You need to be an administrator to nuke an object." }
		    im_project_nuke $object_id
		}
		default {
		    ad_return_complaint 1 "Unable to nuke objects of type '$object_type'"
		    ad_script_abort
		}
	    }
	}
	default {
	    ad_return_complaint 1 "Unknown inbox action: '$operation'"
	    ad_script_abort
	}
    }
}

ad_returnredirect $return_url





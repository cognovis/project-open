# /intranet-ganttproject/www/fix-tasks-with-overallocation.tcl

ad_page_contract {
    Set the tasks's resource assignment so that MS-Project will
    calculate the same end-date as the one specified.
    @author frank.bergmann@project-open.com
} {
    project_id:integer,notnull
    checked:array
    rel_id:array
    task_id:array
    user_id:array
    percent:array
    return_url
    action
}

set main_project_id $project_id
set warning_key "fix-tasks-with-unassigned-skill-profiles"

switch $action {
    fix {
	foreach rid [array names checked] {

	    set status $checked($rid)
	    set tid $task_id($rid)
	    set uid $user_id($rid)
	    set perc $percent($rid)

	    # Skip if the task checkbox is unchecked or no user was selected.
	    if {"on" != $status || "" == $uid || "" == $tid || "" == $perc} { continue }

	    # Add the guy to the project with a certain percentage
	    set new_rel_id [im_biz_object_add_role -percentage $perc $uid $tid [im_biz_object_role_full_member]]
	    # Let the new acs_rel point to the original rel_id of the skill_profile.
	    # This way we know which is an instance and which is the skill profile assignment.
	    db_dml update_skill_inst "update im_biz_object_members set skill_profile_rel_id = :rid where rel_id = :new_rel_id"
	}
    }

    ignore_this {
	db_dml del_ignore "
		delete from im_gantt_ms_project_warning
		where	user_id = [ad_get_user_id] and warning_key = :warning_key
	"
	db_dml insert_ignore "
		insert into im_gantt_ms_project_warning (user_id, warning_key, project_id) 
		values ([ad_get_user_id], :warning_key, :project_id)
	"
    }
    ignore_all {
	db_dml del_ignore "
		delete from im_gantt_ms_project_warning
		where	user_id = [ad_get_user_id] and warning_key = :warning_key
	"
	db_dml insert_ignore "
		insert into im_gantt_ms_project_warning (user_id, warning_key, project_id) 
		values ([ad_get_user_id], :warning_key,	null)
	"
    }

}

ad_returnredirect $return_url

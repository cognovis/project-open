# /intranet-ganttproject/www/fix-tasks-without-start-constraint.tcl

ad_page_contract {
    Set the project's start_date to the start date of the earliest task
    @author frank.bergmann@project-open.com
} {
    project_id:integer,notnull
    task_id:array
    return_url
    action
}

set main_project_id $project_id
set warning_key "fix-tasks-without-start-constraint"

# ad_return_complaint 1 "action=$action, [array names task_id]"

switch $action {
    fix {
	foreach tid [array names task_id] {
	
	    set tid_where "p.project_id = :tid"
	    if {0 == $tid} {
		# Wildcard: fix all tasks below project_id
		set tid_where "p.project_id in (
			select	p.project_id
			from	im_projects main_p,
				im_projects p,
				im_timesheet_tasks t
			where	main_p.project_id = :main_project_id and
				p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
				p.project_id = t.task_id and
				-- the task starts after the main project
				p.start_date::date > main_p.start_date::date and
				-- start as early as possible
				(t.scheduling_constraint_id = 9700 or t.scheduling_constraint_id is null)
			)
		"
	    }

	    db_dml set_start_constraint "
		update	im_timesheet_tasks
		set	scheduling_constraint_id = [im_timesheet_task_scheduling_type_mso],
			scheduling_constraint_date = p.start_date
		from	im_projects p,
			im_timesheet_tasks t
		where	p.project_id = t.task_id and
			p.project_id = im_timesheet_tasks.task_id and
			$tid_where
	    "

	    set audit_tids [db_list audit_tids "select p.project_id from im_projects p where $tid_where"]
	    foreach audit_tid $audit_tids {
		im_audit -object_id $tid
	    }
	}
    }

    ignore_this {
	db_dml del_ignore "
		delete from im_gantt_ms_project_warning
		where	user_id = [ad_get_user_id] and
			warning_key = :warning_key
	"
	db_dml insert_ignore "
		insert into im_gantt_ms_project_warning (
			user_id,
			warning_key,
			project_id
		) values (
			[ad_get_user_id],
			:warning_key,
			:project_id
		)
	"
    }
    ignore_all {
	db_dml del_ignore "
		delete from im_gantt_ms_project_warning
		where	user_id = [ad_get_user_id] and
			warning_key = 'fix-tasks-start-before-main-project'
	"
	db_dml insert_ignore "
		insert into im_gantt_ms_project_warning (
			user_id,
			warning_key,
			project_id
		) values (
			[ad_get_user_id],
			'fix-tasks-start-before-main-project',
			null
		)
	"
    }

}

ad_returnredirect $return_url

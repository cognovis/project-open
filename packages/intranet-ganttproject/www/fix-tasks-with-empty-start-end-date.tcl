# /intranet-ganttproject/www/fix-tasks-with-empty-start-end-date.tcl

ad_page_contract {
    Allow the user to set the task's start and end dates
    @author frank.bergmann@project-open.com
} {
    project_id:integer,notnull
    task_id:array
    return_url
    action
}

set main_project_id $project_id
set warning_key "fix-tasks-with-empty-start-end-date"

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
				p.project_id = t.task_id
			)
		"
	    }

	    db_dml set_start_constraint "
		update	im_projects
		set	start_date = coalesce(im_projects.start_date, main_p.start_date),
			end_date = coalesce(im_projects.end_date, main_p.end_date)
		from	im_projects main_p,
			im_projects p
		where	(im_projects.start_date is null or im_projects.end_date is null) and
			im_projects.project_id = p.project_id and
			main_p.project_id = :main_project_id and
			p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
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

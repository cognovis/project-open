# /intranet-ganttproject/www/fix-tasks-start-before-main-project.tcl

ad_page_contract {
    Set the project's start_date to the start date of the earliest task
    @author frank.bergmann@project-open.com
} {
    project_id:integer,notnull
    return_url
    action
}

switch $action {
    fix {
	# Check for tasks that start before the main project's start
	set sql "
		select	p.project_id as task_id,
			p.project_name as task_name,
			p.start_date as task_start_date,
			main_p.start_date::date as main_project_start_date
		from	im_projects main_p,
			im_projects p
			LEFT OUTER JOIN im_timesheet_tasks t ON (p.project_id = t.task_id)
		where	main_p.project_id = :project_id and
			main_p.parent_id is null and
			p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
			p.start_date < main_p.start_date
        "

	set new_main_start_date [db_string new_main_start_date "select min(task_start_date) from ($sql) t" -default ""]
	
	if {"" != $new_main_start_date} {
	    db_dml update_main_project "
		update im_projects
		set start_date = :new_main_start_date
		where project_id = :project_id
            "
	    
	    im_audit -object_id $project_id
	}
    }
    ignore_this {
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

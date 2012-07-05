# /intranet-ganttproject/www/fix-tasks-with-overallocation.tcl

ad_page_contract {
    Set the tasks's resource assignment so that MS-Project will
    calculate the same end-date as the one specified.
    @author frank.bergmann@project-open.com
} {
    project_id:integer,notnull
    task_id:array
    return_url
    action
}

set main_project_id $project_id
set warning_key "fix-tasks-with-overallocation"

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

	    set task_select_sql "
		select	t.*,
			percentage_skill_profiles + percentage_non_skill_profiles as percentage_sum,
			greatest(percentage_skill_profiles, percentage_non_skill_profiles) as percentage
		from	(
		select	t.planned_units,
			t.uom_id,
			p.project_id,
			p.project_name,
			p.start_date,
			p.end_date,

			coalesce((select sum(coalesce(bom.percentage, 0.0))
			from	acs_rels r,
				im_biz_object_members bom,
				users u
			where	r.object_id_one = p.project_id and
				r.object_id_two = u.user_id and
				r.rel_id = bom.rel_id and
				u.user_id in (
					select member_id from group_distinct_member_map 
					where group_id = (select group_id from groups where group_name = 'Skill Profile')
				)
			), 0.0) as percentage_skill_profiles,

			coalesce((select sum(coalesce(bom.percentage, 0.0))
			from	acs_rels r,
				im_biz_object_members bom,
				users u
			where	r.object_id_one = p.project_id and
				r.object_id_two = u.user_id and
				r.rel_id = bom.rel_id and
				u.user_id not in (
					select member_id from group_distinct_member_map 
					where group_id = (select group_id from groups where group_name = 'Skill Profile')
				)
			), 0.0) as percentage_non_skill_profiles

		from	im_projects p,
			im_timesheet_tasks t
		where	p.project_id = t.task_id and
			$tid_where
		) t
	    "
	    db_foreach tasks_with_overallocation $task_select_sql {

		# Calculate the overallocation factor in order to reduce the resource assignments
		set seconds_in_interval [im_ms_calendar::seconds_in_interval -start_date $start_date -end_date $end_date -calendar [im_ms_calendar::default]]
		set seconds_work [expr $seconds_in_interval * $percentage / 100.0]

		switch $uom_id {
		    320 { set seconds_uom [expr $planned_units * 3600] }
		    321 { set seconds_uom [expr $planned_units * 3600 * 8.0] }
		    default { set seconds_uom 0.0 }
		}
		set overallocation_factor "undefined"
		catch { set overallocation_factor [expr round(10.0 * $seconds_work / $seconds_uom) / 10.0] }

		if {"undefined" != $overallocation_factor} {
		    db_dml reduce_overallocation "
			update	im_biz_object_members
			set	percentage = coalesce(percentage, 0.0) / :overallocation_factor
			where	rel_id in (
				select	r.rel_id
				from	acs_rels r,
					users u
				where	r.object_id_one = :project_id and
					r.object_id_two = u.user_id
			)
		    "
		}

		im_audit -object_id $project_id
	    }
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

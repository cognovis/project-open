# /packages/intranet-ganttproject/tcl/intranet-taskjuggler-procs.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Integrate ]project-open[ tasks and resource assignations
    with GanttProject and its data structure

    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# TaskJuggler
# ---------------------------------------------------------------------


ad_proc -public im_taskjuggler_task_path { 
    project_id
} {
    Returns a TJ "absolute" path for a task.
    Example: "t1234.t2345.t3456"
} {
    set parent_id [db_string super_project "select parent_id from im_projects where project_id = :project_id" -default ""]
    if {"" != $parent_id} {

        #set super_project_path [util_memoize [list im_taskjuggler_task_path $parent_id]]
        set super_project_path [im_taskjuggler_task_path $parent_id]

	if {"" != $super_project_path} { append super_project_path "." }
	return "${super_project_path}t$project_id"
    } else {
	return ""
    }
}


ad_proc -public im_taskjuggler_write_subtasks { 
    {-depth 0 }
    {-default_start ""}
    project_id
} {
    Returns a TJ specification of the project's tasks
} {
    ns_log Notice "im_taskjuggler_write_subtasks: pid=$project_id, depth=$depth, default_start=$default_start"
    # Get sub-tasks in the right sort_order
    set project_list [db_list sorted_query "
	select
		p.project_id
	from	
		im_projects p,
		acs_objects o
	where
		p.project_id = o.object_id
		and parent_id = :project_id
		--  and p.project_type_id = [im_project_type_task]
                and p.project_status_id not in (
			[im_project_status_deleted], 
			[im_project_status_closed]
		)
	order by sort_order
    "]

    set result ""
    foreach project_id $project_list {
	append result [im_taskjuggler_write_task -depth $depth -default_start $default_start $project_id]
    }

    return $result
}

ad_proc -public im_taskjuggler_write_task { 
    {-depth 0 }
    {-default_start ""}
    project_id
} {
    Write out the information about one specific task and then call
    a recursive routine to write out the stuff below the task.
} {
    ns_log Notice "im_taskjuggler_write_task: pid=$project_id, depth=$depth, default_start=$default_start"

    set org_project_id $project_id
    set indent ""
    for {set i 0} {$i < $depth} {incr i} { append indent "\t" }
    incr depth
    set tj ""

    # Get everything about the project
    if {![db_0or1row project_info "
        select  p.*,
		t.*,
		o.object_type,
                p.start_date::date as start_date,
                p.end_date::date as end_date,
                g.*,
		(select count(*) from im_projects sub_p where sub_p.parent_id = :project_id) as num_subtasks
        from    im_projects p
		LEFT OUTER JOIN im_timesheet_tasks t ON (p.project_id = t.task_id)
		LEFT OUTER JOIN im_gantt_projects g ON (p.project_id = g.project_id),
		acs_objects o
        where   p.project_id = :project_id
		and p.project_id = o.object_id
    "]} {
	ad_return_complaint 1 [lang::message::lookup "" intranet-ganttproject.Project_Not_Found "Didn't find project \#%project_id%"]
	return
    }

    # --------------------------------------------------------------
    # Massage values
    if {"" == $priority} { set priority "1" }
    if {"" == $start_date} { set start_date $default_start }
    if {"" == $start_date} { set start_date [db_string today "select to_char(now(), 'YYYY-MM-DD')"] }

    ns_log Notice "im_taskjuggler_write_task: pid=$project_id, project_name=$project_name, start_date=$start_date"
    append tj "${indent}task t$org_project_id \"$project_name\" {\n"

    # --------------------------------------------------------------
    # Add dependencies to predecessors 
    # 9650 == 'Intranet Timesheet Task Dependency Type'
    set dependency_sql "
	SELECT DISTINCT
		task_id_two
	FROM	im_timesheet_task_dependencies ttd,
		im_projects p
	WHERE	ttd.task_id_two = p.project_id AND
		task_id_one = :task_id AND 
		dependency_type_id=9650 AND 
		task_id_two <> :task_id
    "
    set dependency_ctr 0
    db_foreach dependency $dependency_sql {
	set task_path [im_taskjuggler_task_path $task_id_two]
	append tj "${indent}\tdepends $task_path		# $task_id_two\n"
	incr dependency_ctr
    }

    # Make tasks without dependency start at the start of the project
    if {0 == $dependency_ctr} {

	append tj "${indent}\tstart $default_start\n"

	# Write the start command once for the topmost task
#	if {0 != $num_subtasks} {
#	}
    }



    # --------------------------------------------------------------
    # Write out dependent tasks

    set sub_tasks [im_taskjuggler_write_subtasks -depth $depth -default_start $default_start $org_project_id]
    append tj $sub_tasks


    # Write out effort and assignment information only for leaf tasks
    if {0 == $num_subtasks} {
	
	# --------------------------------------------------------------
	# Planned units
	if {"" != $planned_units} {
	    set effort_tj "effort $planned_units"
	    switch $uom_id {
		321 {
		    # Day
		    append effort_tj "d"
		}
		320 {
		    # Hour
		    append effort_tj "h"
		}
		default {
		    ad_return_complaint 1 "Found invalid UoM for a timesheet task: $uom_id"
		    ad_script_abort
		}
	    }
	    append tj "${indent}\t$effort_tj\n"
	}


	# --------------------------------------------------------------
	# Allocations
	set project_allocations_sql "
	select	
		r.object_id_one AS task_id,
                r.object_id_two AS user_id,
		coalesce(bom.percentage, 100.0) as percentage
	from	acs_rels r,
		im_biz_object_members bom
	where
                r.rel_id = bom.rel_id AND
		r.object_id_one = :org_project_id
        "
	set allocation_ctr 0
	db_foreach project_allocations $project_allocations_sql {
	    incr allocation_ctr
	    set allocation_hours [expr $percentage * 8.0 / 100.0]
	    if {$allocation_hours < 0.1 } { 
		# Ignore allocations below 1%.
		append tj "${indent}\t\# WARNING: Ignoring assignment percentage of $percentage because it is below the TJ resolution\n"
		continue 
	    }
	    if {$allocation_hours < 1.0} {
		# Tj allocation precision is 1h.
		append tj "${indent}\t\# WARNING: Increasing allocation from $allocation_hours to 1.0h, because of TJ resolution\n"
		set allocation_hours 1.0 
	}
	    append tj "${indent}\tallocate r$user_id { limits { dailymax ${allocation_hours}h } }\n"
	}
	if {0 == $allocation_ctr} {
	    append tj "${indent}\tallocate members\n"
	}


	# --------------------------------------------------------------
	# Percent Completed
	# Only add this to leaf tasks
	
	if {"" == [string trim $sub_tasks]} {
	    if {"" != $percent_completed} {
		append tj "${indent}\tcomplete $percent_completed\n"
	    }
	}

    }


    # --------------------------------------------------------------
    # Close the task

    append tj "${indent}}\n"

    return $tj
}


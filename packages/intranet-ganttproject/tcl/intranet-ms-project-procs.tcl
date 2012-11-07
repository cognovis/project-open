# /packages/intranet-ganttproject/tcl/intranet-ganttproject.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Integrate ]project-open[ tasks and resource assignations
    with GanttProject and its data structure

    @author frank.bergmann@project-open.com
    @author malte.sussdorff@cognovis.de
}

# ----------------------------------------------------------------------
#
# ----------------------------------------------------------------------

ad_proc -public im_ms_project_calculate_actualstart {
    -task_id
} {
    Calculate the actual start based on the dependencies.
    ToDo: Check if this procedure actually makes sense
    and is used anywhere.
    I'm not clear who wrote this and for what purpose.
} {

    db_foreach parents {
        select to_char(p.end_date, 'YYYY-MM-DD HH24:MM:SS') as end_date,
               ttd.difference, dependency_type_id
        from   im_projects p,
               im_timesheet_task_dependencies ttd
        WHERE  ttd.task_id_one = :task_id and ttd.task_id_two = p.project_id and
               ttd.task_id_two <> :task_id
    } {
        switch $dependency_type_id {
            9660 {
                set actual_start_date ""
            }
            9662 {
                # Finish to start
                set actual_start_date [db_string actual_start_date "
                                SELECT  p2.end_date::date || 'T' || p2.end_date::time as end_date
                                FROM
                                (SELECT to_date(:end_date, 'YYYY-MM-DD HH24:MM:SS') + interval '$difference seconds' as end_date from dual) p2
                        " -default ""]
            }
            9664 {
                set actual_start_date ""
            }
            9666 {
                # start to start
                set actual_start_date [db_string actual_start_date "
                                SELECT  p2.end_date::date || 'T' || p2.end_date::time as end_date
                                FROM
                                (SELECT to_date(:end_date, 'YYYY-MM-DD HH24:MM:SS') + interval '$difference seconds' as end_date from dual) p2
                        " -default ""]
            }
        }
        ds_comment "$actual_start_date"
    }
}


# ----------------------------------------------------------------------
#
# ----------------------------------------------------------------------

ad_proc -public im_ms_project_write_subtasks { 
    { -default_start_date "" }
    { -default_duration "" }
    project_id
    doc
    tree_node 
    outline_level
    outline_number
    id_name
} {
    Write out all the specific subtasks of a task or project.
    This procedure asumes that the current task has already 
    been written out and now deals with the subtasks.
} {
    # Why is id_name passed by reference?
    upvar 1 $id_name id

    # Get sub-tasks in the right sort_order
    set object_list_list [db_list_of_lists sorted_query "
	select	p.project_id as object_id,
		o.object_type,
		p.sort_order
	from	acs_objects o,
		im_projects p
		LEFT OUTER JOIN im_gantt_projects gp ON (p.project_id = gp.project_id)
	where	p.project_id = o.object_id
		and parent_id = :project_id
		and p.project_status_id not in ([im_project_status_deleted])
	order by 
		coalesce(gp.xml_id::integer, 0),
		p.sort_order
    "]

    incr outline_level
    set outline_sub 0
    foreach object_record $object_list_list {
	incr outline_sub
	set object_id [lindex $object_record 0]

	if {$outline_level==1} {
	    set oln "$outline_sub"
	} else {
	    set oln "$outline_number.$outline_sub"
	}

	incr id

	im_ms_project_write_task  \
		-default_start_date $default_start_date  \
		-default_duration $default_duration  \
		$object_id  \
		$doc \
		$tree_node \
		$outline_level \
		$oln \
		id
    }
}

ad_proc -public im_ms_project_write_task { 
    { -default_start_date "" }
    { -default_duration "" }
    project_id
    doc
    tree_node 
    outline_level
    outline_number
    id_name
} {
    Write out the information about one specific task and then call
    a recursive routine to write out the stuff below the task.
} {
    upvar 1 $id_name id
    set org_project_id $project_id

    if { [security::secure_conn_p] } {
	set base_url "https://[ad_host][ad_port]"
    } else {
	set base_url "http://[ad_host][ad_port]"
    }
    set task_view_url "$base_url/intranet-timesheet2-tasks/new?task_id="
    set project_view_url "$base_url/intranet/projects/view?project_id="

    # ------------ Get everything about the project -------------
    if {![db_0or1row project_info "
	select  p.*,
		t.*,
		o.object_type,
		p.start_date::date || 'T' || p.start_date::time as start_date,
		p.end_date::date || 'T' || p.end_date::time as end_date,
		t.scheduling_constraint_date::date || 'T' || t.scheduling_constraint_date::time as scheduling_constraint_date,
		(p.end_date::date 
			- p.start_date::date 
			- 2*(next_day(p.end_date::date-1,'FRI') 
			- next_day(p.start_date::date-1,'FRI'))/7
			+ round((extract(hour from p.end_date) - extract(hour from p.start_date)) / 8.0)
		) * 8 AS duration_hours,
		c.company_name,
		g.*
	from    im_projects p
		LEFT OUTER JOIN im_timesheet_tasks t ON (p.project_id = t.task_id)
		LEFT OUTER JOIN im_gantt_projects g ON (p.project_id = g.project_id),
		acs_objects o,
		im_companies c
	where   p.project_id = :project_id
		and p.project_id = o.object_id
		and p.company_id = c.company_id
    "]} {
	ad_return_complaint 1 [lang::message::lookup "" intranet-ganttproject.Project_Not_Found "Didn't find project \#%project_id%"]
	return
    }

    # Make sure some important variables are set to default values
    # because empty values are not accepted by Microsoft Project:
    #
    if {"" == $percent_completed} { set percent_completed "0" }
    if {"" == $priority} { set priority "1" }
    if {"" == $start_date} { set start_date $default_start_date }
    if {"" == $start_date} { set start_date [db_string today "select to_char(now(), 'YYYY-MM-DD')"] }
    if {"" == $duration_hours} { 
	set duration_hours $default_duration
    }
    if {"" == $duration_hours || [string equal $start_date $end_date] || $duration_hours < 0} { 
	set duration_hours 0 
    }

    # Ignore the duration if it is not a task (a project).
    # Projects don't have duration and planned_units in ]po[.
    if {$project_type_id != [im_project_type_task]} {
	set duration_hours 0
	set planned_units 0
    }

    # Set completed=100% if the task has been closed
    if {[im_category_is_a $project_status_id [im_project_status_closed]]} {
	set percent_completed 100.0
    }

    set task_node [$doc createElement Task]
    $tree_node appendChild $task_node

    # minimal set of elements in case this hasn't been imported before
    if {[llength $xml_elements] == 0} {
	set xml_elements {
		UID ID 
		Name Type
		EffortDriven
		OutlineNumber OutlineLevel Priority 
		Start Finish
	        ManualStart
	        ManualFinish
	        IsNull
		Milestone
		Work RemainingWork
		Duration
	        ManualDuration
		RemainingDuration
		DurationFormat
		CalendarUID 
		PercentComplete
		FixedCostAccrual
	        ConstraintType
	        ConstraintDate
	        ActualStart
	}
    }
    
    # Add the following elements to the xml_elements always
    foreach xml_element [list "PredecessorLink" "ActualStart" "ManualStart" "ManualFinish" "ManualDuration"] {
	if {[lsearch $xml_elements $xml_element] < 0} {
	    lappend xml_elements $xml_element
	}
    }

    set predecessors_done 0
    foreach element $xml_elements { 
	set xml_attribute_name [plsql_utility::generate_oracle_name "xml_$element"]
	switch $element {
	    Name			{ 
		set value $project_name
		# Replace TAB characters with spaces
		regsub -all "\t" $value " " value
	    				}
	    Type			{ 
                if {![info exists effort_driven_type_id] || "" == $effort_driven_type_id} {set effort_driven_type_id 9720}
		set value [util_memoize [list db_string type "select aux_int1 from im_categories where category_id = $effort_driven_type_id" -default ""]]
		if {"" == $value} { 
		    ad_return_complaint 1 "im_ms_project_write_task: Unknown fixed task type '$effort_driven_type_id'" 
		}
	    }
	    IsNull			{ set value 0 }
	    OutlineNumber		{ set value $outline_number }
	    OutlineLevel		{ set value $outline_level }
	    Priority			{ set value 500 }
	    ActualStart         { 
		# We need to add the ActualStart to a milestone otherwise
		# The Percent Complete will not be transferred.
		if {[info exists xml_actualstart]} {
		    set value $xml_actualstart
		}
		if {$value ne "" && "t" == $milestone_p} {
		    $task_node appendXML "
				<ActualStart>$value</ActualStart>
			    "
		}
		continue
	    }
	    Start - ManualStart		{ set value $start_date }
	    Finish - ManualFinish	{ set value $end_date }
	    Duration - ManualDuration {
		# Check if we've got a duration defined in the xml_elements.
		# Otherwise (export without import...) generate a duration.
		set seconds [expr $duration_hours * 3600.0]
		set value [im_gp_seconds_to_ms_project_time $seconds]
	    }
	    ManualDuration {
		# Check if we've got a duration defined in the xml_elements.
		# Otherwise (export without import...) generate a duration.
		set seconds [expr $duration_hours * 3600.0]
		set value [im_gp_seconds_to_ms_project_time $seconds]
	    }
	    
	    DurationFormat		{ set value 7 }
	    EffortDriven		{ if {"t" == $effort_driven_p} { set value 1 } else { set value 0 } }
	    RemainingDuration {
		set remaining_duration_hours [expr round($duration_hours * (100.0 - $percent_completed) / 100.0)]
		set seconds [expr $remaining_duration_hours * 3600.0]
		set value [im_gp_seconds_to_ms_project_time $seconds]
	    }
	    Milestone			{ if {"t" == $milestone_p} { set value 1 } else { set value 0 } }
	    Notes			{ set value $note }
	    PercentComplete		{ set value $percent_completed }
	    ConstraintDate		{ set value $scheduling_constraint_date }
	    ConstraintType	{
		# Category "Intranet Timesheet Task Scheduling Type" has MS-Project Values in aux_int1.
		set value ""
		if {"" != $scheduling_constraint_id} {
		    set value [util_memoize [list db_string contype "select aux_int1 from im_categories where category_id = $scheduling_constraint_id" -default ""]]
		}
		if {"" == $value} {
		    # This should not occur. 
		    # Maybe this project has been created before scheduling_constraing_id was defined.
		    # Fall back to the xml_constrainttype field in im_gantt_projects
		    if {[info exists $xml_attribute_name]} {
			set value [expr $$xml_attribute_name]
		    } else {
			set value 0
		    }
		}
	    }
	    PredecessorLink	{ 
		if {$predecessors_done} { continue }
		set predecessors_done 1
		
		# Add dependencies to predecessors 
		set dependency_sql "
				SELECT DISTINCT
					gp.xml_uid as xml_uid_ms_project,
					gp.project_id as xml_uid,
					coalesce(c.aux_int1,1) as type_id,
                                        coalesce(ttd.difference,0) as difference
				FROM	im_categories c,
					im_timesheet_task_dependencies ttd
					LEFT OUTER JOIN im_gantt_projects gp ON (ttd.task_id_two = gp.project_id)
				WHERE	ttd.task_id_one = :task_id and
                                        ttd.dependency_type_id = c.category_id and
					ttd.task_id_two <> :task_id
			"
		
		db_foreach dependency $dependency_sql {
		    $task_node appendXML "
				<PredecessorLink>
					<PredecessorUID>$xml_uid</PredecessorUID>
					<Type>$type_id</Type>
					<CrossProject>0</CrossProject>
					<LinkLag>$difference</LinkLag>
					<LagFormat>7</LagFormat>
				</PredecessorLink>
			    "
		}
		continue
	    }
	    UID				{ set value $org_project_id }
	    Work			{ 
		if { ![info exists planned_units] || "" == $planned_units || "" == [string trim $planned_units] } { 
		    set planned_units 0 
		    set value ""
		} else {
		    set seconds [expr $planned_units * 3600.0]
		    set value [im_gp_seconds_to_ms_project_time $seconds]
		}
	    }
	    ACWP - \
		ActualCost - \
		ActualDuration - \
		ActualOvertimeCost - \
		ActualOvertimeWork - \
		ActualWork - \
		BCWP - \
		BCWS - \
		CV - \
		CommitmentType - \
		Cost - \
		CreateDate - \
		Critical - \
		CustomProperty - \
		Depend - \
		EarlyFinish - \
		EarlyStart - \
		EarnedValueMethod - \
		Estimated - \
		ExtendedAttribute - \
		ExternalTask - \
		FinishVariance - \
		FixedCost - \
		FreeSlack - \
		HideBar - \
		IgnoreResourceCalendar - \
		IsPublished - \
		IsSubproject - \
		IsSubprojectReadOnly - \
		LateFinish - \
		LateStart - \
		LevelAssignments - \
		LevelingCanSplit - \
		LevelingDelay - \
		LevelingDelayFormat - \
		OverAllocated - \
		OvertimeCost - \
		OvertimeWork - \
		PercentWorkComplete - \
		PhysicalPercentComplete - \
		Recurring - \
		RegularWork - \
		RemainingCost - \
		RemainingOvertimeCost - \
		RemainingOvertimeWork - \
		RemainingWork - \
		ResumeValid - \
		Rollup - \
		StartVariance - \
		Summary - \
		Task - \
		TotalSlack - \
		WorkVariance - \
		Xxxx {
		    # Skip these ones
		    continue 
		}
		default {
			if {[info exists $xml_attribute_name]} {
			    set value [expr $$xml_attribute_name]
			} else {
			    set value 0
			}
		}
	}

	# Setup reasonable values for tasks not imported from MS-Project
	if {"" == $value} {
	    ns_log Notice "im_ms_project_write_task: Error: Undefined value for '$element'"
	    switch $element {
		UID					{ set value $org_project_id }
		ID					{ set value $org_project_id }
		Duration - RemainingDuration - Work - RemainingWork	{ set value "PT24H0M0S" }
		PercentComplete - PercentWorkComplete	{ set value $percent_completed }
		FixedCostAccrual			{ set value 3 }
	    }
	}

	# Special logic for elements
	switch $element {
	    FixedCostAccrual {
		# I'm not sure what this field is good for, 
		# but any value except for 3 gives an error...
		set value 3
	    }
	}

	ns_log Notice "im_ms_project_write_task: Adding element='$element' with value='$value'"
	$task_node appendFromList [list $element {} [list [list \#text $value]]]
    }

    im_ms_project_write_subtasks \
	-default_start_date $start_date \
	-default_duration $duration_hours \
	$project_id \
	$doc \
	$tree_node \
	$outline_level \
	$outline_number \
	id
}



ad_proc -public im_ms_project_seconds_in_timephased {
    -task_id:required
} {
    Calculate the seconds in the timephased data of a task.
    Returns "" if there are no timephased data for this task.
} {
    set sql "
	select	gat.*,
		bom.percentage
	from	acs_rels r,
		im_biz_object_members bom,
		im_gantt_assignment_timephases gat
	where	r.object_id_one = :task_id and
		r.rel_id = bom.rel_id and
		r.rel_id = gat.rel_id
    "
    set seconds ""
    db_foreach timephased_data $sql {

        # Fraber 20120914: Overwritten assignments have NULL percentage.
	# ToDo: Fix the update of timephased data to remove TP for old assignments
        if {"" == $percentage} { continue }

	if {"" != $timephase_value} {
	    set value_seconds [im_gp_ms_project_time_to_seconds $timephase_value]
	    if {[string is integer $value_seconds]} { 
		if {"" == $seconds} { set seconds 0.0 }
		set seconds [expr $seconds + $value_seconds]
	    }
	}
    }
    return $seconds
}

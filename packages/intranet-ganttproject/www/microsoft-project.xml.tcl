# /packages/intranet-ganttproject/www/microsoft-project.xml.tcl
#
# Copyright (C) 2003 - 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Create a Microsoft Project XML structure for a single project
    @author frank.bergmann@project-open.com
} {
    project_id:integer 
    {format "xml"}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set today [db_string today "select to_char(now(), 'YYYY-MM-DD')"]
set user_id [ad_maybe_redirect_for_registration]
set main_project_id $project_id


set default_hourly_cost [ad_parameter -package_id [im_package_cost_id] "DefaultTimesheetHourlyCost" "" 30]

# ---------------------------------------------------------------
# Get information about the project
# ---------------------------------------------------------------

if {![db_0or1row project_info "
	select	g.*,
		p.*,
		p.start_date::date || 'T' || p.start_date::time as project_start_date,
		p.end_date::date || 'T' || p.end_date::time as project_end_date,
		p.end_date::date - p.start_date::date as project_duration,
		c.company_name,
		im_name_from_user_id(p.project_lead_id) as project_lead_name
	from	im_projects p left join im_gantt_projects g on (g.project_id=p.project_id),
		im_companies c
	where	p.project_id = :project_id
		and p.company_id = c.company_id
"]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-ganttproject.Project_Not_Found "Didn't find project \#%project_id%"]
    return
}

# Filename for the download file
set project_filename [string tolower [string trim "$project_name $project_path"]]
regsub {[^[:alnum:]]} $project_filename "_" project_filename
regsub {[[:space:]]+} $project_filename "_" project_filename
regsub {_+} $project_filename "_" project_filename


# ---------------------------------------------------------------
# Check if all sub-projects and tasks have a im_gantt_project entry.
# Update the "xml_id" field of gp to have a consecutive number.
# ---------------------------------------------------------------

set sub_project_without_gp_sql "
	select	child.project_id,
		gp.project_id as gantt_project_id
	from	im_projects p, 
		im_projects child 
		LEFT OUTER JOIN im_gantt_projects gp ON (child.project_id = gp.project_id)
	where	p.project_id = :main_project_id and 
		child.tree_sortkey between p.tree_sortkey and tree_right(p.tree_sortkey) and
		child.project_id != :main_project_id
	order by
		child.tree_sortkey
"
# ToDo: Sort this list using a multirow sort according to sorting parameter
set xml_id_cnt 1
db_foreach sub_project_without_gp $sub_project_without_gp_sql {
    if {"" == $gantt_project_id} {
  	db_dml insert_gp "insert into im_gantt_projects (project_id, xml_elements) VALUES (:project_id, '')"
    }
    db_dml sub_project_update "
	update im_gantt_projects
	set xml_id = :xml_id_cnt
	where project_id = :project_id
    "
    incr xml_id_cnt
}


# ---------------------------------------------------------------
# Calculate a consecutive sequence for "xml_id"
# MS-Project needs a "ID" field for all tasks starting with 1.
# ---------------------------------------------------------------




# ---------------------------------------------------------------
# Project node

set doc [dom createDocument Project]
set project_node [$doc documentElement]

$project_node setAttribute xmlns "http://schemas.microsoft.com/project"

# minimal set of elements in case this hasn't been imported before
if {![info exists xml_elements] || [llength $xml_elements] == 0} {
    set xml_elements {Name Title Manager ScheduleFromStart StartDate FinishDate}
}

foreach element $xml_elements { 
    set append_p 1
    switch $element {
	"Name" - "Title"	{ set value "${project_name}.xml" }
	"Manager"		{ set value $project_lead_name }
	"ScheduleFromStart"	{ set value 1 }
	"StartDate"		{ set value $project_start_date }
	"FinishDate"		{ set value $project_end_date }
	"CalendarUID"		{ set value 1 }
        DefaultStartTime - DefaultFinishTime {
	    # Determines the default start- and end time of tasks.
	    # A mismatch could lead to working hours being cut.
	    if {[catch {
		    set attribute_name [plsql_utility::generate_oracle_name "xml_$element"]
		    set value [expr $$attribute_name]
	    } err_msg]} {
		    set append_p 0
	    }
	}
	Assignments - \
	Calendars - \
	Resources - \
	Tasks - \
        ActualsInSync - \
        AdminProject - \
        AutoAddNewResourcesAndTasks - \
        Autolink - \
        BaselineForEarnedValue - \
        CreationDate - \
        CriticalSlackLimit - \
        CurrencyCode - \
        CurrencyDigits - \
        CurrencySymbol - \
        CurrencySymbolPosition - \
        CurrentDate - \
        DaysPerMonth - \
        DefaultFixedCostAccrual - \
        DefaultOvertimeRate - \
        DefaultStandardRate - \
        DefaultTaskEVMethod - \
        DefaultTaskType - \
        DurationFormat - \
        EditableActualCosts - \
        ExtendedAttributes/ - \
        ExtendedCreationDate - \
        FYStartDate - \
        FinishDate - \
        FiscalYearStart - \
        HonorConstraints - \
        InsertedProjectsLikeSummary - \
        LastSaved - \
        MicrosoftProjectServerURL - \
        MinutesPerDay - \
        MinutesPerWeek - \
        MoveCompletedEndsBack - \
        MoveCompletedEndsForward - \
        MoveRemainingStartsBack - \
        MoveRemainingStartsForward - \
        MultipleCriticalPaths - \
        NewTaskStartDate - \
        NewTasksEffortDriven - \
        NewTasksEstimated - \
        OutlineCodes/ - \
        ProjectExternallyEdited - \
        RemoveFileProperties - \
        ScheduleFromStart - \
        SplitsInProgressTasks - \
        SpreadActualCost - \
        SpreadPercentComplete - \
        StartDate - \
        TaskUpdatesResource - \
        WBSMasks/ - \
        WeekStartDay - \
        WorkFormat - \
	Xxx {
	    # Don't write out these fields by default
	    set append_p 0
	}
	default {
	    set attribute_name [plsql_utility::generate_oracle_name "xml_$element"]
	    set value [expr $$attribute_name]
	}
    }

    # the following does "<$element>$value</$element>"
    if {$append_p} {
        $project_node appendFromList [list $element {} [list [list \#text $value]]]
    }
}


# ---------------------------------------------------------------
# Calendards

set calendars_node [$doc createElement Calendars]
$project_node appendChild $calendars_node

set start_morning "09:00:00"
set end_morning "13:00:00"
set start_after "15:00:00"
set end_after "19:00:00"

$calendars_node appendXML "
	<Calendar>
		<UID>1</UID>
		<Name>Standard</Name>
		<IsBaseCalendar>true</IsBaseCalendar>
		<WeekDays>
			<WeekDay>
				<DayType>1</DayType>
				<DayWorking>0</DayWorking>
			</WeekDay>
			<WeekDay>
				<DayType>7</DayType>
				<DayWorking>0</DayWorking>
			</WeekDay>
		</WeekDays>
	</Calendar>
"


# ---------------------------------------------------------------
# Get the information about all resources who participate in
# project or any of its sub-projects

set project_resources_sql "
	select distinct
		gp.*,
		p.*,
		e.*,
		pa.email,
		uc.home_phone,
		uc.work_phone,
		uc.cell_phone,
		uc.user_id AS user_id,
		im_name_from_user_id(p.person_id) as user_name
	from 	
		parties pa,
		persons p
		LEFT OUTER JOIN users_contact uc ON (p.person_id = uc.user_id)
		LEFT OUTER JOIN im_employees e ON (p.person_id = e.employee_id)
		LEFT OUTER JOIN im_gantt_persons gp ON (p.person_id = gp.person_id),
		acs_rels r,
		im_biz_object_members bom
	where
		r.rel_id = bom.rel_id
		and r.object_id_two = uc.user_id
		and uc.user_id = p.person_id
		and uc.user_id = pa.party_id
		and r.object_id_one in (
			select	children.project_id as subproject_id
			from	im_projects parent,
				im_projects children
			where	children.project_status_id not in (
					[im_project_status_deleted],
					[im_project_status_canceled]
				)
				and children.tree_sortkey between
					parent.tree_sortkey and
					tree_right(parent.tree_sortkey)
				and parent.project_id = :main_project_id
		UNION
			select  :main_project_id
		)
"

set ttt {
# Loop through all resources and add them to the XML structure
db_foreach project_resources $project_resources_sql {
    set calendar_node [$doc createElement Calendar]
    $calendars_node appendChild $calendar_node

    $calendar_node appendFromList [list UID {} [list [list \#text $user_id]]]
    $calendar_node appendFromList [list Name {} [list [list \#text $user_name]]]

    $calendar_node appendXML "<IsBaseCalendar>false</IsBaseCalendar>"
    $calendar_node appendXML "<BaseCalendarUID>1</BaseCalendarUID>"

    set weekdays_node [$doc createElement WeekDays]
    $calendar_node appendChild $weekdays_node

set ttt {

    # Append entries for user absences
    set user_absences_sql "
	select	start_date::date || 'T00:00:00' as start_date,
		end_date::date || 'T23:59:00' as end_date 
	from	im_user_absences
	where	owner_id = :user_id
	order by start_date
    "
    db_foreach resource_absences $user_absences_sql {
	$weekdays_node appendXML "
		<WeekDay>
			<DayType>0</DayType>
			<DayWorking>0</DayWorking>
			<TimePeriod>
				<FromDate>$start_date</FromDate>
				<ToDate>$end_date</ToDate>
			</TimePeriod>
		</WeekDay>
	"
    }

}
}
}
 
# ---------------------------------------------------------------
# Tasks

set tasks_node [$doc createElement Tasks]
$project_node appendChild $tasks_node

set id 0
im_ms_project_write_subtasks \
    -default_start_date $project_start_date \
   -default_duration $project_duration \
    $main_project_id \
    $doc \
    $tasks_node \
    "0" "1" id


# ---------------------------------------------------------------
# Resources
#    <resources>
#	<resource id="0" name="Frank Bergmann" function="Default:1" contacts="" phone="" />
#	<resource id="1" name="Klaus Hofeditz" function="Default:0" contacts="" phone="" />
#    </resources>

set resources_node [$doc createElement Resources]
$project_node appendChild $resources_node

set id 0
set xml_elements {}
set temp temp

db_foreach project_resources $project_resources_sql {
    incr id

    # First letter of first and last name    
    set initials [string range $first_names 0 1][string range $last_name 0 1]

    if {"" == $hourly_cost || 0 == $hourly_cost} {
	set hourly_cost $default_hourly_cost
    }

    set resource_node [$doc createElement Resource]
    $resources_node appendChild $resource_node
    
    # minimal set of elements in case this hasn't been imported before
    if {[llength $xml_elements]==0} {
	set xml_elements {
		UID ID 
		Name 
		Initials
		EmailAddress 
		Type
		Cost 
		AccrueAt 
		StandardRate 
		OvertimeRate 
		CostPerUse 
		CalendarUID
	}
    }
    
    foreach element $xml_elements { 
	switch $element {
		UID			{ set value $user_id }
		ID			{ set value $id }
		Type			{ set value 1 }
		Name			{ set value $user_name }
		EmailAddress		{ set value $email } 
		AccrueAt		{ set value 3 }
		StandardRate		{ set value $hourly_cost }
		Cost - OvertimeRate - CostPerUse { set value 0 }
		CalendarUID		{ set value $user_id }
		Initials		{ set value $initials }
		MaxUnits - OverAllocated - CanLevel - PeakUnits { continue }
		default {
		    set attribute_name [plsql_utility::generate_oracle_name "xml_$element"]
		    if {[info exists $attribute_name ] } {
			set value [expr $$attribute_name]
		    } else {
			set value 0
		    }
		}
	}
	
	$resource_node appendFromList [list $element {} [list [list \#text $value]]]
    }
}


# ---------------------------------------------------------------
# Assignments

set allocations_node [$doc createElement Assignments]
$project_node appendChild $allocations_node

set project_allocations_sql "
	select	
		p.project_id as task_id,
		gp.xml_uid::integer as xml_uid,
		object_id_one AS task_id,
		object_id_two AS user_id,
		bom.percentage as percentage_assigned,
		p.percent_completed,
		to_char(p.start_date, 'YYYY-MM-DD') as start_date_date,
		to_char(p.end_date, 'YYYY-MM-DD') as end_date_date,
		tt.planned_units,
		(select	sum(coalesce(pbom.percentage,0))
		 from	im_biz_object_members pbom,
			acs_rels pr
		 where	pr.rel_id = pbom.rel_id and
			pr.object_id_one = tt.task_id
		) as total_percentage_assigned
	from
		acs_rels r,
		im_projects p
		LEFT OUTER JOIN im_timesheet_tasks tt ON (p.project_id = tt.task_id)
		LEFT OUTER JOIN im_gantt_projects gp ON (tt.task_id = gp.project_id),
		im_biz_object_members bom
	where
		r.rel_id = bom.rel_id AND
		r.object_id_one = tt.task_id AND
		r.object_id_one in (
			select	task_id
			from	im_timesheet_tasks_view
			where	project_id in (
				select	children.project_id as subproject_id
				from	im_projects parent,
					im_projects children
				where	children.project_status_id not in (
						[im_project_status_deleted],
						[im_project_status_canceled]
					)
					and children.tree_sortkey between
						parent.tree_sortkey and
						tree_right(parent.tree_sortkey)
					and parent.project_id = :main_project_id
			UNION
				select  :main_project_id
			)
		)
"
set assignment_ctr 0
db_foreach project_allocations $project_allocations_sql {

    ns_log Notice "microsoft-project: allocactions: xml_uid=$xml_uid"
    if {"" == $percentage_assigned} {
	# Don't export empty assignments.
	# These assignments are created by assignments of
	# resources to sub-tasks in ]po[
	continue
    }

    # Calculate the work included in this assignments.
    # The sum of assigned work overrides the task work in MS-Project,
    # so we divide the task work evenly across the assigned resources.
    if { ![info exists planned_units] || "" == $planned_units || "" == [string trim $planned_units] } { set planned_units 0 }
    set planned_seconds [expr $planned_units * 3600]
    set work_seconds [expr $planned_seconds * $percentage_assigned / $total_percentage_assigned]
    set work_ms [im_gp_seconds_to_ms_project_time $work_seconds]

    ns_log Notice "microsoft-project: allocactions: uid=$assignment_ctr, task_id=$task_id, tot=$total_percentage_assigned, assig=$percentage_assigned"


    $allocations_node appendXML "
	<Assignment>
		<UID>$assignment_ctr</UID>
		<TaskUID>$task_id</TaskUID>
		<ResourceUID>$user_id</ResourceUID>
		<Units>[expr $percentage_assigned / 100.0]</Units>
		<PercentWorkComplete>$percent_completed</PercentWorkComplete>
		<Start>${start_date_date}T00:00:00</Start>
		<Finish>${end_date_date}T23:00:00</Finish>
		<OvertimeWork>PT0H0M0S</OvertimeWork>
		<RegularWork>$work_ms</RegularWork>
		<RemainingWork>$work_ms</RemainingWork>
		<Work>$work_ms</Work>
	</Assignment>
    "
    incr assignment_ctr
}



set xml_org [$doc asXML -indent 8 -escapeNonASCII]
set xml ""
# <OutlineCodes></OutlineCodes>
foreach line [split $xml_org "\n"] {

    if {[regexp {^([\ \t]*)\<([a-zA-Z0-9]+)\>\<\/([a-zA-Z0-9]+)\>} $line match blank tag1 tag2]} {
	if {[string equal $tag1 $tag2]} {
	    append xml "$blank<$tag1/>\n"     
	} else {
	    append xml "$line\n"
	}
    } else {
	append xml "$line\n"
    }
}


if {"html" == $format} {
    ad_return_complaint 1 "<pre>[ns_quotehtml $xml]</pre>"
} else {
    set outputheaders [ns_conn outputheaders]
    ns_set cput $outputheaders "Content-Disposition" "attachment; filename=${project_filename}.xml"
    ns_return 200 application/octet-stream "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n$xml"
}


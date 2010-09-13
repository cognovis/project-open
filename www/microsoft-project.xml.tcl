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


# ---------------------------------------------------------------
# Create the XML
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
    switch $element {
	"Name" - "Title"	{ set value "${project_name}.xml" }
	"Manager"		{ set value $project_lead_name }
	"ScheduleFromStart"	{ set value 1 }
	"StartDate"		{ set value $project_start_date }
	"FinishDate"		{ set value $project_end_date }
	"CalendarUID"		{ set value 1 }
	"Calendars" - "Tasks" - "Resources" - "Assignments"	{ continue }
	default {
	    set attribute_name [plsql_utility::generate_oracle_name "xml_$element"]
	    set value [expr $$attribute_name]
	}
    }

    # the following does "<$element>$value</$element>"
    $project_node appendFromList [list $element {} [list [list \#text $value]]]
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
		<IsBaseCalendar>1</IsBaseCalendar>
		<BaseCalendarUID>-1</BaseCalendarUID>
		<WeekDays>
		<WeekDay>
			<DayType>1</DayType>
			<DayWorking>0</DayWorking>
		</WeekDay>
		<WeekDay>
			<DayType>2</DayType>
			<DayWorking>1</DayWorking>
			<WorkingTimes>
			<WorkingTime>
				<FromTime>$start_morning</FromTime>
				<ToTime>$end_morning</ToTime>
			</WorkingTime>
			<WorkingTime>
				<FromTime>$start_after</FromTime>
				<ToTime>$end_after</ToTime>
			</WorkingTime>
			</WorkingTimes>
		</WeekDay>
		<WeekDay>
			<DayType>3</DayType>
			<DayWorking>1</DayWorking>
			<WorkingTimes>
			<WorkingTime>
				<FromTime>$start_morning</FromTime>
				<ToTime>$end_morning</ToTime>
			</WorkingTime>
			<WorkingTime>
				<FromTime>$start_after</FromTime>
				<ToTime>$end_after</ToTime>
			</WorkingTime>
			</WorkingTimes>
		</WeekDay>
		<WeekDay>
			<DayType>4</DayType>
			<DayWorking>1</DayWorking>
			<WorkingTimes>
			<WorkingTime>
				<FromTime>$start_morning</FromTime>
				<ToTime>$end_morning</ToTime>
			</WorkingTime>
			<WorkingTime>
				<FromTime>$start_after</FromTime>
				<ToTime>$end_after</ToTime>
			</WorkingTime>
			</WorkingTimes>
		</WeekDay>
		<WeekDay>
			<DayType>5</DayType>
			<DayWorking>1</DayWorking>
			<WorkingTimes>
			<WorkingTime>
				<FromTime>$start_morning</FromTime>
				<ToTime>$end_morning</ToTime>
			</WorkingTime>
			<WorkingTime>
				<FromTime>$start_after</FromTime>
				<ToTime>$end_after</ToTime>
			</WorkingTime>
			</WorkingTimes>
		</WeekDay>
		<WeekDay>
			<DayType>6</DayType>
			<DayWorking>1</DayWorking>
			<WorkingTimes>
			<WorkingTime>
				<FromTime>$start_morning</FromTime>
				<ToTime>$end_morning</ToTime>
			</WorkingTime>
			<WorkingTime>
				<FromTime>$start_after</FromTime>
				<ToTime>$end_after</ToTime>
			</WorkingTime>
			</WorkingTimes>
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
		pa.email,
		uc.home_phone,
		uc.work_phone,
		uc.cell_phone,
		uc.user_id AS user_id,
		im_name_from_user_id(p.person_id) as user_name
	from 	users_contact uc,
		acs_rels r,
		im_biz_object_members bom,
		persons p
		left join im_gantt_persons gp ON (p.person_id = gp.person_id),
		parties pa
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
				and parent.project_id = :project_id
		UNION
			select  :project_id
		)
"

# Loop through all resources and add them to the XML structure
db_foreach project_resources $project_resources_sql {
    set calendar_node [$doc createElement Calendar]
    $calendars_node appendChild $calendar_node

    $calendar_node appendFromList [list UID {} [list [list \#text $user_id]]]
    $calendar_node appendFromList [list Name {} [list [list \#text $user_name]]]

    $calendar_node appendXML "<IsBaseCalendar>0</IsBaseCalendar>"
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
 
# ---------------------------------------------------------------
# Tasks

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
	select
		p.project_id as object_id,
		o.object_type,
		p.sort_order
	from	
		im_projects p,
		acs_objects o
	where
		p.project_id = o.object_id
		and parent_id = :project_id
		and p.project_type_id = [im_project_type_task]
		and p.project_status_id not in (
			[im_project_status_deleted], 
			[im_project_status_closed]
		)
	order by sort_order
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
		(p.end_date::date 
			- p.start_date::date 
			- 2*(next_day(p.end_date::date-1,'FRI') 
			- next_day(p.start_date::date-1,'FRI'))/7
			+ round((extract(hour from p.end_date) - extract(hour from p.start_date)) / 8.0)
		) * 8 AS duration_hours,
		c.company_name,
		g.*
	from    im_projects p
		LEFT OUTER JOIN im_timesheet_tasks t on (p.project_id = t.task_id)
		left join im_gantt_projects g on (p.project_id = g.project_id),
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
    if {"" == $duration_hours || [string equal $start_date $end_date] } { 
	set duration_hours 0 
    }

    set task_node [$doc createElement Task]
    $tree_node appendChild $task_node

    # minimal set of elements in case this hasn't been imported before
    if {[llength $xml_elements]==0} {
	set xml_elements {UID ID Name Type OutlineNumber OutlineLevel Priority 
		Start Finish Duration RemainingDuration CalendarUID PredecessorLink}
    }

    set predecessors_done 0

#		"UID"			{ set value $project_id }
#		"ID"			{ set value $id }


    foreach element $xml_elements { 
	switch $element {
		"Name"			{ set value $project_name }
		"Type"			{   if {[info exists xml_type] && $xml_type!=""} {
						set value $xml_type
					    } else {
						set value 0 
					    }
					}
		"OutlineNumber"		{ set value $outline_number }
		"OutlineLevel"		{ set value $outline_level }
		"Priority"		{ set value 500 }
		"Start"			{ set value $start_date }
		"Finish"		{ set value $end_date }
		"Duration" {
			# Check if we've got a duration defined in the xml_elements.
			# Otherwise (export without import...) generate a duration.
			set value "PT$duration_hours\H0M0S" 
                        set attribute_name [plsql_utility::generate_oracle_name "xml_$element"]
                        if {[info exists $attribute_name ] } { set value [expr $$attribute_name] }
		}
		"RemainingDuration" {
			# Check if we've got a duration defined in the xml_elements.
			# Otherwise (export without import...) generate a duration.
			set value "PT$duration_hours\H0M0S" 
                        set attribute_name [plsql_utility::generate_oracle_name "xml_$element"]
                        if {[info exists $attribute_name ] } { set value [expr $$attribute_name] }
		}
		"CalendarUID"		{ set value -1 }
		"Notes"			{ set value $note }
		"PredecessorLink"	{ 
			if {$predecessors_done} { continue }
			set predecessors_done 1

			# Add dependencies to predecessors 
			set dependency_sql "
				SELECT DISTINCT
					gp.xml_uid
				FROM	im_timesheet_task_dependencies ttd
					LEFT OUTER JOIN im_gantt_projects gp ON (ttd.task_id_two = gp.project_id)
				WHERE	ttd.task_id_one = :task_id and
					ttd.dependency_type_id = [im_timesheet_task_dependency_type_depends] and
					ttd.task_id_two <> :task_id
			"

			db_foreach dependency $dependency_sql {
			    $task_node appendXML "
				<PredecessorLink>
					<PredecessorUID>$xml_uid</PredecessorUID>
					<Type>1</Type>
					<CrossProject>0</CrossProject>
					<LinkLag>0</LinkLag>
					<LagFormat>7</LagFormat>
				</PredecessorLink>
			    "
			}
			continue
		}
		"customproperty" - "task" - "depend" - "ExtendedAttribute" { continue }
		default {
			set attribute_name [plsql_utility::generate_oracle_name "xml_$element"]
			if {[info exists $attribute_name ] } {
				set value [expr $$attribute_name]
			} else {
				set value 0
			}
		}
	}
	
	$task_node appendFromList [list $element {} [list [list \#text $value]]]
    }

    # Disabled storing the ]po[ task IDs.
    # Instead, we can use the UID of MS-Project, which survives updates of the project
    set ttt {    
	    $task_node appendXML "
			<ExtendedAttribute>
			<UID>$project_id</UID>
			<FieldID>188744006</FieldID>
			<Value>$project_nr</Value>
			</ExtendedAttribute>
		"
	    $task_node appendXML "
			<ExtendedAttribute>
			<UID>$project_id</UID>
			<FieldID>188744007</FieldID>
			<Value>$project_id</Value>
			</ExtendedAttribute>
		"
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



set tasks_node [$doc createElement Tasks]
$project_node appendChild $tasks_node


# Add a dummy node #0 for the project iself.
$tasks_node appendXML "
		<Task>
			<UID>0</UID>
			<ID>0</ID>
			<Type>1</Type>
			<IsNull>0</IsNull>
			<CreateDate>2010-08-30T12:32:00</CreateDate>
			<WBS>0</WBS>
			<OutlineNumber>0</OutlineNumber>
			<OutlineLevel>0</OutlineLevel>
			<Priority>500</Priority>
			<Start>2010-09-02T09:00:00</Start>
			<Finish>2010-12-28T09:47:00</Finish>
			<Duration>PT664H47M0S</Duration>
			<DurationFormat>53</DurationFormat>
			<Work>PT994H24M0S</Work>
			<ResumeValid>0</ResumeValid>
			<EffortDriven>0</EffortDriven>
			<Recurring>0</Recurring>
			<OverAllocated>0</OverAllocated>
			<Estimated>1</Estimated>
			<Milestone>0</Milestone>
			<Summary>1</Summary>
			<Critical>1</Critical>
			<IsSubproject>0</IsSubproject>
			<IsSubprojectReadOnly>0</IsSubprojectReadOnly>
			<ExternalTask>0</ExternalTask>
			<EarlyStart>2010-09-02T09:00:00</EarlyStart>
			<EarlyFinish>2010-12-28T09:47:00</EarlyFinish>
			<LateStart>2010-09-02T09:00:00</LateStart>
			<LateFinish>2010-12-28T09:47:00</LateFinish>
			<StartVariance>0</StartVariance>
			<FinishVariance>0</FinishVariance>
			<WorkVariance>59664000</WorkVariance>
			<FreeSlack>0</FreeSlack>
			<TotalSlack>0</TotalSlack>
			<FixedCost>0</FixedCost>
			<FixedCostAccrual>3</FixedCostAccrual>
			<PercentComplete>0</PercentComplete>
			<PercentWorkComplete>0</PercentWorkComplete>
			<Cost>3992000</Cost>
			<OvertimeCost>0</OvertimeCost>
			<OvertimeWork>PT0H0M0S</OvertimeWork>
			<ActualDuration>PT0H0M0S</ActualDuration>
			<ActualCost>0</ActualCost>
			<ActualOvertimeCost>0</ActualOvertimeCost>
			<ActualWork>PT0H0M0S</ActualWork>
			<ActualOvertimeWork>PT0H0M0S</ActualOvertimeWork>
			<RegularWork>PT994H24M0S</RegularWork>
			<RemainingDuration>PT664H47M0S</RemainingDuration>
			<RemainingCost>3992000</RemainingCost>
			<RemainingWork>PT994H24M0S</RemainingWork>
			<RemainingOvertimeCost>0</RemainingOvertimeCost>
			<RemainingOvertimeWork>PT0H0M0S</RemainingOvertimeWork>
			<ACWP>0</ACWP>
			<CV>0</CV>
			<ConstraintType>0</ConstraintType>
			<CalendarUID>-1</CalendarUID>
			<LevelAssignments>1</LevelAssignments>
			<LevelingCanSplit>1</LevelingCanSplit>
			<LevelingDelay>0</LevelingDelay>
			<LevelingDelayFormat>8</LevelingDelayFormat>
			<IgnoreResourceCalendar>0</IgnoreResourceCalendar>
			<HideBar>0</HideBar>
			<Rollup>0</Rollup>
			<BCWS>0</BCWS>
			<BCWP>0</BCWP>
			<PhysicalPercentComplete>0</PhysicalPercentComplete>
			<EarnedValueMethod>0</EarnedValueMethod>
			<IsPublished>1</IsPublished>
			<CommitmentType>0</CommitmentType>
		</Task>
"



set id 0
im_ms_project_write_subtasks \
    -default_start_date $project_start_date \
   -default_duration $project_duration \
    $project_id \
    $doc \
    $tasks_node \
    "0" "1" id


# -------- Resources -------------
#    <resources>
#	<resource id="0" name="Frank Bergmann" function="Default:1" contacts="" phone="" />
#	<resource id="1" name="Klaus Hofeditz" function="Default:0" contacts="" phone="" />
#    </resources>

set resources_node [$doc createElement Resources]
$project_node appendChild $resources_node

# standard "unassigned" resource
$resources_node appendXML "
	<Resource>
		<UID>0</UID>
		<ID>0</ID>
		<Name>Unassigned</Name>
		<IsNull>0</IsNull>
		<Initials>U</Initials>
		<MaxUnits>1</MaxUnits>
		<PeakUnits>1</PeakUnits>
		<OverAllocated>0</OverAllocated>
		<CanLevel>0</CanLevel>
		<AccrueAt>3</AccrueAt>
	</Resource>
"

set id 0
set xml_elements {}
set temp temp

db_foreach project_resources $project_resources_sql {
    incr id
    
    set initials [regsub -all {(^|\W)([\w])\S*} $user_name {\2} temp]

    set resource_node [$doc createElement Resource]
    $resources_node appendChild $resource_node
    
    # minimal set of elements in case this hasn't been imported before
    if {[llength $xml_elements]==0} {
	set xml_elements {UID ID Name EmailAddress AccrueAt StandardRate 
		Cost OvertimeRate CostPerUse CalendarUID}
    }
    
    foreach element $xml_elements { 
	switch $element {
		"UID"		{ set value $user_id }
		"ID"			{ set value $id }
		"Name"		{ set value $user_name }
		"EmailAddress"	{ set value $email } 
		"AccrueAt"		{ set value 3 }
		"StandardRate" - "Cost" -
		"OvertimeRate" - "CostPerUse" { set value 0 }
		"CalendarUID"	{ set value $user_id }
		"Initials"		{ set value $initials }
		"MaxUnits" - "OverAllocated" - 
		"CanLevel" - "PeakUnits" { continue }
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

set allocations_node [$doc createElement Assignments]
$project_node appendChild $allocations_node

set project_allocations_sql "
	select	
		gp.xml_uid::integer as xml_uid,
		object_id_one AS task_id,
		object_id_two AS user_id,
		percentage
	from	acs_rels r,
		im_timesheet_tasks tt
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
					and parent.project_id = :project_id
			UNION
				select  :project_id
			)
		)
"
set assignment_ctr 0
db_foreach project_allocations $project_allocations_sql {

    ns_log Notice "microsoft-project: xml_uid=$xml_uid"

    $allocations_node appendXML "
	<Assignment>
		<UID>$assignment_ctr</UID>
		<TaskUID>$xml_uid</TaskUID>
		<ResourceUID>$user_id</ResourceUID>
		<Units>1</Units>
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
    ns_return 200 application/octet-stream "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n$xml"
}


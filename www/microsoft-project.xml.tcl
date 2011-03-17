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
	Assignments - \
	Calendars - \
	Resources - \
	Tasks - \
        ActualsInSync - \
        AdminProject - \
        AutoAddNewResourcesAndTasks - \
        Autolink - \
        BaselineForEarnedValue - \
        CalendarUID - \
        CreationDate - \
        CriticalSlackLimit - \
        CurrencyCode - \
        CurrencyDigits - \
        CurrencySymbol - \
        CurrencySymbolPosition - \
        CurrentDate - \
        DaysPerMonth - \
        DefaultFinishTime - \
        DefaultFixedCostAccrual - \
        DefaultOvertimeRate - \
        DefaultStandardRate - \
        DefaultStartTime - \
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
	Xxx { continue }
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
 
# ---------------------------------------------------------------
# Tasks

set tasks_node [$doc createElement Tasks]
$project_node appendChild $tasks_node

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
		"UID"			{ set value $user_id }
		"ID"			{ set value $id }
		"Name"			{ set value $user_name }
		"EmailAddress"		{ set value $email } 
		"AccrueAt"		{ set value 3 }
		"StandardRate" - "Cost" - "OvertimeRate" - "CostPerUse" { set value 0 }
		"CalendarUID"		{ set value $user_id }
		"Initials"		{ set value $initials }
		"MaxUnits" - "OverAllocated" - 	"CanLevel" - "PeakUnits" { continue }
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
		coalesce(bom.percentage, 0.0) as percentage_assigned,
		p.percent_completed,
		to_char(p.start_date, 'YYYY-MM-DD') as start_date_date,
		to_char(p.end_date, 'YYYY-MM-DD') as end_date_date,
		tt.planned_units
	from	acs_rels r,
		im_projects p,
		im_timesheet_tasks tt
		LEFT OUTER JOIN im_gantt_projects gp ON (tt.task_id = gp.project_id),
		im_biz_object_members bom
	where
		p.project_id = tt.task_id AND
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
		<Units>[expr $percentage_assigned / 100.0]</Units>
		<PercentWorkComplete>$percent_completed</PercentWorkComplete>
		<Start>${start_date_date}T00:00:00</Start>
		<Finish>${end_date_date}T23:00:00</Finish>
		<OvertimeWork>PT0H0M0S</OvertimeWork>
		<RegularWork>PT${planned_units}H0M0S</RegularWork>
		<RemainingWork>PT${planned_units}H0M0S</RemainingWork>
		<Work>PT${planned_units}H0M0S</Work>
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


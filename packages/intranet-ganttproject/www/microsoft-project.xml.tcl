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
		p.start_date as main_project_start_date,
		p.end_date as main_project_end_date,
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
    set value ""
    switch $element {
	"Name" - "Title"	{ set value "${project_name}.xml" }
	"Manager"		{ set value $project_lead_name }
	"StartDate"		{ set value $project_start_date }
	"FinishDate"		{ set value $project_end_date }
	"CalendarUID"		{ set value 1 }
        "ProjectExternallyEdited" { set value 0 }
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
	CreationDate - \
        CurrencyCode - \
	CurrentDate - \
        ExtendedAttributes/ - \
        FinishDate - \
	LastSaved - \
        MoveCompletedEndsForward - \
        NewTasksEstimated - \
        ProjectExternallyEdited - \
        StartDate - \
	Xxx {
	    # Don't write out these fields by default
	    set append_p 0
	}
	default {
	    set attribute_name [plsql_utility::generate_oracle_name "xml_$element"]
	    if {[info exists $attribute_name]} {
		set value [expr $$attribute_name]
	    }
	}
    }

    # the following does "<$element>$value</$element>"
    if {$append_p} {
	ns_log Notice "microsoft-project.xml.tcl: append $element=$value"
        $project_node appendFromList [list $element {} [list [list \#text $value]]]
    }
}


# ---------------------------------------------------------------
# Calendards

set calendars_node [$doc createElement Calendars]
$project_node appendChild $calendars_node

if {"" == $project_calendar} {
    # No calendar specified: Create a basic calendar spec
    # that leaves the start and end hours to the MS-Project
    # country version
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
} else {
    # We have got a project calendar imported from MS-Project
    $calendars_node appendXML [im_ms_calendar::to_xml -calendar $project_calendar]
    # ad_return_complaint 1 "<pre>[ns_quotehtml [im_ms_calendar::to_xml -calendar $project_calendar]]\n $project_calendar</pre>"
}

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
	order by
		p.person_id
"


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
		coalesce(p.percent_completed,0) as percent_completed,
		p.start_date as start_date_timestamp,
		p.end_date as end_date_timestamp,
		to_char(p.start_date, 'YYYY-MM-DD') as start_date_date,
		to_char(p.end_date, 'YYYY-MM-DD') as end_date_date,
		tt.planned_units,
		r.rel_id,
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

    # Use the main project's start and end date as defaults for the task
    if {"" == $start_date_timestamp} { set start_date_timestamp $main_project_start_date }
    if {"" == $end_date_timestamp} { set end_date_timestamp $main_project_end_date }

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
    set planned_seconds [expr $planned_units * 3600.0]
    set actual_work_seconds [expr $planned_seconds * $percent_completed / 100.0]
    set remaining_work_seconds [expr $planned_seconds - $actual_work_seconds]

    if {$total_percentage_assigned == 0} {
	set work_seconds $planned_seconds
    } else {
	set work_seconds [expr $planned_seconds * $percentage_assigned / $total_percentage_assigned]
	set actual_work_seconds [expr $actual_work_seconds * $percentage_assigned / $total_percentage_assigned]
	set remaining_work_seconds [expr $remaining_work_seconds * $percentage_assigned / $total_percentage_assigned]
    }
    set work_ms [im_gp_seconds_to_ms_project_time $work_seconds]
    set actual_work_ms [im_gp_seconds_to_ms_project_time $actual_work_seconds]
    set remaining_work_ms [im_gp_seconds_to_ms_project_time $remaining_work_seconds]
    ns_log Notice "microsoft-project: allocactions: uid=$assignment_ctr, task_id=$task_id, tot=$total_percentage_assigned, assig=$percentage_assigned"

    # There are two different ways how to create assignment entries for MS-Project:
    # 1. Based on the ]po[ information: This is a relatively simple record.
    # 2. Based on MS-Project TimephasedData: We use this if the values have not been modified in ]po[
    #    in order to return exactly the same schedule for a task that was specified in MS-Project
    #    (exact "round-trip")

    set units [expr $percentage_assigned / 100.0]

    set xml_exists_p [db_0or1row assignment_info "
	select	ga.*
	from	im_gantt_assignments ga
	where	ga.rel_id = :rel_id
    "]
    
    if {$xml_exists_p} {

	set units_diff 100
	if {$units > 0} { set units_diff [expr 100.0 * abs(($units - $xml_units) / $units)] }
        ns_log Notice "microsoft-project: TimephasedData: rel_id=$rel_id, $task_id != $xml_taskuid, $user_id != $xml_resourceuid, $units != $xml_units, units_diff=$units_diff"
	if {$task_id != $xml_taskuid} { sset xml_exists_p 0 }
	if {$user_id != $xml_resourceuid} { ssset xml_exists_p 0 }
	if {$units_diff > 10.0} { sssset xml_exists_p 0 }
    }

    if {!$xml_exists_p} {
	# Simplified assignment - no timephased data
	$allocations_node appendXML "
		<Assignment>
			<UID>$assignment_ctr</UID>
			<TaskUID>$task_id</TaskUID>
			<ResourceUID>$user_id</ResourceUID>
			<Units>$units</Units>
			<PercentWorkComplete>$percent_completed</PercentWorkComplete>
			<Start>${start_date_date}T00:00:00</Start>
			<Finish>${end_date_date}T23:00:00</Finish>
			<OvertimeWork>PT0H0M0S</OvertimeWork>
			<RegularWork>$work_ms</RegularWork>
			<ActualWork>$actual_work_ms</ActualWork>
			<RemainingWork>$remaining_work_ms</RemainingWork>
			<Work>$work_ms</Work>
		</Assignment>
        "
    } else {
	# Complete assignment - store timephased data
	set xml_xml ""
	foreach xml_element $xml_elements {
	    if {"TimephasedData" == $xml_element} { continue }
	    if {"UID" == $xml_element} { continue }
	    if {"TaskUID" == $xml_element} { continue }
	    if {"ResourceUID" == $xml_element} { continue }

	    ns_log Notice "microsoft-project: TimephasedData: store: xml_element=$xml_element, len(xml_xml) = [string length $xml_xml]"
	    set var_name "xml_[string tolower $xml_element]"
	    set var_value [expr "$$var_name"]
	    append xml_xml "<$xml_element>$var_value</$xml_element>\n\t\t\t"
	}
	set timephased_xml ""
	set timephased_sql "
		select	timephase_id,
			timephase_uid,
			timephase_type,
			timephase_start::date || 'T' || timephase_start::time as timephase_start,
			timephase_end::date || 'T' || timephase_end::time as timephase_end,
			timephase_unit,
			timephase_value
		from	im_gantt_assignment_timephases gat
		where	gat.rel_id = :rel_id
	"
	db_foreach tp $timephased_sql {
	    append timephased_xml "
			<TimephasedData>
				<Type>$timephase_type</Type>
				<UID>$timephase_uid</UID>
				<Start>$timephase_start</Start>
				<Finish>$timephase_end</Finish>
				<Unit>$timephase_unit</Unit>
				<Value>$timephase_value</Value>
			</TimephasedData>
	    "
	}

	set allocations_html "
		<Assignment>
			<UID>$assignment_ctr</UID>
			<TaskUID>$task_id</TaskUID>
			<ResourceUID>$user_id</ResourceUID>
			$xml_xml
			$timephased_xml
		</Assignment>	
	"
	$allocations_node appendXML $allocations_html
	
    }
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


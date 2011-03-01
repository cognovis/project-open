# /packages/intranet-ganttproject/www/ganttproject.xml.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Create a OpenProj XML structure for a project

    @author frank.bergmann@project-open.com
} {
    { user_id:integer 0 }
    { expiry_date "" }
    project_id:integer 
    { security_token "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set today [db_string today "select to_char(now(), 'YYYY-MM-DD')"]
if {0 == $user_id} {
    set user_id [ad_maybe_redirect_for_registration]
}

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

set project_url "/intranet/projects/view?project_id=$project_id"


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
                left join im_gantt_persons gp on (p.person_id=gp.person_id),
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

# ---------------------------------------------------------------
# Create the XML
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Project node

set doc [dom createDocument Project]
set project_node [$doc documentElement]

$project_node setAttribute xmlns "http://schemas.microsoft.com/project"

# minimal set of elements in case this hasn't been imported before
if {![info exists xml_elements] || [llength $xml_elements]==0} {
    set xml_elements {Name Title Manager ScheduleFromStart StartDate FinishDate}
}


foreach element $xml_elements { 
    switch $element {
	"Name" - "Title"            { set value $project_name }
	"Manager"                   { set value $project_lead_name }
	"ScheduleFromStart"         { set value 1 }
	"StartDate"                 { set value $project_start_date }
	"FinishDate"                { set value $project_end_date }
	"CalendarUID"               { set value 1 }
	"Calendars" 
	- "Tasks" - "Resources" 
	- "Assignments"             { continue }
	default {
	    set attribute_name [plsql_utility::generate_oracle_name "xml_$element"]
	    set value [expr $$attribute_name]
	}
    }

    # the following does "<$element>$value</$element>"
    $project_node appendFromList [list $element {} [list [list \#text $value]]]
}

# -------- Calendars ---------

set calendars_node [$doc createElement Calendars]
$project_node appendChild $calendars_node

$calendars_node appendXML "
        <Calendar>
            <UID>1</UID>
            <Name>Standard</Name>
            <IsBaseCalendar>1</IsBaseCalendar>
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
                            <FromTime>08:00:00</FromTime>
                            <ToTime>12:00:00</ToTime>
                        </WorkingTime>
                        <WorkingTime>
                            <FromTime>13:00:00</FromTime>
                            <ToTime>17:00:00</ToTime>
                        </WorkingTime>
                    </WorkingTimes>
                </WeekDay>
                <WeekDay>
                    <DayType>3</DayType>
                    <DayWorking>1</DayWorking>
                    <WorkingTimes>
                        <WorkingTime>
                            <FromTime>08:00:00</FromTime>
                            <ToTime>12:00:00</ToTime>
                        </WorkingTime>
                        <WorkingTime>
                            <FromTime>13:00:00</FromTime>
                            <ToTime>17:00:00</ToTime>
                        </WorkingTime>
                    </WorkingTimes>
                </WeekDay>
                <WeekDay>
                    <DayType>4</DayType>
                    <DayWorking>1</DayWorking>
                    <WorkingTimes>
                        <WorkingTime>
                            <FromTime>08:00:00</FromTime>
                            <ToTime>12:00:00</ToTime>
                        </WorkingTime>
                        <WorkingTime>
                            <FromTime>13:00:00</FromTime>
                            <ToTime>17:00:00</ToTime>
                        </WorkingTime>
                    </WorkingTimes>
                </WeekDay>
                <WeekDay>
                    <DayType>5</DayType>
                    <DayWorking>1</DayWorking>
                    <WorkingTimes>
                        <WorkingTime>
                            <FromTime>08:00:00</FromTime>
                            <ToTime>12:00:00</ToTime>
                        </WorkingTime>
                        <WorkingTime>
                            <FromTime>13:00:00</FromTime>
                            <ToTime>17:00:00</ToTime>
                        </WorkingTime>
                    </WorkingTimes>
                </WeekDay>
                <WeekDay>
                    <DayType>6</DayType>
                    <DayWorking>1</DayWorking>
                    <WorkingTimes>
                        <WorkingTime>
                            <FromTime>08:00:00</FromTime>
                            <ToTime>12:00:00</ToTime>
                        </WorkingTime>
                        <WorkingTime>
                            <FromTime>13:00:00</FromTime>
                            <ToTime>17:00:00</ToTime>
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


db_foreach project_resources $project_resources_sql {
    set calendar_node [$doc createElement Calendar]
    $calendars_node appendChild $calendar_node

    $calendar_node appendFromList [list UID {} [list [list \#text $user_id]]]
    $calendar_node appendFromList [list Name {} [list [list \#text $user_name]]]

    $calendar_node appendXML "<IsBaseCalendar>0</IsBaseCalendar>"
    $calendar_node appendXML "<BaseCalendarUID>4</BaseCalendarUID>"

    set weekdays_node [$doc createElement WeekDays]
    $calendar_node appendChild $weekdays_node

    db_foreach resource_absences "
       select 
          start_date::date || 'T00:00:00' as start_date,
          end_date::date || 'T23:59:00' as end_date 
       from im_user_absences
       where owner_id=:user_id
       order by start_date
    " {
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
 
# -------- Tasks -------------

ad_proc -public im_openproj_write_subtasks { 
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

	im_openproj_write_task  \
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

ad_proc -public im_openproj_write_task { 
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
                (
                   p.end_date::date - p.start_date::date 
                   - 2*(next_day(p.end_date::date-1,'FRI') - next_day(p.start_date::date-1,'FRI'))/7
                   + ROUND((extract(hour from p.end_date)-extract(hour from p.start_date))/8.0)
                )*8 AS duration,
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
    # because empty values are not accepted by GanttProject:
    #
    if {"" == $percent_completed} { set percent_completed "0" }
    if {"" == $priority} { set priority "1" }
    if {"" == $start_date} { set start_date $default_start_date }
    if {"" == $start_date} { set start_date [db_string today "select to_char(now(), 'YYYY-MM-DD')"] }
    if {"" == $duration} { 
	set duration $default_duration 
    } 
    if {"" == $duration || [string equal $start_date $end_date] } { 
	set duration 0 
    }

    set task_node [$doc createElement Task]
    $tree_node appendChild $task_node

    # minimal set of elements in case this hasn't been imported before
    if {[llength $xml_elements]==0} {
	set xml_elements {UID ID Name Type OutlineNumber OutlineLevel Priority 
	    Start Finish Duration RemainingDuration CalendarUID PredecessorLink}
    }

    set predecessors_done 0

    foreach element $xml_elements { 
	switch $element {
	    "UID"                       { set value $project_id }
	    "ID"                        { set value $id }
	    "Name"                      { set value $project_name }
	    "Type"                      { 
		if {[info exists xml_type] && $xml_type!=""} {
		    set value $xml_type
		} else {
		    set value 0 
		}
	    }
	    "OutlineNumber"             { set value $outline_number }
	    "OutlineLevel"              { set value $outline_level }
            "Priority"                  { set value 500 }
	    "Start"                     { set value $start_date }
	    "Finish"                    { set value $end_date }
	    "Duration" - "RemainingDuration" { 
		set value "PT$duration\H0M0S" 
	    }
	    "CalendarUID"               { set value -1 }
	    "Notes"                     { set value $note }
	    "PredecessorLink"           { 
		if {$predecessors_done} {
		    continue
		}
		set predecessors_done 1

		# Add dependencies to predecessors 
		# 9650 == 'Intranet Timesheet Task Dependency Type'
		set dependency_sql "
	    	   SELECT DISTINCT task_id_two
		   FROM	im_timesheet_task_dependencies 
	    	   WHERE	
                      task_id_one = :task_id 
                      AND dependency_type_id=9650
                      AND task_id_two<>:task_id
                "
		db_foreach dependency $dependency_sql {
		    $task_node appendXML "
                       <PredecessorLink>
                         <PredecessorUID>$task_id_two</PredecessorUID>
                         <Type>1</Type>
                       </PredecessorLink>
                    "
		}
		continue
	    }
	    "customproperty" - "task" - "depend" - "ExtendedAttribute" { 
		continue
	    }

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

    im_openproj_write_subtasks \
	-default_start_date $start_date \
	-default_duration $duration \
	$project_id \
	$doc \
	$tree_node \
	$outline_level \
	$outline_number \
	id
}



set tasks_node [$doc createElement Tasks]
$project_node appendChild $tasks_node

set id 0
im_openproj_write_subtasks \
    -default_start_date $project_start_date \
   -default_duration $project_duration \
    $project_id \
    $doc \
    $tasks_node \
    "0" "1" id


# -------- Resources -------------
#    <resources>
#        <resource id="0" name="Frank Bergmann" function="Default:1" contacts="" phone="" />
#        <resource id="1" name="Klaus Hofeditz" function="Default:0" contacts="" phone="" />
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
	    "UID"                   { set value $user_id }
	    "ID"                    { set value $id }
	    "Name"                  { set value $user_name }
	    "EmailAddress"          { set value $email } 
	    "AccrueAt"              { set value 3 }
	    "StandardRate" - "Cost" -
	    "OvertimeRate" - "CostPerUse" { set value 0 }
	    "CalendarUID"           { set value $user_id }
	    "Initials"              { set value $initials }
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
                object_id_one AS task_id,
                object_id_two AS user_id,
                percentage
	from	acs_rels,im_biz_object_members
	where
                acs_rels.rel_id=im_biz_object_members.rel_id AND
		object_id_one in (
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
db_foreach project_allocations $project_allocations_sql {
    $allocations_node appendXML "
        <Assignment>
            <UID>0</UID>
            <TaskUID>$task_id</TaskUID>
            <ResourceUID>$user_id</ResourceUID>
            <Units>1</Units>
        </Assignment>
    "
}

ns_return 200 application/octet-stream "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>[$doc asXML -indent 2 -escapeNonASCII]"



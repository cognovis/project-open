# /packages/intranet-ganttproject/www/ganttproject.xml.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Create a GanttProject XML structure for a project

    @author frank.bergmann@project-open.com
} {
    { user_id:integer 0 }
    { expiry_date "" }
    { project_id:integer 9689 }
    { security_token "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set today [db_string today "select to_char(now(), 'YYYY-MM-DD')"]

if { [security::secure_conn_p] } {
    set base_url "https://[ad_host][ad_port]"
} else {
    set base_url "http://[ad_host][ad_port]"
}

set task_view_url "$base_url/intranet-timesheet2-tasks/new?task_id="


# ---------------------------------------------------------------
# Get information about the project
# ---------------------------------------------------------------

if {![db_0or1row project_info "
	select	p.*,
		p.start_date::date as project_start_date,
		p.end_date::date as project_end_date,
		c.company_name
	from	im_projects p,
		im_companies c
	where	project_id = :project_id
		and p.company_id = c.company_id
"]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-ganttproject.Project_Not_Found "Didn't find project \#%project_id%"]
    return
}

set project_url "/intranet/projects/view?project_id=$project_id"


# ---------------------------------------------------------------
# Create the XML
# ---------------------------------------------------------------

set version "1.12"
set view_index 0
set gantt_divider_location 250
set resource_divider_location 250
set zooming_state 6

# ---------------------------------------------------------------
# Project node

set doc [dom createDocument project]
set project_node [$doc documentElement]
$project_node setAttribute version $version
$project_node setAttribute name $project_name
$project_node setAttribute company $company_name
$project_node setAttribute webLink $project_url
$project_node setAttribute view-date $today
$project_node setAttribute view-index $view_index
$project_node setAttribute gantt-divider-location $gantt_divider_location
$project_node setAttribute resource-divider-location $resource_divider_location


# -------- Tasks -------------

set tasks_node [$doc createElement tasks]
$project_node appendChild $tasks_node
$tasks_node setAttribute color "\#8cb6ce"
$tasks_node appendXML "
        <taskproperties>
            <taskproperty id='tpd0' name='type' type='default' valuetype='icon' />
            <taskproperty id='tpd1' name='priority' type='default' valuetype='icon' />
            <taskproperty id='tpd2' name='info' type='default' valuetype='icon' />
            <taskproperty id='tpd3' name='name' type='default' valuetype='text' />
            <taskproperty id='tpd4' name='begindate' type='default' valuetype='date' />
            <taskproperty id='tpd5' name='enddate' type='default' valuetype='date' />
            <taskproperty id='tpd6' name='duration' type='default' valuetype='int' />
            <taskproperty id='tpd7' name='completion' type='default' valuetype='int' />
            <taskproperty id='tpd8' name='coordinator' type='default' valuetype='text' />
            <taskproperty id='tpd9' name='predecessors' type='default' valuetype='text' />
            <taskproperty id='tpd10' name='label' type='default' valuetype='text' />
        </taskproperties>
"

set project_tasks_sql "
	select	t.*,
		t.start_date::date as start_date_date,
		t.end_date::date as end_date_date,
		(to_char(t.end_date, 'J')::integer - to_char(t.start_date, 'J')::integer) as duration
	from 	im_timesheet_tasks t
	where	t.project_id in (
			select
				children.project_id as subproject_id
			from
				im_projects parent,
				im_projects children
			where
				children.project_status_id not in (
					[im_project_status_deleted],
					[im_project_status_canceled]
				)
				and children.tree_sortkey between 
					parent.tree_sortkey and 
					tree_right(parent.tree_sortkey)
				and parent.project_id = :project_id
		   UNION
			select	:project_id
		)
"
db_foreach project_tasks $project_tasks_sql {

    if {"" == $start_date_date} { set start_date_date $project_start_date }
    if {"" == $end_date_date} { set end_date_date $project_end_date }
    if {"" == $duration} { 
	set duration [db_string duration "select :end_date_date::date - :start_date_date::date" -default 1]
    }
    ns_log Notice "ganttproject.xml: task #$task_id on project project #$project_id: start=$start_date_date, end=$end_date_date, dur=$duration"
    if {"" == $priority} { set priority "1" }
    if {"" == $percent_completed} { set percent_completed "0" }

    set task_node [$doc createElement task]
    $tasks_node appendChild $task_node
    $task_node setAttribute id $task_id
    $task_node setAttribute name $task_name
    $task_node setAttribute meeting "false"
    $task_node setAttribute start $start_date_date
    $task_node setAttribute duration $duration
    $task_node setAttribute complete $percent_completed
    $task_node setAttribute priority $priority
    $task_node setAttribute webLink "$task_view_url$task_id"
    $task_node setAttribute expand "true"

    # Add dependencies to predecessors
    set dependency_sql "
	select * from im_timesheet_task_dependency_map 
	where task_id_one = :task_id
    "
    db_foreach dependency $dependency_sql {
	set depend_node [$doc createElement depend]
	$task_node appendChild $depend_node
	$depend_node setAttribute id $task_id_two
	$depend_node setAttribute type 2
	$depend_node setAttribute difference 0
	$depend_node setAttribute hardness "Strong"
    }
}


# -------- Resources -------------
#    <resources>
#        <resource id="0" name="Frank Bergmann" function="Default:1" contacts="" phone="" />
#        <resource id="1" name="Klaus Hofeditz" function="Default:0" contacts="" phone="" />
#    </resources>

set resources_node [$doc createElement resources]
$project_node appendChild $resources_node

set resource_counter 0
set project_resources_sql "
	select	bom.object_role_id,
		uc.*,
		p.*,
		pa.*
	from 	users_contact uc,
		acs_rels r,
		im_biz_object_members bom,
		persons p,
		parties pa
	where	r.object_id_one = :project_id
		and r.rel_id = bom.rel_id
		and r.object_id_two = uc.user_id
		and uc.user_id = p.person_id
		and uc.user_id = pa.party_id
"
db_foreach project_resources $project_resources_sql {

    set phone [list]
    if {"" != $home_phone} { lappend phone "home: $home_phone" }
    if {"" != $work_phone} { lappend phone "work: $work_phone" }
    if {"" != $cell_phone} { lappend phone "cell: $cell_phone" }

    set function "Default:0"
    if {$object_role_id == [im_biz_object_role_project_manager]} { set function "Default:1" }

    set resource_node [$doc createElement resource]
    $resources_node appendChild $resource_node

    $resource_node setAttribute id $resource_counter
    $resource_node setAttribute name [ns_quotehtml "$first_names $last_name"]
    $resource_node setAttribute function [ns_quotehtml $function]
    $resource_node setAttribute contacts [ns_quotehtml $email]
    $resource_node setAttribute phone [ns_quotehtml [join $phone ", "]]

    incr resource_counter
}


# -------- Zooming State -------------
$project_node appendFromList [list widget [list zooming-state $zooming_state] [list]]
# $project_node appendXML "<view zooming-state='$zooming_state'/>"


# --------- Calendars Node -----------

$project_node appendXML "
<calendars>
    <day-types>
        <day-type id='0'/>
        <day-type id='1'/>
        <calendar id='1' name='default'>
            <default-week sun='1' mon='0' tue='0' wed='0' thu='0' fri='0' sat='1'/>
            <overriden-day-types/>
            <days/>
        </calendar>
    </day-types>
</calendars>"

# -------- Description -------------
$project_node appendXML "<description>[ns_quotehtml $note]</description>"



# -------- Task Display Columns -------------
$project_node appendXML "
    <taskdisplaycolumns>
        <displaycolumn property-id='tpd3' order='0' width='150' />
        <displaycolumn property-id='tpd4' order='1' width='30' />
        <displaycolumn property-id='tpd5' order='2' width='30' />
    </taskdisplaycolumns>
"


# -------- Roleset Name -------------
$project_node appendXML "
    <roles roleset-name='Default'/>
"


ns_return 200 text/xml [$doc asXML -indent 2 -escapeNonASCII]



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
# Write Out a Single Task
# ---------------------------------------------------------------

ad_proc -public im_ganttproject_write_project_task {
    task_id
    doc
    project_node
    tree_node
    project_id
} {
    Create a GanttProject XML structure for a single task
} {
    if { [security::secure_conn_p] } {
        set base_url "https://[ad_host][ad_port]"
    } else {
        set base_url "http://[ad_host][ad_port]"
    }
    set task_view_url "$base_url/intranet-timesheet2-tasks/new?task_id="
    set project_view_url "$base_url/intranet/projects/view?project_id="

    set project_tasks_sql "
    	select	t.*,
    		t.start_date::date as start_date_date,
    		t.end_date::date as end_date_date,
    		(to_char(t.end_date, 'J')::integer - to_char(t.start_date, 'J')::integer) as duration
    	from 	im_timesheet_tasks t
    	where	t.task_id = :task_id
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
        $project_node appendChild $task_node
        $task_node setAttribute id $task_id
        $task_node setAttribute name $task_name
        $task_node setAttribute meeting "false"
        $task_node setAttribute start $start_date_date
        $task_node setAttribute duration $duration
        $task_node setAttribute complete $percent_completed
        $task_node setAttribute priority $priority
        $task_node setAttribute webLink "$task_view_url$task_id"
        $task_node setAttribute expand "true"

	# Custom Property "task_nr"
	# <customproperty taskproperty-id="tpc0" value="linux_install" />
	set task_nr_node [$doc createElement customproperty]
	$task_node appendChild $task_nr_node
	$task_nr_node setAttribute taskproperty-id tpc0
	$task_nr_node setAttribute value $task_nr

	# Custom Property "task_id"
	# <customproperty taskproperty-id="tpc1" value="12345" />
	set task_id_node [$doc createElement customproperty]
	$task_node appendChild $task_id_node
	$task_id_node setAttribute taskproperty-id tpc1
	$task_id_node setAttribute value $task_id

        # Add dependencies to predecessors
        set dependency_sql "
	    	select * from im_timesheet_task_dependencies 
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
}


# ---------------------------------------------------------------
# Write Out Tasks (recursively)
# ---------------------------------------------------------------


ad_proc -public im_ganttproject_write_project { 
    doc
    tree_node 
    project_id
} {
    Recursively write out the information about the tasks
    below a specific project.
} {
    if { [security::secure_conn_p] } {
	set base_url "https://[ad_host][ad_port]"
    } else {
	set base_url "http://[ad_host][ad_port]"
    }
    set task_view_url "$base_url/intranet-timesheet2-tasks/new?task_id="
    set project_view_url "$base_url/intranet/projects/view?project_id="

    # ------------ Create the Project Node -------------
    if {![db_0or1row project_info "
        select  p.*,
                p.start_date::date as project_start_date,
                p.end_date::date as project_end_date,
		p.end_date::date - p.start_date::date as duration,
		1 as priority,
                c.company_name
        from    im_projects p,
                im_companies c
        where   project_id = :project_id
                and p.company_id = c.company_id
	order by
		sort_order
    "]} {
	ad_return_complaint 1 [lang::message::lookup "" intranet-ganttproject.Project_Not_Found "Didn't find project \#%project_id%"]
	return
    }

    if {"" == $percent_completed} { set percent_completed "0" }

    set project_node [$doc createElement task]
    $tree_node appendChild $project_node
    $project_node setAttribute id $project_id
    $project_node setAttribute name $project_name
    $project_node setAttribute meeting "false"
    $project_node setAttribute start $project_start_date
    $project_node setAttribute duration $duration
    $project_node setAttribute complete $percent_completed
    $project_node setAttribute priority $priority
    $project_node setAttribute webLink "$project_view_url$project_id"
    $project_node setAttribute expand "true"

    # Custom Property "task_nr"
    # <customproperty taskproperty-id="tpc0" value="linux_install" />
    set task_nr_node [$doc createElement customproperty]
    $project_node appendChild $task_nr_node
    $task_nr_node setAttribute taskproperty-id tpc0
    $task_nr_node setAttribute value $project_nr
    
    # Custom Property "task_id"
    # <customproperty taskproperty-id="tpc1" value="12345" />
    set task_id_node [$doc createElement customproperty]
    $project_node appendChild $task_id_node
    $task_id_node setAttribute taskproperty-id tpc1
    $task_id_node setAttribute value $project_id
    
    # ------------ Select both Tasks and Sub-Projects -------------
    # ... in the sort_order

    set object_list_list [db_list_of_lists sorted_query "
	select *
	from
	    (	select	p.project_id as object_id,
			'im_project' as object_type,
			sort_order
		from	im_projects p
		where	parent_id = :project_id
	                and project_status_id not in (
				[im_project_status_deleted], 
				[im_project_status_closed]
			)
	    UNION
		select	t.task_id as object_id,
			'im_timesheet_task' as object_type,
			t.sort_order
		from	im_timesheet_tasks t
		where	t.project_id = :project_id
	   ) ttt
	order by sort_order
    "]

    foreach object_record $object_list_list {
	set object_id [lindex $object_record 0]
	set object_type [lindex $object_record 1]

	switch $object_type {
	    "im_timesheet_task" {
		im_ganttproject_write_project_task \
			$object_id \
			$doc \
			$project_node \
			$tree_node \
			$project_id
	    }
	    "im_project" {
		# Recurse into Sub-Projects
		set subproject_sql "
			select	project_id
			from	im_projects
			where	parent_id = :project_id
				and project_status_id not in (
					[im_project_status_deleted], 
					[im_project_status_closed]
				)
                "
		db_foreach sub_projects $subproject_sql {
		    # ToDo: Check infinite loop!!!
		    im_ganttproject_write_project_tasks $doc $project_node $project_id
		}
	    }
	    default {
		ad_return_complaint 1 "Object type '$object_type' not supported"
	    }
	}
    }
}


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
set gantt_divider_location 300
set resource_divider_location 300
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
	    <taskproperty id='tpc0' name='task_nr' type='custom' valuetype='text' defaultvalue='' />
	    <taskproperty id='tpc1' name='task_id' type='custom' valuetype='int' defaultvalue='0' />
        </taskproperties>
"

# Recursively write out the task hierarchy
im_ganttproject_write_project $doc $tasks_node $project_id


# -------- Resources -------------
#    <resources>
#        <resource id="0" name="Frank Bergmann" function="Default:1" contacts="" phone="" />
#        <resource id="1" name="Klaus Hofeditz" function="Default:0" contacts="" phone="" />
#    </resources>

set resources_node [$doc createElement resources]
$project_node appendChild $resources_node

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

db_foreach project_resources $project_resources_sql {

    set phone [list]
    if {"" != $home_phone} { lappend phone "home: $home_phone" }
    if {"" != $work_phone} { lappend phone "work: $work_phone" }
    if {"" != $cell_phone} { lappend phone "cell: $cell_phone" }

    set function "Default:0"
    if {$object_role_id == [im_biz_object_role_project_manager]} { set function "Default:1" }

    set resource_node [$doc createElement resource]
    $resources_node appendChild $resource_node

    $resource_node setAttribute id $user_id
    $resource_node setAttribute name [ns_quotehtml "$first_names $last_name"]
    $resource_node setAttribute function [ns_quotehtml $function]
    $resource_node setAttribute contacts [ns_quotehtml $email]
    $resource_node setAttribute phone [ns_quotehtml [join $phone ", "]]
}


# -------- Allocations -------------
# Allocations only work on tasks, not on projects (super-tasks)
# <allocations>
#   <allocation task-id="12391" resource-id="9021" function="Default:1" responsible="true" load="20.0"/>
#   <allocation task-id="12302" resource-id="9021" function="Default:1" responsible="false" load="50.0"/>
#   <allocation task-id="12302" resource-id="8892" function="Default:0" responsible="true" load="50.0"/>
# </allocations>

set allocations_node [$doc createElement allocations]
$project_node appendChild $allocations_node

set project_allocations_sql "
	select	*
	from	im_timesheet_task_allocations tta
	where
		tta.task_id in (
			select	task_id
			from	im_timesheet_tasks
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
    set allocation_node [$doc createElement allocation]
    $allocations_node appendChild $allocation_node

    set responsible "false"
    if {"t" == $task_manager_p} { set responsible "true" }

    $allocation_node setAttribute task-id $task_id
    $allocation_node setAttribute resource-id $user_id
    $allocation_node setAttribute function "Default:0"
    $allocation_node setAttribute responsible $responsible
    $allocation_node setAttribute load $percentage
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
	<displaycolumn property-id='tpc0' order='3' width='80' />
	<displaycolumn property-id='tpc1' order='4' width='40' />
    </taskdisplaycolumns>
"

set date_columns "
	<displaycolumn property-id='tpd4' order='1' width='30' />
	<displaycolumn property-id='tpd5' order='2' width='30' />
"


# -------- Roleset Name -------------
$project_node appendXML "
    <roles roleset-name='Default'/>
"


ns_return 200 text/xxx [$doc asXML -indent 2 -escapeNonASCII]



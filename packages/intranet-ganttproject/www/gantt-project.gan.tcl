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

# get the current users permissions for this project
im_project_permissions $user_id $project_id view read write admin
if {!$read || ![im_permission $user_id "view_gantt_proj_detail"]} { 
    ad_return_complaint 1 "You don't have permissions to see this page" 
    ad_script_abort
}



# ---------------------------------------------------------------
# Get information about the project
# ---------------------------------------------------------------

if {![db_0or1row project_info "
	select	p.*,
		p.start_date::date as project_start_date,
		p.end_date::date as project_end_date,
		p.end_date::date - p.start_date::date as project_duration,
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
im_ganttproject_write_subtasks \
    -default_start_date $project_start_date \
    -default_duration $project_duration \
    $project_id \
    $doc \
    $tasks_node

set resources_node [$doc createElement resources]
$project_node appendChild $resources_node

set project_resources_sql "
	select	distinct 
                bom.object_role_id,
		uc.*,
		p.*,
		pa.*,
		im_name_from_user_id(p.person_id) as user_name
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

set resource_ids {}

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
    $resource_node setAttribute name [ns_quotehtml $user_name]
    $resource_node setAttribute function [ns_quotehtml $function]
    $resource_node setAttribute contacts [ns_quotehtml $email]
    $resource_node setAttribute phone [ns_quotehtml [join $phone ", "]]

    lappend resource_ids $user_id
}


# -------- Allocations -------------
# <allocations>
#   <allocation task-id="12391" resource-id="9021" function="Default:1" responsible="true" load="20.0"/>
#   <allocation task-id="12302" resource-id="9021" function="Default:1" responsible="false" load="50.0"/>
#   <allocation task-id="12302" resource-id="8892" function="Default:0" responsible="true" load="50.0"/>
# </allocations>


set allocations_node [$doc createElement allocations]
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
    set allocation_node [$doc createElement allocation]
    $allocations_node appendChild $allocation_node

    set responsible "false"
    #TODO: if {"t" == $task_manager_p} { set responsible "true" }

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
$project_node appendXML "<description>[ns_quotehtml $description]</description>"


# -------- vacations / abscenses ----------------------
# <vacations>
# <vacation start="2008-06-18" end="2008-06-18" resourceid="624"/>
# <vacation start="2008-06-11" end="2008-06-12" resourceid="624"/>
# </vacations>

if {[llength $resource_ids] > 0} {
    set vacations_node [$doc createElement vacations]
    $project_node appendChild $vacations_node

    db_foreach abscenses "
       select 
          owner_id,
          start_date::date as start_date,
          end_date::date as end_date 
       from im_user_absences
       where owner_id in ([join $resource_ids ,])
  " {
      set vacation_node [$doc createElement vacation]
      $vacation_node setAttribute start $start_date
      $vacation_node setAttribute end $end_date
      $vacation_node setAttribute resourceid $owner_id
      $vacations_node appendChild $vacation_node
   }
}

# -------- Task Display Columns -------------
$project_node appendXML "
    <taskdisplaycolumns>
	<displaycolumn property-id='tpd3' order='0' width='150' />
<!--	<displaycolumn property-id='tpc0' order='3' width='80' /> -->
<!--	<displaycolumn property-id='tpc1' order='4' width='40' /> -->
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


ns_return 200 application/octet-stream [$doc asXML -indent 2 -escapeNonASCII]



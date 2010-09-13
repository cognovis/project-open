# /packages/intranet-ganttproject/www/taskjuggler.xml.tcl
#
# Copyright (C) 2003 - 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Create a TaskJuggler .tpj file for scheduling
    @author frank.bergmann@project-open.com
} {
    project_id:integer 
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set today [db_string today "select to_char(now(), 'YYYY-MM-DD')"]
set user_id [ad_maybe_redirect_for_registration]

set hours_per_day 8.0
set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

# ---------------------------------------------------------------
# Get information about the project
# ---------------------------------------------------------------

if {![db_0or1row project_info "
	select	g.*,
                p.*,
		p.project_id as main_project_id,
                p.start_date::date as project_start_date,
                p.end_date::date as project_end_date,
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
# Create the TJ Header
# ---------------------------------------------------------------

set base_tj "
/*
 * This file has been automatically created by \]project-open\[
 * Please do not edit manually. 
 */

project p$project_id \"$project_name\" \"1.0\" $project_start_date - $project_end_date {
    currency \"$default_currency\"
}
"


# ---------------------------------------------------------------
# Resource TJ Entries
# ---------------------------------------------------------------

set project_resources_sql "
	select distinct
                p.*,
		im_name_from_user_id(p.person_id) as user_name,
		pa.email,
		uc.*,
		e.*
	from 	users_contact uc,
		acs_rels r,
		im_biz_object_members bom,
		persons p,
		parties pa
		LEFT OUTER JOIN im_employees e ON (pa.party_id = e.employee_id)
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

set resource_tj ""
db_foreach project_resources $project_resources_sql {

    set user_tj "resource r$person_id \"$user_name\" {\n"

    if {"" != $hourly_cost} {
	append user_tj "\trate [expr $hourly_cost * $hours_per_day]\n"
    }

    set absences_sql "
	select	ua.start_date::date as absence_start_date,
		ua.end_date::date + 1 as absence_end_date 
	from	im_user_absences ua
	where	ua.owner_id = :person_id and
		ua.end_date >= :project_start_date
	order by start_date
    "
    db_foreach resource_absences $absences_sql {
	append user_tj "\tvacation $absence_start_date - $absence_end_date\n"
    }

    append user_tj "}\n"
    append resource_tj "$user_tj\n"

}

# ---------------------------------------------------------------
# Task TJ Entries
# ---------------------------------------------------------------

# Start writing out the tasks
set tasks_tj [im_taskjuggler_write_subtasks $main_project_id]




ad_return_complaint 1 "
<pre>
$base_tj
$resource_tj
$tasks_tj
</pre>
"










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



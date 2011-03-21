# /packages/intranet-core/projects/view.tcl
#
# Copyright (C) 1998-2004 various parties
# The software is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    View all the info about a specific project.

    @param project_id the group id
    @param orderby the display order
    @param show_all_comments whether to show all comments

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { project_id:integer 0}
    { response_id:integer 0}
}

if {0 == $project_id} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_specify_a] "
    return
}

# First check if the report is already generated, then just return the
# generated PDF

# Use the highest (latest) item_id, just in case.. we have more from
# somewhere else, altough this should not happen, to be honest.....
set item_id [db_string get_item "select max(item_id) from cr_items where parent_id = :response_id and content_type = 'content_revision'" -default ""]

if {$item_id ne ""} {
    ad_returnredirect "/file/$item_id"
}

set extra_selects [list "0 as zero"]
set column_sql "
	select  w.deref_plpgsql_function,
		aa.attribute_name
	from    im_dynfield_widgets w,
		im_dynfield_attributes a,
		acs_attributes aa
	where   a.widget_name = w.widget_name and
		a.acs_attribute_id = aa.attribute_id and
		aa.object_type = 'im_project'
"
db_foreach column_list_sql $column_sql {
    lappend extra_selects "${deref_plpgsql_function}(p.$attribute_name) as ${attribute_name}_deref"
}

set extra_select [join $extra_selects ",\n\t"]

set query "
select
	p.*,
        (select aux_int1 from im_categories where category_id = p.project_priority_st_id) as strategic_value,
        (select aux_int1 from im_categories where category_id = p.project_priority_op_id) as operative_value,
	c.*,
	to_char(p.end_date, 'HH24:MI') as end_date_time,
	to_char(p.start_date, 'DD.MM.YYYY') as start_date_formatted,
	to_char(p.end_date, 'DD.MM.YYYY') as end_date_formatted,
	to_char(p.percent_completed, '999990.9%') as percent_completed_formatted,
	c.primary_contact_id as company_contact_id,
	im_name_from_user_id(c.primary_contact_id) as company_contact,
	im_email_from_user_id(c.primary_contact_id) as company_contact_email,
	im_name_from_user_id(p.project_lead_id) as project_lead,
	im_name_from_user_id(p.supervisor_id) as supervisor,
	im_name_from_user_id(c.manager_id) as manager,
	$extra_select
from
	im_projects p, 
	im_companies c

where 
	p.project_id=:project_id
	and p.company_id = c.company_id
"


if { ![db_0or1row projects_info_query $query] } {
    ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
    return
}

set project_type [im_category_from_id $project_type_id]
set project_status [im_category_from_id $project_status_id]

# Get the parent project's name
if {"" == $parent_id} { set parent_id 0 }
set parent_name [util_memoize [list db_string parent_name "select project_name from im_projects where project_id = $parent_id" -default ""]]

set user_id [ad_conn user_id]
set creator [im_name_from_user_id $user_id]
set creator_cost_center [db_string cost_center "select cost_center_name from im_cost_centers, im_employees where department_id = cost_center_id and employee_id = :user_id" -default ""]


set questions_sql "
		select	r.response_id,
			r.question_id,
			r.choice_id,
			sqc.label as choice,
			r.boolean_answer,
			r.clob_answer,
			r.number_answer,
			r.varchar_answer,
			r.date_answer
		from	survsimp_questions q,
			survsimp_question_responses r
			LEFT OUTER JOIN survsimp_question_choices sqc ON (r.choice_id = sqc.choice_id)
		where	q.question_id = r.question_id
			and r.response_id = :response_id
		order by sort_key
	"

db_foreach response $questions_sql {
    set ${question_id}_response "$choice $boolean_answer $clob_answer $number_answer $varchar_answer $date_answer"

}

foreach question_id [list 27931 27932 27933 27934] {

    
    set answer [string trim [set ${question_id}_response]]
    set answer [lang::util::localize $answer en_US]
    ns_log Notice "$question_id :: $answer"
    switch $answer {
        Yellow {
            set ${question_id}_response {
                <draw:frame draw:style-name="fr2" draw:name="Grafik2" text:anchor-type="as-char" svg:width="0.681cm" svg:height="1.799cm" draw:z-index="5">
                <draw:image xlink:href="Pictures/10000000000000190000004208AE16B6.png" xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad"/>
                </draw:frame>
            }
        }
        Red {
            set ${question_id}_response {
                <draw:frame draw:style-name="fr2" draw:name="Grafik1" text:anchor-type="as-char" svg:width="0.681cm" svg:height="1.739cm" draw:z-index="2">
                <draw:image xlink:href="Pictures/100000000000001A0000004408B1848C.png" xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad"/>
                </draw:frame>
            }
        }
        Green {
            set ${question_id}_response {
                <draw:frame draw:style-name="fr2" draw:name="Grafik3" text:anchor-type="as-char" svg:width="0.681cm" svg:height="1.739cm" draw:z-index="3">
                <draw:image xlink:href="Pictures/100000000000001A0000004558E63332.png" xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad"/>
                </draw:frame>
            }
        }
        default {
            set ${question_id}_response ""
        }
    }   
}

set 51640_response "malte"
set aufwand_xml ""

#    select im_cost_center__name(cost_center_id) as cost_center, coalesce(sum(planned_units),0) as planned, coalesce(sum(hours),0) as logged from (select cost_center_id, planned_units, hours from im_projects p, im_timesheet_tasks t left outer join im_hours h on (t.task_id = h.project_id) where parent_id = :project_id and t.task_id = p.project_id) as hours group by cost_center_id;


# get the project list
set project_ids_sql [im_project_subproject_ids -project_id $project_id -project_type_ids 10000037 -sql]

# Get the tasks
set task_ids_sql [im_project_subproject_ids -project_id $project_id -project_type_ids 10000037 -type "task" -sql]

set logged_cost_centers [list]
# get the logged hours per cost center
db_foreach cost_center "
	select sum(hours) as hours, im_cost_center__name(department_id) as cost_center, department_id as cost_center_id
			from im_hours h, im_employees e, im_projects p
			where p.project_id in ($project_ids_sql,$task_ids_sql)
			and h.user_id = e.employee_id
			and p.project_id = h.project_id
              group by cost_center_id
" {
	set logged_hours($cost_center_id) $hours
	set cost_center_name($cost_center_id) $cost_center
	lappend logged_cost_centers $cost_center_id
}

set created_cost_centers [list]
db_foreach cost_centers "
    select im_cost_center__name(cost_center_id) as cost_center, cost_center_id,
       coalesce(sum(remaining_hours),0) as remaining_hours,
       coalesce(round(cast((100 - (sum(remaining_hours) / sum(planned_units))*100 ) as numeric),2),round(100,2)) as percent_completed,
       coalesce(sum(planned_units),0) as planned 
    from (select cost_center_id, planned_units,
            (planned_units * (100-percent_completed) / 100) as remaining_hours
          from im_projects p, 
            im_timesheet_tasks t 
	  where   p.parent_id in ($project_ids_sql) and t.task_id = p.project_id) as hours 
    group by cost_center_id
" {
	
	if {![exists_and_not_null logged_hours($cost_center_id)]} {
		set logged_hours($cost_center_id) 0
	}
	
    set abweichung [expr $planned - $logged_hours($cost_center_id)]
	ds_comment "percent $percent_completed :: $remaining_hours :: $planned"
	append aufwand_xml "
	<table:table-row table:style-name=\"Tabelle4.1\">
	<table:table-cell table:style-name=\"Tabelle4.A2\" office:value-type=\"string\">
	<text:p text:style-name=\"P33\">$cost_center</text:p>
	</table:table-cell>
	<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
	<text:p text:style-name=\"P33\">$planned</text:p>
	</table:table-cell>
	<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
	<text:p text:style-name=\"P33\">$logged_hours($cost_center_id)</text:p>
	</table:table-cell>
	<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
	<text:p text:style-name=\"P33\">$percent_completed</text:p>
	</table:table-cell>
	<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
	<text:p text:style-name=\"P33\">$abweichung</text:p>
	</table:table-cell>
	<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
	<text:p text:style-name=\"P33\">$remaining_hours</text:p>
	</table:table-cell>
	</table:table-row>
    "

	lappend created_cost_centers $cost_center_id
}


foreach cost_center_id $logged_cost_centers {
	
	# Check if we inserted the cost center already
	if {[lsearch $created_cost_centers $cost_center_id] < 0} {
		append aufwand_xml "
		<table:table-row table:style-name=\"Tabelle4.1\">
		<table:table-cell table:style-name=\"Tabelle4.A2\" office:value-type=\"string\">
		<text:p text:style-name=\"P33\">$cost_center_name($cost_center_id)</text:p>
		</table:table-cell>
		<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
		<text:p text:style-name=\"P33\"></text:p>
		</table:table-cell>
		<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
		<text:p text:style-name=\"P33\">$logged_hours($cost_center_id)</text:p>
		</table:table-cell>
		<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
		<text:p text:style-name=\"P33\"></text:p>
		</table:table-cell>
		<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
		<text:p text:style-name=\"P33\"></text:p>
		</table:table-cell>
		<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
		<text:p text:style-name=\"P33\"></text:p>
		</table:table-cell>
		</table:table-row>
	    "
	}
}

# Initialize
set invest_estimate 0
set invest_ist 0
set invest_obligo 0
set single_estimate 0
set single_ist 0
set single_obligo 0

db_foreach investitionskosten "select round(sum(item_units * price_per_unit),0) as amount, cost_type_id from im_invoice_items ii, im_costs c where ii.invoice_id = c.cost_id and c.project_id in ($project_ids_sql) and item_material_id = 33361 group by cost_type_id" {
    switch $cost_type_id {
	3750 {set invest_estimate $amount}
	3704 {set invest_ist $amount}
	3706 {set invest_obligo $amount}
    }
}


db_foreach einmalkosten "select round(sum(item_units * price_per_unit),0) as amount, cost_type_id from im_invoice_items ii, im_costs c where ii.invoice_id = c.cost_id and c.project_id in ($project_ids_sql) and item_material_id = 33359 group by cost_type_id" {
    switch $cost_type_id {
	3750 {set single_estimate $amount}
	3704 {set single_ist $amount}
	3706 {set single_obligo $amount}
    }
}

db_1row plankosten "select coalesce(single_costs,0) as single_plan, coalesce(investment_cost,0) as invest_plan from im_projects where project_id = :project_id"

set invest_delta1 [expr $invest_plan - $invest_ist - $invest_obligo]
set invest_delta2 [expr $invest_delta1 - $invest_estimate]

set single_delta1 [expr $single_plan - $single_ist - $single_obligo]
set single_delta2 [expr $single_delta1 - $single_estimate]

# Gesamtsumme

set gesamt_plan [expr $invest_plan + $single_plan]
set gesamt_ist [expr $invest_ist + $single_ist]
set gesamt_delta1 [expr $invest_delta1 + $single_delta1]
set gesamt_obligo [expr $invest_obligo + $single_obligo]
set gesamt_estimate [expr $invest_estimate + $single_estimate]
set gesamt_delta2 [expr $invest_delta2 + $single_delta2]

# Save the Generated Statusbericht along with this response as a
# content item.
intranet_oo::parse_content -template_file_path "[acs_package_root_dir "intranet-cust-berendsen"]/templates/statusbericht.odt" -output_filename ${project_name}.pdf -parent_id $response_id

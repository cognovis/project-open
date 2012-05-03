# /packages/intranet-pmo/www/statusreport.tcl
#
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
#

ad_page_contract {
    Generate a status report

    @param project_id the group id
    @author Malte Sussdorff ( malte.sussdorff@cognovis.de )
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
    ad_script_abort
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

set aufwand_xml ""


# Get the tasks
set task_ids_sql [im_project_subproject_ids -project_id $project_id -type "task" -sql]
set project_ids_sql [im_project_subproject_ids -project_id $project_id -sql]

# get the logged hours per cost center
set logged_cost_centers [list]
db_foreach cost_center "
	select sum(hours) as hours, department_id as cost_center_id
			from im_hours h, im_employees e, im_projects p
			where p.project_id in ($project_ids_sql,$task_ids_sql)
			and h.user_id = e.employee_id
			and p.project_id = h.project_id
              group by cost_center_id
" {
	set logged_hours($cost_center_id) $hours
	lappend logged_cost_centers $cost_center_id
}


# Get the budget information
set budget_id [db_string budget_id "select item_id from cr_items where parent_id = :project_id and content_type = 'im_budget' limit 1" -default ""]
db_1row budget_information "select budget, budget_hours, investment_costs, single_costs from im_budgets where budget_id = (select live_revision from cr_items where item_id = :budget_id)"


# Get the planned data from the database
set cost_center_ids [list]
db_foreach hours_sql {select sum(hours) as hours,department_id 
    from im_budget_hoursx 
    where hour_id in (select live_revision from cr_items where parent_id = :budget_id and content_type = 'im_budget_hour') group by department_id
} {
    set budgeted_hours($department_id) $hours
    lappend cost_center_ids $department_id
}

# Get the latest data from the database
db_foreach hours_sql {select sum(hours) as hours,department_id 
    from im_budget_hoursx 
    where hour_id in (select latest_revision from cr_items where parent_id = :budget_id and content_type = 'im_budget_hour') group by department_id
} {
    set latest_hours($department_id) $hours
    if {[lsearch $cost_center_ids $department_id]<0} {
        # This deparment wasn't budgeted
        lappend cost_center_ids $department_id
        set budgeted_hours($department_id) 0
    }
}

# Get the total remaining hours
db_1row hours "select coalesce(sum(remaining_hours),0) as remaining_hours,
       coalesce(sum(planned_units),0) as planned 
    from (select planned_units,
            (planned_units * (100-coalesce(percent_completed,0)) / 100) as remaining_hours
          from im_projects p, 
            im_timesheet_tasks t 
	  where   p.parent_id in ($project_ids_sql) and t.task_id = p.project_id) as hours 
"

foreach cost_center_id $logged_cost_centers {
	
	# Check if we inserted the cost center already.
    # We only want to use cost centers here which have logged hours,
    # but no 
	if {[lsearch $cost_center_ids $cost_center_id] < 0} {
        lappend cost_center_ids $cost_center_id
        set budgeted_hours($cost_center_id) 0
        set latest_hours($cost_center_id) 0
    }
}

set total_logged_hours 0
set total_budget_change 0

foreach cost_center_id $cost_center_ids {

	if {![exists_and_not_null logged_hours($cost_center_id)]} {
		set logged_hours($cost_center_id) 0
	}

	if {![exists_and_not_null latest_hours($cost_center_id)]} {
		set latest_hours($cost_center_id) 0
	}
	
    set remaining_budget [expr $budgeted_hours($cost_center_id) - $logged_hours($cost_center_id)]
    set budget_change [expr $budgeted_hours($cost_center_id) - $latest_hours($cost_center_id)]
    set cost_center [db_string cost_center "select im_cost_center__name(:cost_center_id) from dual" -default ""]

    # Get the totals
    set total_logged_hours [expr $total_logged_hours + $logged_hours($cost_center_id)]
    set total_budget_change [expr $total_budget_change + $budget_change]
	append aufwand_xml "
	<table:table-row table:style-name=\"Tabelle4.1\">
	<table:table-cell table:style-name=\"Tabelle4.A2\" office:value-type=\"string\">
	<text:p text:style-name=\"P33\">$cost_center</text:p>
	</table:table-cell>
	<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
	<text:p text:style-name=\"P33\">$budgeted_hours($cost_center_id)</text:p>
	</table:table-cell>
	<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
	<text:p text:style-name=\"P33\">$logged_hours($cost_center_id)</text:p>
	</table:table-cell>
	<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
	<text:p text:style-name=\"P33\">$remaining_budget</text:p>
	</table:table-cell>
	<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
	<text:p text:style-name=\"P33\"></text:p>
	</table:table-cell>
	<table:table-cell table:style-name=\"Tabelle4.B2\" office:value-type=\"string\">
	<text:p text:style-name=\"P33\">$budget_change</text:p>
	</table:table-cell>
	</table:table-row>
    "
}

set total_remaining_budget [expr $budget_hours - $total_logged_hours]

#################
# 
# COST TABLES
#
#################


# Initialize
set invest_ist [db_string invest_costs "select sum(amount) from sap_invoices where sap_project_nr = (select sap_project_nr from im_projects where project_id = :project_id) and konto <3000" -default ""]
if {$invest_ist eq ""} {set invest_ist 0}

set single_ist [db_string single_costs "select sum(amount) from sap_invoices where sap_project_nr = (select sap_project_nr from im_projects where project_id = :project_id) and konto >=3000" -default ""]
if {$single_ist eq ""} {set single_ist 0}

db_1row budget_plan_information "select coalesce(budget,0) as budget_latest, coalesce(investment_costs,0) as investment_cost_latest, coalesce(single_costs,0) as single_cost_latest from im_budgets where budget_id = (select latest_revision from cr_items where item_id = :budget_id)"


set invest_delta1 [expr $investment_costs - $invest_ist]
set invest_delta2 [expr $investment_costs - $investment_cost_latest]

set single_delta1 [expr $single_costs - $single_ist]
set single_delta2 [expr $single_costs - $single_cost_latest]

# Gesamtsumme

set gesamt_ist [expr $invest_ist + $single_ist]
set gesamt_delta1 [expr $budget - $gesamt_ist]
set gesamt_delta2 [expr $budget - $budget_latest]

# Save the Generated Statusbericht along with this response as a
# content item.
intranet_oo::parse_content -template_file_path "[acs_package_root_dir "intranet-pmo"]/templates/statusbericht.odt" -output_filename ${project_name}.pdf -parent_id $response_id

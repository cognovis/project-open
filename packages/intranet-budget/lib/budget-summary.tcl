ad_page_contract {
    It displays budget information
} { 
    {-project_id ""}
}


set budget_id [db_string budget_id "select item_id from cr_items where parent_id = :project_id and content_type = 'im_budget' limit 1" -default ""]
set Budget [::im::dynfield::CrClass::im_budget get_instance_from_db -item_id $budget_id]            

# ----------------- 1 Table Budget Costs HTML
set budget_cost_html "
    <table with=\"100%\">
      <tr class=rowtitle>
        <td class=rowtitle colspan=2 align=center>[_ intranet-budget.Budget]</td>"

# get the project list
set project_budget [$Budget budget]
set project_budget_hours [$Budget budget_hours]
set project_budget_currency "EUR"

array set subtotals [im_cost_update_project_cost_cache $project_id]

append budget_cost_html "</tr>\n<tr>\n<td>[_ intranet-core.Project_Budget]</td>\n"
append budget_cost_html "<td align=right>+ $project_budget $project_budget_currency</td>\n"

append budget_cost_html "</tr>\n<tr>\n<td>[_ intranet-cost.Provider_Bills]</td>\n"
set provider_bills $subtotals([im_cost_type_bill])
append budget_cost_html "<td align=right>- $provider_bills $project_budget_currency</td>\n"

append budget_cost_html "</tr>\n<tr>\n<td>[_ intranet-budget.Cost_Estimates]</td>\n"


# Set Cost Estimates
set cost_ids [db_list costs {select item_id from cr_items where parent_id = :budget_id and content_type = 'im_budget_cost'}]
set cost_estimates 0
foreach item_id $cost_ids {
    set Cost [::im::dynfield::CrClass::im_budget_cost get_instance_from_db -item_id $item_id]            
    incr cost_estimates [$Cost amount]
}
set cost_estimates [expr $cost_estimates - $provider_bills]
append budget_cost_html "<td align=right>- $cost_estimates $project_budget_currency</td>\n"


set remaining_budget [expr $project_budget - $provider_bills - $cost_estimates]
append budget_cost_html "</tr>\n<tr>\n<td><b>[_ intranet-budget.Remaining_Budget]</b></td>\n"
append budget_cost_html "<td align=right><b>$remaining_budget $project_budget_currency</b></td>\n"
append budget_cost_html "</tr>\n</table>\n"






# ----------------- 2. Table Logged Hours HTML
# Get the numbers for each task in this project and any subproject
# Check permissions for showing subprojects
set current_user_id [ad_get_user_id]
set perm_sql "
    (select p.*
      from    im_projects p,
              acs_rels r
      where   r.object_id_one = p.project_id
      and r.object_id_two = :current_user_id
    )
"

if {[im_permission $current_user_id "view_projects_all"]} {
        set perm_sql "im_projects" 
}


# Get the tasks
set task_ids_sql [im_project_subproject_ids -project_id $project_id -type "task" -sql]
set project_ids_sql [im_project_subproject_ids -project_id $project_id -sql]

# get the logged hours per cost center
set logged_hours_total [db_string logged_hours "
	select sum(hours) 
			from im_hours h
			where h.project_id in ($project_ids_sql,$task_ids_sql)
" -default 0]

db_1row hours "select coalesce(sum(remaining_hours),0) as remaining_hours_total,
       coalesce(sum(planned_units),0) as planned 
    from (select planned_units,
            (planned_units * (100-coalesce(percent_completed,0)) / 100) as remaining_hours
          from im_projects p, 
            im_timesheet_tasks t 
	  where   p.parent_id in ($project_ids_sql) and t.task_id = p.project_id) as hours 
"

# Get the budgeted_hours
set hour_ids [db_list hours {select item_id from cr_items where parent_id = :budget_id and content_type = 'im_budget_hour'}]
set budgeted_hours 0
foreach item_id $hour_ids {
    set Hour [::im::dynfield::CrClass::im_budget_hour get_instance_from_db -item_id $item_id]            
    incr budgeted_hours [$Hour hours]
}

# We reduce the budgeted_hours if they are already showing up in the
# planned tasks.
set budgeted_hours [expr $budgeted_hours - $planned]

set logged_hours_total [im_timesheet_hours_sum -project_id $project_id]
set remaining_budget_hours [expr $project_budget_hours - $logged_hours_total - $remaining_hours_total - $budgeted_hours]

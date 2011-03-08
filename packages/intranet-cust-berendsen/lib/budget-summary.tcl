ad_page_contract {
    It displays budget information
} { 
    {-project_id ""}
}




# ----------------- 1 Table Budget Costs HTML
set budget_cost_html "
    <table with=\"100%\">                                                                                                                                
      <tr class=rowtitle>                                                                                                                                
        <td class=rowtitle colspan=2 align=center>[_ intranet-budget.Budget]</td>"

db_1row select_project_budget_info {
    select project_budget, project_budget_hours, project_budget_currency, percent_completed 
    from im_projects 
    where project_id = :project_id
} -column_array project_budget_info

# Default Currency                                                                                                                                       
#set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set default_currency $project_budget_info(project_budget_currency)

array set subtotals [im_cost_update_project_cost_cache $project_id]
ns_log Notice "[parray subtotals]"

append budget_cost_html "</tr>\n<tr>\n<td>[_ intranet-core.Project_Budget]</td>\n"
set project_budget $project_budget_info(project_budget)
append budget_cost_html "<td align=right>+ $project_budget $default_currency</td>\n"

append budget_cost_html "</tr>\n<tr>\n<td>[_ intranet-cost.Provider_Bills]</td>\n"
set provider_bills $subtotals([im_cost_type_bill])
append budget_cost_html "<td align=right>- $provider_bills $default_currency</td>\n"

append budget_cost_html "</tr>\n<tr>\n<td>[_ intranet-cost.Purchase_Orders]</td>\n"
set purchase_orders $subtotals([im_cost_type_po])
append budget_cost_html "<td align=right>- $purchase_orders $default_currency</td>\n"

append budget_cost_html "</tr>\n<tr>\n<td>[_ intranet-budget.Cost_Estimates]</td>\n"

if {[exists_and_not_null subtotals([im_cost_type_estimation])]} {
    set cost_estimates $subtotals([im_cost_type_estimation])
} else {
    set cost_estimates 0
}

#set cost_estimates 0
append budget_cost_html "<td align=right>- $cost_estimates $default_currency</td>\n"


set remaining_budget [expr $project_budget - $provider_bills - $purchase_orders - $cost_estimates]
append budget_cost_html "</tr>\n<tr>\n<td><b>[_ intranet-budget.Remaining_Budget]</b></td>\n"
append budget_cost_html "<td align=right><b>$remaining_budget $default_currency</b></td>\n"
append budget_cost_html "</tr>\n</table>\n"






# ----------------- 2. Table Logged Hours HTML

set project_budget_hours $project_budget_info(project_budget_hours)

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


# get the project list
set project_ids_sql [im_project_subproject_ids -project_id $project_id -project_type_ids 10000037 -sql]

# Get the tasks
set task_ids_sql [im_project_subproject_ids -project_id $project_id -project_type_ids 10000037 -type "task" -sql]


# get the logged hours per cost center
set logged_hours_total [db_string logged_hours "
	select sum(hours) 
			from im_hours h
			where h.project_id in ($project_ids_sql,$task_ids_sql)
" -default 0]

db_1row hours "select coalesce(sum(remaining_hours),0) as remaining_hours_total,
       coalesce(sum(planned_units),0) as planned 
    from (select planned_units,
            (planned_units * (100-percent_completed) / 100) as remaining_hours
          from im_projects p, 
            im_timesheet_tasks t 
	  where   p.parent_id in ($project_ids_sql) and t.task_id = p.project_id) as hours 
"

set remaining_budget_hours [expr $project_budget_hours - $logged_hours_total - $remaining_hours_total]

ad_library {
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
}

namespace eval im_cust_berendsen {}

ad_proc -private im_cust_berendsen::package_install {} {} {
# Do nothing
}

ad_proc -private im_cust_berendsen::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    After upgrade callback for intranet-cust-berendsen
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            0.3d1 0.3d2 {
                # Delete old projects
                set del_project_ids [db_list projects "select project_id from im_projects  where project_status_id = 10000042 order by tree_sortkey asc"]
                # First delete the responses
                db_dml delete "delete from survsimp_responses where related_object_id in ([template::util::tcl_to_sql_list $del_project_ids])"
                foreach project_id $del_project_ids {
                    ns_log Notice "<li>Nuking project \#$project_id ...<br>\n"
                    set error [im_project_nuke $project_id]
                    if {"" == $error} {
                        ns_log Notice "... successful\n"
                    } else {
                        ns_log Notice "<font color=red>$error</font>\n"
                    }
                }
            }
            0.3d2 0.3d3 {
                # Upgrade the projects to make use of intranet-budget
                
                # Create the budgets. One per project for the time being
                db_foreach project_info "select *, im_name_from_id(project_id) as project_name from im_projects" {
                    
                    # Try if we have a budget already (just in case)
                    set budget_id [content::item::get_id_by_name -name "budget_${project_id}" -parent_id $project_id]
                    
                    if {$budget_id eq ""} {
                        set budget [::im::dynfield::CrClass::im_budget create $project_id \
                                        -parent_id $project_id -name "budget_${project_id}" -title "Budget für $project_name" \
                                        -budget_hours $project_budget_hours -budget_hours_explanation "$project_budget_hours_explanation" \
                                        -economic_gain "$economic_gain" -economic_gain_explanation "$economic_gain_explanation" \
                                        -budget "$project_budget" -single_costs "$single_costs" -single_costs_explanation "$single_costs_explanation" \
                                        -investment_costs "$investment_cost" -investment_costs_explanation "$investment_cost_explanation" \
                                        -annual_costs "$annual_costs" -annual_costs_explanation "$annual_costs_explanation"                                   
                                   ]
                        $budget save_new
                    }
                }
                
                # Get the Costs
                db_foreach invoice_item "select item_name, item_id, item_units*price_per_unit as amount, project_id, invoice_id, item_material_id 
                                         from im_invoice_items where item_material_id  is not null and project_id is not null" {
                    set budget_id [content::item::get_id_by_name -name "budget_${project_id}" -parent_id $project_id]
                    switch $item_material_id {
                        33361 {set type_id 3751}
                        33362 {set type_id 3753}
                        33359 {set type_id 3752}
                    }
                    
                    if {$budget_id ne ""} {
                        set budget_item [::im::dynfield::CrClass::im_budget_cost create $item_id -parent_id $budget_id -name "budget_costs_${item_id}" -title "$item_name" \
                                             -amount "$amount" -type_id $type_id]
                        $budget_item save_new
                    } else {
                        ds_comment "error::: $item_id"
                    } 
                    
                }
                
                # Get the hours
                db_foreach budgets "select item_id as budget_id, parent_id as project_id from cr_items where content_type  = 'im_budget'" {
                    # Get the tasks
                    db_foreach task "select cost_center_id as department_id, task_id, planned_units, project_name 
                                     from im_timesheet_tasks, im_projects where project_id = task_id and parent_id = :project_id" {
                                         set budget_item [::im::dynfield::CrClass::im_budget_hour create $task_id -parent_id $budget_id \
                                                              -name "budget_hours_${task_id}" -title "$project_name" -hours "$planned_units" \
                                                              -department_id $department_id]
                        $budget_item save_new
                    }
                }
            }
        }
}
ad_page_contract {
    
    This is the handler for both retrieving as well as storing the data from the budget table
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-03-15
    @cvs-id $Id$
} {
    {action "get_costs"}
    budget_id:integer
    {item_id ""}
    {amount ""}
    {title ""}
    {type_id ""}
    {hours ""}
    {department_id ""}
    {budget "0"}
    {budget_hours "0"}
    {budget_hours_explanation:html ""}
    {economic_gain "0"}
    {economic_gain_explanation:html ""}
    {single_costs "0"}
    {single_costs_explanation:html ""}
    {annual_costs "0"}
    {annual_costs_explanation:html ""}
    {investment_costs "0"}
    {investment_costs_explanation:html ""}
} -properties {
} -validate {
} -errors {
}
ns_log Notice "BUDGET ACTION $action"
switch $action {
    get_budget {

        # Return the budget as a json        
        if {![exists_and_not_null budget_id]} {
            ad_return_error "Missing budget_id" "You need to provide a budget_id if you want to get the budget with get_budget"
        }

        set json_lists [list]

        # Get the data from the database
        set revision_id [db_string revision_id {select latest_revision from cr_items where item_id = :budget_id}]
        set vars [list budget budget_hours budget_hours_explanation economic_gain economic_gain_explanation single_costs single_costs_explanation annual_costs annual_costs_explanation investment_costs investment_costs_explanation item_id approved_p]
        
        db_1row budget_info "select object_title as title, [join $vars ","] from im_budgetsx where budget_id = :revision_id"
        lappend vars title

        # Set the json
        set json_list [list]
        foreach var $vars {
            lappend json_list $var
            lappend json_list [set $var]
        }
        regsub -all {\"} $json_list {\\\"} json_list        
        set json [util::json::gen [util::json::object::create [list success true data [util::json::object::create $json_list]]]]
        ns_return 200 text/text $json
        
    }
    get_live_budget {

        # Return the budget as a json        
        if {![exists_and_not_null budget_id]} {
            ad_return_error "Missing budget_id" "You need to provide a budget_id if you want to get the budget with get_budget"
        }

        set json_lists [list]

        # Get the data from the database
        set revision_id [db_string revision_id {select live_revision from cr_items where item_id = :budget_id}]
        set vars [list budget budget_hours budget_hours_explanation economic_gain economic_gain_explanation single_costs single_costs_explanation annual_costs annual_costs_explanation investment_costs investment_costs_explanation item_id approved_p]
        
        db_1row budget_info "select object_title as title, [join $vars ","] from im_budgetsx where budget_id = :revision_id"
        lappend vars title

        # Set the json
        set json_list [list]
        foreach var $vars {
            lappend json_list $var
            lappend json_list [set $var]
        }
        regsub -all {\"} $json_list {\\\"} json_list        
        set json [util::json::gen [util::json::object::create [list success true data [util::json::object::create $json_list]]]]
        ns_return 200 text/text $json
    }
    get_calculated_budget {

        # Return the budget as a json        
        if {![exists_and_not_null budget_id]} {
            ad_return_error "Missing budget_id" "You need to provide a budget_id if you want to get the budget with get_budget"
        }

        set json_lists [list]

        # Get the data from the database
        set revision_id [db_string revision_id {select live_revision from cr_items where item_id = :budget_id}]
        set vars [list budget budget_hours budget_hours_explanation economic_gain economic_gain_explanation single_costs single_costs_explanation annual_costs annual_costs_explanation investment_costs investment_costs_explanation item_id approved_p]
        
        db_1row budget_info "select object_title as title, [join $vars ","] from im_budgetsx where budget_id = :revision_id"

        set budget_hours [db_string get_hours "select coalesce(sum(b.hours),0) as budget_hours from im_budget_hours b, cr_items ci where parent_id = :budget_id and latest_revision = hour_id"]
        set investment_costs [db_string get_costs "select coalesce(sum(amount),0) as investment_costs from im_budget_costs, cr_items ci where parent_id = :budget_id and latest_revision = cost_id and type_id = 3751"]
        set single_costs [db_string get_costs "select coalesce(sum(amount),0) as single_costs from im_budget_costs, cr_items ci where parent_id = :budget_id and latest_revision = cost_id and type_id = 3752"]
        set annual_costs [db_string get_costs "select coalesce(sum(amount),0) as annual_costs from im_budget_costs, cr_items ci where parent_id = :budget_id and latest_revision = cost_id and type_id = 3753"]
        set economic_gain [db_string get_hours "select coalesce(sum(b.amount),0) as economic_gain from im_budget_benefits b, cr_items ci where parent_id = :budget_id and latest_revision = benefit_id"]
        set budget [db_string get_costs "select coalesce(sum(amount),0) as budget from im_budget_costs, cr_items ci where parent_id = :budget_id and latest_revision = cost_id and type_id in (3751,3752)"]

        # Set the json
        lappend vars title
        set json_list [list]
        foreach var $vars {
            lappend json_list $var
            lappend json_list [set $var]
        }
        regsub -all {\"} $json_list {\\\"} json_list        
        set json [util::json::gen [util::json::object::create [list success true data [util::json::object::create $json_list]]]]
        ns_return 200 text/text $json
    }
    save_budget {
        ns_log Notice "SAVING BUDGET"
        content::revision::new -item_id $budget_id \
            -attributes [list \
                             [list budget $budget] \
                             [list budget_hours $budget_hours] \
                             [list budget_hours_explanation $budget_hours_explanation] \
                             [list economic_gain $economic_gain] \
                             [list economic_gain_explanation $economic_gain_explanation] \
                             [list single_costs $single_costs] \
                             [list single_costs_explanation $single_costs_explanation] \
                             [list investment_costs $investment_costs] \
                             [list investment_costs_explanation $investment_costs_explanation] \
                             [list annual_costs $annual_costs] \
                             [list annual_costs_explanation $annual_costs_explanation] \
                        ] \
            -title $title            

        # Update the project information
        db_dml update_project "update im_projects set project_budget = $budget, project_budget_hours = $budget_hours where project_id = (select parent_id from cr_items where item_id = :item_id)"

        set json [util::json::gen [util::json::object::create [list success true]]]
        ns_return 200 text/text $json
    }        
    approve_budget {
        # Publish the budget and all associated items. A published
        # budget is an approved one.

        item::publish -item_id $budget_id
        db_dml set_approved_p "update im_budgets set approved_p = 't' where budget_id = (select live_revision from cr_items where item_id = :budget_id)"

        set cost_ids [db_list costs {select item_id from cr_items where parent_id = :budget_id and content_type = 'im_budget_cost'}]
        foreach item_id $cost_ids {
            item::publish -item_id $item_id
            db_dml set_approved_p "update im_budget_costs set approved_p = 't' where cost_id = (select live_revision from cr_items where item_id = :item_id)"
        }

        set benefit_ids [db_list benefits {select item_id from cr_items where parent_id = :budget_id and content_type = 'im_budget_benefit'}]
        foreach item_id $benefit_ids {
            item::publish -item_id $item_id
            db_dml set_approved_p "update im_budget_benefits set approved_p = 't' where benefit_id = (select live_revision from cr_items where item_id = :item_id)"
        }

        set hour_ids [db_list hours {select item_id from cr_items where parent_id = :budget_id and content_type = 'im_budget_hour'}]
        foreach item_id $hour_ids {
            item::publish -item_id $item_id
            db_dml set_approved_p "update im_budget_hours set approved_p = 't' where hour_id = (select live_revision from cr_items where item_id = :item_id)"
        }

        
        set json [util::json::gen [util::json::object::create [list success true]]]

        ns_return 200 text/text $json

    }        
    get_costs {
        if {![exists_and_not_null budget_id]} {
            ad_return_error "Missing budget_id" "You need to provide a budget_id if you want to get the budget with get_budget"
        }
        
        set json_lists [list]
        set counter 0
        
        # Get the data from the database
        set cost_revision_ids [db_list costs {select latest_revision from cr_items where parent_id = :budget_id and content_type = 'im_budget_cost'}]
        
        foreach revision_id $cost_revision_ids {
            incr counter
            db_1row cost_info "select object_title as title, type_id, cost_id, amount, item_id, approved_p from im_budget_costsx where cost_id = :revision_id"

            # Set the json
            set json_list [list]
            foreach var [list cost_id amount approved_p title item_id type_id] {
                lappend json_list $var
                lappend json_list [set $var]
            }
            # Make sure we have no " " " unescaped
            regsub -all {\"} $json_list {\\\"} json_list
            lappend json_lists [util::json::object::create $json_list]
        }

        # Generate the array of items
        set json_array(results) $counter
        set json_array(items) [util::json::array::create $json_lists]
        ns_return 200 text/text [util::json::gen [util::json::object::create [array get json_array]]]
    }
    save_costs {
        if {$item_id ne ""} {
            content::revision::new -item_id $item_id -attributes [list [list amount $amount] [list approved_p "f"] [list type_id $type_id]] -title $title            

            # Return success if it worked
            ns_return 200 text/text "1"
        } else {
            
            # We have a new entry, so let's instantiate the object,
            # but only if we have a budget_id
            if {![exists_and_not_null budget_id]} {
                ns_return 200 text/text "0"
            } else {
                content::item::new -parent_id $budget_id -attributes [list [list amount $amount] [list type_id $type_id] [list approved_p "f"]] -title $title -name "$title" -content_type "im_budget_cost"
                ns_return 200 text/text "1"
            }
        }
        
    }
    get_benefits {
        if {![exists_and_not_null budget_id]} {
            ad_return_error "Missing budget_id" "You need to provide a budget_id if you want to get the budget with get_budget"
        }

        set json_lists [list]
        set counter 0
        
        # Get the data from the database
        set benefit_revision_ids [db_list benefits {select latest_revision from cr_items where parent_id = :budget_id and content_type = 'im_budget_benefit'}]
        
        foreach revision_id $benefit_revision_ids {
            incr counter
            db_1row benefit_info "select object_title as title, benefit_id, amount, item_id, approved_p from im_budget_benefitsx where benefit_id = :revision_id"

            # Set the json
            set json_list [list]
            foreach var [list benefit_id amount approved_p title item_id] {
                lappend json_list $var
                lappend json_list [set $var]
            }
            # Make sure we have no " " " unescaped
            regsub -all {\"} $json_list {\\\"} json_list
            lappend json_lists [util::json::object::create $json_list]
        }

        # Generate the array of items
        set json_array(results) $counter
        set json_array(items) [util::json::array::create $json_lists]
        ns_return 200 text/text [util::json::gen [util::json::object::create [array get json_array]]]
    }
    save_benefits {
        if {$item_id ne ""} {
            content::revision::new -item_id $item_id -attributes [list [list amount $amount] [list approved_p "f"]] -title $title            

            # Return success if it worked
            ns_return 200 text/text "1"
        } else {
            
            # We have a new entry, so let's instantiate the object,
            # but only if we have a budget_id
            if {![exists_and_not_null budget_id]} {
                ns_return 200 text/text "0"
            } else {
                content::item::new -parent_id $budget_id -attributes [list [list amount $amount] [list approved_p "f"]] -title $title -name "$title" -content_type "im_budget_benefit"
                ns_return 200 text/text "1"
            }
        }
        
    }
    get_hours {
        if {![exists_and_not_null budget_id]} {
            ad_return_error "Missing budget_id" "You need to provide a budget_id if you want to get the budget with get_budget"
        }
        
        set json_lists [list]
        set counter 0
 
        # Get the data from the database
        set hour_revision_ids [db_list hours {select latest_revision from cr_items where parent_id = :budget_id and content_type = 'im_budget_hour'}]
        
        foreach revision_id $hour_revision_ids {
            incr counter
            db_1row hour_info "select object_title as title, hour_id, department_id, hours, item_id, approved_p from im_budget_hoursx where hour_id = :revision_id"

            # Set the json
            set json_list [list]
            foreach var [list hour_id department_id hours approved_p title item_id] {
                lappend json_list $var
                lappend json_list [set $var]
            }
            # Make sure we have no " " " unescaped
            regsub -all {\"} $json_list {\\\"} json_list
            lappend json_lists [util::json::object::create $json_list]
        }

        # Generate the array of items
        set json_array(results) $counter
        set json_array(items) [util::json::array::create $json_lists]
        ns_return 200 text/text [util::json::gen [util::json::object::create [array get json_array]]]
    }
    save_hours {
        if {$item_id ne ""} {
            
            content::revision::new -item_id $item_id -attributes [list [list hours $hours] [list department_id $department_id] [list approved_p "f"]] -title $title

            # Return success if it worked
            ns_return 200 text/text "1"
        } else {

            # We have a new entry, so let's instantiate the object,
            # but only if we have a budget_id
            if {![exists_and_not_null budget_id]} {
                ns_return 200 text/text "0"
            } else {
                content::item::new -parent_id $budget_id -attributes [list [list hours $hours] [list department_id $department_id] [list approved_p "f"]] -title $title -name "$title" -content_type "im_budget_hour"
                ns_return 200 text/text "1"
            }
        }
    }
    default {
    }
}

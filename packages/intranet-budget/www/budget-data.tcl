# 

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
    {cost_type_id ""}
    {hours ""}
    {department_id ""}
} -properties {
} -validate {
} -errors {
}

switch $action {
    get_budget {
        # Return the budget as a json
        
        if {![exists_and_not_null budget_id]} {
            ad_return_error "Missing budget_id" "You need to provide a budget_id if you want to get the budget with get_budget"
        }
        
        content::item::get -item_id $budget_id -array_name budget
        set json [util::json::gen [util::json::object::create [array get budget]]]
        ns_return 200 text/text $json
    }
    get_costs {
        if {![exists_and_not_null budget_id]} {
            ad_return_error "Missing budget_id" "You need to provide a budget_id if you want to get the budget with get_budget"
        }
        
        set json_lists [list]
        set counter 0

        # Get the data from the database
        set cost_ids [db_list costs {select item_id from cr_items where parent_id = :budget_id and content_type = '::im_budget::BudgetCosts'}]
        
        foreach item_id $cost_ids {
            incr counter
            set Cost [::im_budget::BudgetCosts get_instance_from_db -item_id $item_id]            
            # Append one entry to the json_lists for the array
            lappend json_lists [util::json::object::create [subst \
                                                                {item_id "$item_id"
                                                                    title "[$Cost title]"
                                                                    amount "[$Cost amount]"
                                                                    cost_type_id "[$Cost cost_type_id]"}
                                                           ]
                                                ]
        }
        
        # Generate the array of items
        set json_array(results) $counter
        set json_array(items) [util::json::array::create $json_lists]
        ns_return 200 text/text [util::json::gen [util::json::object::create [array get json_array]]]
    }
    save_costs {
        if {$item_id ne ""} {
            
            # We are editing a cost row, because we have an item_id,
            # first get the Cost object for the row
            set Cost [::im_budget::BudgetCosts get_instance_from_db -item_id $item_id]

            # Now update the fields
            $Cost set title $title
            $Cost set amount $amount
            $Cost set cost_type_id $cost_type_id

            # Save and destro
            $Cost save
            $Cost destroy

            # Return success if it worked
            ns_return 200 text/text "1"
        } else {
            
            # We have a new entry, so let's instantiate the object,
            # but only if we have a budget_id
            if {![exists_and_not_null budget_id]} {
                ns_return 200 text/text "0"
            } else {

                set Cost [::im_budget::BudgetCosts create cost \
                              -parent_id $budget_id \
                              -title $title \
                              -amount $amount \
                              -cost_type_id $cost_type_id]
                
                $Cost save_new
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
        set hour_ids [db_list hours {select item_id from cr_items where parent_id = :budget_id and content_type = '::im_budget::BudgetHours'}]
        
        foreach item_id $hour_ids {
            incr counter
            set Hour [::im_budget::BudgetHours get_instance_from_db -item_id $item_id]            
            # Append one entry to the json_lists for the array
            lappend json_lists [util::json::object::create [subst \
                                                                {item_id "$item_id"
                                                                    title "[$Hour title]"
                                                                    hours "[$Hour hours]"
                                                                    department_id "[$Hour department_id]"}
                                                           ]
                                                ]
        }
        
        # Generate the array of items
        set json_array(results) $counter
        set json_array(items) [util::json::array::create $json_lists]
        ns_return 200 text/text [util::json::gen [util::json::object::create [array get json_array]]]
    }
    save_hours {
        if {$item_id ne ""} {
            
            # We are editing a cost row, because we have an item_id,
            # first get the Hour object for the row
            set Hour [::im_budget::BudgetHours get_instance_from_db -item_id $item_id]

            # Now update the fields
            $Hour set title $$title
            $Hour set hours $hours
            $Hour set department_id $department_id

            # Save and destro
            $Hour save
            $Hour destroy

            # Return success if it worked
            ns_return 200 text/text "1"
        } else {
            
            # We have a new entry, so let's instantiate the object,
            # but only if we have a budget_id
            if {![exists_and_not_null budget_id]} {
                ns_return 200 text/text "0"
            } else {

                set Hour [::im_budget::BudgetHours create cost \
                              -parent_id $budget_id \
                              -title $title \
                              -hours $hours \
                              -department_id $department_id]
                
                $Hour save_new
                ns_return 200 text/text "1"
            }
        }
        
    }
    default {
    }
}

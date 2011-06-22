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
    {type_id ""}
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
        
        set Budget [::im::dynfield::CrClass::im_budget get_instance_from_db -item_id $budget_id]
        set json [util::json::gen [util::json::object::create [list success true data [$Budget json_object]]]]
        ns_return 200 text/text $json
    }
    get_live_budget {

        # Return the budget as a json        
        if {![exists_and_not_null budget_id]} {
            ad_return_error "Missing budget_id" "You need to provide a budget_id if you want to get the budget with get_budget"
        }
        
        set revision_id [content::item::get_live_revision -item_id $budget_id]
        set Budget [::im::dynfield::CrClass::im_budget get_instance_from_db -revision_id $revision_id]
        set json [util::json::gen [util::json::object::create [list success true data [$Budget json_object]]]]
        ns_return 200 text/text $json
    }
    get_calculated_budget {

        # Return the budget as a json        
        if {![exists_and_not_null budget_id]} {
            ad_return_error "Missing budget_id" "You need to provide a budget_id if you want to get the budget with get_budget"
        }
        
        set Budget [::im::dynfield::CrClass::im_budget get_instance_from_db -item_id $budget_id]

        # Now we overwrite what is in the database with the calculated
        # figures from the costs, benefits and hours. This allows us
        # to differentiate between the saved value (which you get with
        # get_budget) and what should the value be (based on the sum)
        $Budget set budget_hours [db_string get_hours "select sum(b.hours) from im_budget_hours b, cr_items ci where parent_id = :budget_id and latest_revision = hour_id"]
        $Budget set investment_costs [db_string get_costs "select sum(amount) from im_budget_costs, cr_items ci where parent_id = :budget_id and latest_revision = fund_id and type_id = 3751"]
        $Budget set single_costs [db_string get_costs "select sum(amount) from im_budget_costs, cr_items ci where parent_id = :budget_id and latest_revision = fund_id and type_id = 3752"]
        $Budget set annual_costs [db_string get_costs "select sum(amount) from im_budget_costs, cr_items ci where parent_id = :budget_id and latest_revision = fund_id and type_id = 3753"]
        $Budget set economic_gain [db_string get_hours "select sum(b.amount) from im_budget_benefits b, cr_items ci where parent_id = :budget_id and latest_revision = fund_id"]
        $Budget set budget [db_string get_costs "select sum(amount) from im_budget_costs, cr_items ci where parent_id = :budget_id and latest_revision = fund_id and type_id in (3751,3752)"]
        set json [util::json::gen [util::json::object::create [list success true data [$Budget json_object]]]]
        ns_return 200 text/text $json
    }
    save_budget {
        
        # Get the budget from the database
        set Budget [::im::dynfield::CrClass::im_budget get_instance_from_db -item_id $budget_id]
        
        $Budget update_from_form
        $Budget approved_p "f"
        $Budget save -live_p false

        # Update the project information
        db_dml update_project "update im_projects set project_budget = [$Budget budget], project_budget_hours = [$Budget budget_hours] where project_id = [$Budget parent_id]"
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
            db_dml set_approved_p "update im_budget_costs set approved_p = 't' where fund_id = (select live_revision from cr_items where item_id = :item_id)"
        }

        set benefit_ids [db_list benefits {select item_id from cr_items where parent_id = :budget_id and content_type = 'im_budget_benefit'}]
        foreach item_id $benefit_ids {
            item::publish -item_id $item_id
            db_dml set_approved_p "update im_budget_benefits set approved_p = 't' where fund_id = (select live_revision from cr_items where item_id = :item_id)"
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
        set cost_ids [db_list costs {select item_id from cr_items where parent_id = :budget_id and content_type = 'im_budget_cost'}]
        
        foreach item_id $cost_ids {
            incr counter
            set Cost [::im::dynfield::CrClass::im_budget_cost get_instance_from_db -item_id $item_id]            
            # Append one entry to the json_lists for the array
            lappend json_lists [$Cost json_object]
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
            set Cost [::im::dynfield::CrClass::im_budget_cost get_instance_from_db -item_id $item_id]

            # Now update the fields
            $Cost set title $title
            $Cost set amount $amount
            $Cost set type_id $type_id
            $Cost set approved_p "f"

            # Save and destro
            $Cost save -live_p false
            $Cost destroy

            # Return success if it worked
            ns_return 200 text/text "1"
        } else {
            
            # We have a new entry, so let's instantiate the object,
            # but only if we have a budget_id
            if {![exists_and_not_null budget_id]} {
                ns_return 200 text/text "0"
            } else {

                set Cost [::im::dynfield::CrClass::im_budget_cost create cost \
                              -parent_id $budget_id \
                              -title $title \
                              -amount $amount \
                              -type_id $type_id]
                
                $Cost save_new -live_p false
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
        set benefit_ids [db_list benefits {select item_id from cr_items where parent_id = :budget_id and content_type = 'im_budget_benefit'}]
        
        foreach item_id $benefit_ids {
            incr counter
            set Benefit [::im::dynfield::CrClass::im_budget_benefit get_instance_from_db -item_id $item_id]            
            # Append one entry to the json_lists for the array
            lappend json_lists [$Benefit json_object]
        }
        
        # Generate the array of items
        set json_array(results) $counter
        set json_array(items) [util::json::array::create $json_lists]
        ns_return 200 text/text [util::json::gen [util::json::object::create [array get json_array]]]
    }
    save_benefits {
        if {$item_id ne ""} {
            
            # We are editing a benefit row, because we have an item_id,
            # first get the Benefit object for the row
            set Benefit [::im::dynfield::CrClass::im_budget_benefit get_instance_from_db -item_id $item_id]
            ns_log Notice "[$Benefit serialize]"
            ns_log Notice "Amount :: $amount"
            # Now update the fields
            $Benefit set title $title
            $Benefit set amount $amount
            $Benefit set approved_p "f"

            # Save and destro
            $Benefit save -live_p false
            $Benefit destroy

            # Return success if it worked
            ns_return 200 text/text "1"
        } else {
            
            # We have a new entry, so let's instantiate the object,
            # but only if we have a budget_id
            if {![exists_and_not_null budget_id]} {
                ns_return 200 text/text "0"
            } else {

                set Benefit [::im::dynfield::CrClass::im_budget_benefit create benefit \
                              -parent_id $budget_id \
                              -title $title \
                              -amount $amount \
                              -type_id $type_id]
                
                $Benefit save_new -live_p false
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
        set hour_ids [db_list hours {select item_id from cr_items where parent_id = :budget_id and content_type = 'im_budget_hour'}]
        
        foreach item_id $hour_ids {
            incr counter
            set Hour [::im::dynfield::CrClass::im_budget_hour get_instance_from_db -item_id $item_id]            
            lappend json_lists [$Hour json_object]
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
            set Hour [::im::dynfield::CrClass::im_budget_hour get_instance_from_db -item_id $item_id]

            # Now update the fields
            $Hour set title $title
            $Hour set hours $hours
            $Hour set department_id $department_id
            $Hour set approved_p "f"

            # Save and destro
            $Hour save -live_p false
            $Hour destroy

            # Return success if it worked
            ns_return 200 text/text "1"
        } else {
            
            # We have a new entry, so let's instantiate the object,
            # but only if we have a budget_id
            if {![exists_and_not_null budget_id]} {
                ns_return 200 text/text "0"
            } else {

                set Hour [::im::dynfield::CrClass::im_budget_hour create cost \
                              -parent_id $budget_id \
                              -title $title \
                              -hours $hours \
                              -department_id $department_id]
                
                $Hour save_new -live_p false
                ns_return 200 text/text "1"
            }
        }
        
    }
    default {
    }
}

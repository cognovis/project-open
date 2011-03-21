set optional_param_list [list customer_id supplier_id]
foreach optional_param $optional_param_list {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

# We are going to get a list of all members of the group Freelancer
# that have worked in a project for customer_id (party_id in this case).
# So first we get all projects were the party_id is customer

set project_list [db_list get_projects { select item_id from pm_projectsx where customer_id = :customer_id }]

if {![empty_string_p $project_list]} {
    # Now we search for all the members of the Freelancer
    # group that are assigned to one of this projects.
    
    # Get the group members list
    set group_id [group::get_id -group_name "Freelancer"]
    set group_members_list [group::get_members -group_id $group_id]
    # Now we create the select menu to use
    if {![empty_string_p $group_members_list]} {
	set select_menu "<select name=\"supplier_id\">"
	append select_menu "<option value=\"-100\" selected> - - - - - -</option>"
	
	db_foreach get_members {  } {
	    append select_menu "<option value=\"$supplier_id\">[contact::name -party_id $supplier_id]</option>"
	}
	append select_menu "</select>"
    } else {
	set select_menu ""
    }
} else {
    set select_menu ""
}

set portlet_layout [parameter::get -parameter "DefaultPortletLayout"]
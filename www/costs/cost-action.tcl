# /packages/intranet-costs/www/cost-action.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Purpose: Takes commands from the /intranet-cost/index
    page and deletes costs where marked

    @param return_url the url to return to
    @param group_id group id
    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet-costs/" }
    del_cost:multiple,optional
    cost_status:array,optional
    submit
}

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id add_costs]} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}

set task_status_delivered [db_string task_status_delivered "select task_status_id from im_task_status where upper(task_status)='DELIVERED'"]
set project_status_delivered [db_string project_status_delivered "select project_status_id from im_project_status where upper(project_status)='DELIVERED'"]

ns_log Notice "cost-action: submit=$submit"
switch $submit {

    "Save" {
	# Save the stati for the costs on this list
	foreach cost_id [array names cost_status] {
	    set cost_status_id $cost_status($cost_id)
	    ns_log Notice "set cost_status($cost_id) = $cost_status_id"

	    db_dml update_cost_status "update im_costs set cost_status_id=:cost_status_id where cost_id=:cost_id"
	}

	ad_returnredirect $return_url
	return
    }

    "Del" {
	# "Del" button pressed: delete the marked costs:
	#	- Mark the associated im_trans_tasks as "delivered"
	#	  and reset their cost_id (to be able to
	#	  delete the cost).
	#	- Delete the associated im_cost_items
	#	- Delete from project-cost-map
	#       - Deleter underlying im_cost item
	#
	set in_clause_list [list]

	# Maybe the list of costs was empty...
	if {![info exists del_cost]} { 
	    ad_returnredirect $return_url
	    return
	}

	foreach cost_id $del_cost {
	    lappend in_clause_list $cost_id
	}
	set cost_where_list "([join $in_clause_list ","])"

	set delete_cost_items_sql "
		delete from im_cost_items i
		where i.cost_id in $cost_where_list
	"

	# Reset the status of all project to "delivered" that
	# were included in the cost
	set reset_projects_included_sql "
		update im_projects
		set project_status_id=:project_status_delivered
		where project_id in (
			select distinct
				r.object_id_one
			from
				acs_rels r
			where
				r.object_id_two in $cost_where_list
		)
	"

	# Set all projects back to "delivered" that have tasks
	# that were included in the costs to delete.
	set reset_projects_with_tasks_sql "
		update im_projects
		set project_status_id=:project_status_delivered
		where project_id in (
			select distinct
				t.project_id
			from
				im_trans_tasks t
			where
				t.cost_id in $cost_where_list
		)
	"

	# Reset the status of all costd tasks to delivered.
	set reset_tasks_sql "
		update im_trans_tasks t
		set cost_id=null
		where t.cost_id in $cost_where_list
	"

	set delete_map_sql "
		delete from acs_rels r
		where r.object_id_two in $cost_where_list
	"

	set delete_costs_sql "
	begin
		for row in (
			select cost_id
			from	im_costs
			where	cost_id in $cost_where_list
		) loop
			im_cost.del(row.cost_id);
		end loop;
	end;
	"

	db_transaction {
	    # Changing project state back to "delivered" and 
	    # changing im_trans_tasks to not-cost only for translation...
	    if {[db_table_exists "im_trans_tasks"]} {
		db_dml reset_projects_with_tasks $reset_projects_with_tasks_sql
		db_dml reset_tasks $reset_tasks_sql
	    }

	    db_dml reset_projects_included $reset_projects_included_sql
	    db_dml delete_cost_items $delete_cost_items_sql
	    db_dml delete_map $delete_map_sql
	    db_dml delete_costs $delete_costs_sql
	}

	ad_returnredirect $return_url
	return
    }

    default {
	set error "Unknown submit command: '$submit'"
	ad_returnredirect "/error?error=$error"
    }
}


ad_page_contract {
    Fifth stage of simple process wizard.
    Create the workflow in the DB.

    @author Matthew Burke (mburke@arsdigita.com)
    @author Lars Pind (lars@pinds.com)
    @creation-date 29 August 2000
    @cvs-id $Id$
}

set workflow_name [ad_get_client_property wf workflow_name]
set workflow_description [ad_get_client_property wf workflow_description]
wf_wizard_massage_tasks [ad_get_client_property wf tasks] tasks task
set num_tasks [llength $tasks]

set context [list [list "" "Simple Process Wizard"] "Create"]

if { [empty_string_p $workflow_name] } {
    ad_returnredirect ""
    ad_script_abort
}

if { $num_tasks == 0 } {
    ad_returnredirect "tasks"
    ad_script_abort
}

# setup loop_attribute_name, input_place
set last_transition_key {}
foreach transition_key $tasks {

    # set the input_place_key for this task and output_place_key of the prior taks
    if { ![empty_string_p $last_transition_key] } {
	set task($transition_key,input_place_key) "before_[string range $transition_key 0 92]"
	set task($last_transition_key,output_place_key) $task($transition_key,input_place_key)
    } else {
	set task($transition_key,input_place_key) "start"
    }

    # take care of the loop: find the place_key and generate an attribute_name
    set loop_to_transition_key $task($transition_key,loop_to_transition_key)

    if { ![empty_string_p $loop_to_transition_key] } {
	# atttribute_name will become (transition_key)_(question)_p
	set task($transition_key,loop_attribute_name) "${transition_key}_[wf_name_to_key $task($transition_key,loop_question)]_p"

	# we actually loop to a place, so let's get the input place for the transition we're looping to
	# this should be already set, because we can only loop to a prior task
	set task($transition_key,loop_to_place_key) $task($loop_to_transition_key,input_place_key)
    }

    set last_transition_key $transition_key
}

set task($last_transition_key,output_place_key) "end"

set workflow_name [wf_make_unique -maxlen 100 \
	-taken_names [db_list object_pretty_names "select pretty_name from acs_object_types"] \
	$workflow_name ""]

set workflow_key [wf_make_unique -maxlen 30 \
	-taken_names [db_list object_types "select object_type from acs_object_types"] \
	[wf_name_to_key $workflow_name] "_wf"]

set workflow_cases_table [wf_make_unique -maxlen 30 \
	-taken_names [db_tables] \
	$workflow_key "_cases"]

set workflow_cases_constraint [wf_make_unique -maxlen 30 \
	-taken_names [db_list constraints "select constraint_name from user_constraints"] \
	$workflow_cases_table "_case_fk"]


db_dml create_cases_table "
create table $workflow_cases_table (
  case_id             integer primary key
                      constraint $workflow_cases_constraint
                      references wf_cases on delete cascade
)"


set error_p 0
db_transaction {

    db_exec_plsql create_workflow "
    declare
        v_workflow_key varchar(40);
    begin
        v_workflow_key := workflow.create_workflow(
            workflow_key => '[db_quote $workflow_key]',
            pretty_name => '[db_quote $workflow_name]', 
            pretty_plural => '[db_quote $workflow_name]', 
     	    description => '[db_quote $workflow_description]',
  	    table_name => '[db_quote $workflow_cases_table]'
        );
    end;
    "
    #####
    #
    # Places
    #
    #####

    foreach transition_key $tasks {
	wf_add_place \
		-workflow_key $workflow_key \
		-place_key $task($transition_key,input_place_key) \
		-place_name "Ready to $task($transition_key,task_name)" 
    }

    wf_add_place \
	    -workflow_key $workflow_key \
	    -place_key "end" \
	    -place_name "Process finished"

    #####
    #
    # Roles
    #
    #####

    # For simplicity, we just create one role per transition, with the same 
    # key and name as the transition, and match those up one-to-one

    foreach transition_key $tasks {
	wf_add_role \
		-workflow_key $workflow_key \
		-role_key $transition_key \
		-role_name $task($transition_key,task_name)
    }

    #####
    #
    # Transitions
    #
    #####

    foreach transition_key $tasks {
	wf_add_transition \
		-workflow_key $workflow_key \
		-transition_key $transition_key \
		-transition_name $task($transition_key,task_name) \
		-role_key $transition_key \
		-estimated_minutes $task($transition_key,task_time)
    }


    #####
    #
    # Arcs
    #
    #####

    foreach transition_key $tasks {
	# arc from input place 
	wf_add_arc_in \
		-workflow_key $workflow_key \
		-from_place_key $task($transition_key,input_place_key) \
		-to_transition_key $transition_key


	# arcs to output place(s)
	if { [empty_string_p $task($transition_key,loop_to_transition_key)] } {

	    # Simple: only one output arc, no guard
	    wf_add_arc_out \
		    -workflow_key $workflow_key \
		    -from_transition_key $transition_key \
		    -to_place_key $task($transition_key,output_place_key)

	} else {

	    if { [string equal $task($transition_key,loop_answer) "t"] } {
		set false_place $task($transition_key,output_place_key)
		set true_place $task($transition_key,loop_to_place_key)
	    } else {
		set true_place $task($transition_key,output_place_key)
		set false_place $task($transition_key,loop_to_place_key)
	    }
	    
	    wf_add_arc_out \
		    -workflow_key $workflow_key \
		    -from_transition_key $transition_key \
		    -to_place_key $false_place \
		    -guard_callback "#" \
		    -guard_description "Not $task($transition_key,loop_question)"

	    # Default guard to call. Depends on PG/Oracle
	    set guard_callback "wf_callback__guard_attribute_true"
	    # ToDo: replace "__" by "." for Oracle.

	    wf_add_arc_out \
		    -workflow_key $workflow_key \
		    -from_transition_key $transition_key \
		    -to_place_key $true_place \
		    -guard_callback $guard_callback \
		    -guard_custom_arg $task($transition_key,loop_attribute_name) \
		    -guard_description $task($transition_key,loop_question)
	}
    }


    #####
    # 
    # Define the attributes and transition_attribute_map
    #
    #####
    
    foreach transition_key $tasks {
	if { ![empty_string_p $task($transition_key,loop_to_transition_key)] } {

	    db_exec_plsql define_attribute "
	    declare
	        v_attribute_id acs_attributes.attribute_id%TYPE;
	    begin
	        v_attribute_id := workflow.create_attribute(
	            workflow_key => '[db_quote $workflow_key]',
	            attribute_name => '[db_quote $task($transition_key,loop_attribute_name)]',
	            datatype => 'boolean',
	            pretty_name => '[db_quote "$task($transition_key,loop_question)"]',
      	            default_value => '[ad_decode $task($transition_key,loop_answer) "t" "f" "t"]'
	        );
	    
	    end;"

	    wf_add_trans_attribute_map \
		    -workflow_key $workflow_key \
		    -transition_key $transition_key \
		    -attribute_name $task($transition_key,loop_attribute_name)

	}
    }

    
    #####
    #
    # Manual assignments
    #
    #####

    foreach transition_key $tasks {
	set assigning_transition_key $task($transition_key,assigning_transition_key)
	if { ![empty_string_p $assigning_transition_key] } {

	    wf_add_trans_role_assign_map \
		    -workflow_key $workflow_key \
		    -transition_key $assigning_transition_key \
		    -assign_role_key $transition_key

	}
    }

} on_error {
    set error_p 1
}

if { $error_p } {
    if { [db_table_exists $workflow_cases_table] } {
	db_dml drop_cases_table "drop table $workflow_cases_table"
    }

    ad_return_error "Failed creating process" "We're sorry, but we couldn't create your process."
    return
}

ad_set_client_property -persistent t wf workflow_name ""
ad_set_client_property -persistent t wf workflow_description ""
ad_set_client_property -persistent t wf tasks ""

ad_return_template

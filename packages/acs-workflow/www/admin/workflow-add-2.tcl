ad_page_contract {
    Add new process.
} {
    workflow_name:trim,notnull
    description
} -validate {
    name_unique -requires { workflow_name:notnull } {
	set num [db_string num_object_types { 
	    select decode(count(*),0,0,1) from acs_object_types where pretty_name = :workflow_name 
	}]
        if { $num > 0 } {
	    ad_complain "This name is already taken. You'll have to come up with something else. Sorry."
	}
    }
}

set workflow_key [wf_make_unique -maxlen 30 \
	-taken_names [db_list object_types "select object_type from acs_object_types"] \
	[wf_name_to_key $workflow_name] "_wf"]


set workflow_cases_table [wf_make_unique -maxlen 30 \
	-taken_names [db_tables] \
	$workflow_key "_cases"]

set workflow_cases_constraint [wf_make_unique -maxlen 30 \
	-taken_names [db_list constraints "select constraint_name from user_constraints"] \
	$workflow_cases_table "_case_fk"]


if { [catch  {
    db_dml create_cases_table "
    create table $workflow_cases_table (
    case_id             integer primary key
                        constraint $workflow_cases_constraint
                        references wf_cases
    )"
} error] } {
    ns_log Error "Problem creating new process case table: $error"
    ad_return_error "Error creating process" "We had a problem creating your new process."
    return
}

db_transaction {
    db_exec_plsql create_workflow "
    declare
        v_workflow_key varchar(40);
    begin
        v_workflow_key := workflow.create_workflow(
            workflow_key => :workflow_key,
            pretty_name => :workflow_name, 
            pretty_plural => :workflow_name, 
     	    description => :description,
  	    table_name => :workflow_cases_table
        );
    end;
    "

    db_dml start_place {
        insert into wf_places (place_key, workflow_key, place_name, sort_order)
        values ('start', :workflow_key, 'Start place', 1)
    }
    
    db_dml end_place {
        insert into wf_places (place_key, workflow_key, place_name, sort_order)
        values ('end', :workflow_key, 'End place', 999)
    }
    
} on_error {
    ns_log Error "Problem creating object type: $error"
    db_dml drop_cases_table "drop table $workflow_cases_table"
    ad_return_error "Error creating process" "We had a problem creating your new process."
    return
}



ad_returnredirect "define?[export_url_vars workflow_key]"

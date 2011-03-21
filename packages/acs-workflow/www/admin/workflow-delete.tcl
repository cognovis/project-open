ad_page_contract { 
    Delete a workflow definition from the system.

    @author Lars Pind (lars@pinds.com)
    @creation-date 28 September 2000
    @cvs-id $Id: workflow-delete.tcl,v 1.6 2010/06/09 11:20:03 po34demo Exp $
} {
    workflow_key:notnull
} -validate {
    workflow_exists -requires {workflow_key} {
	if ![db_string workflow_exists "
	select 1 from wf_workflows 
	where workflow_key = :workflow_key"] {
	    ad_complain "You seem to have specified a nonexistent workflow."
	}
    }
}



set cases_table [db_string cases_table { select table_name from acs_object_types where object_type = :workflow_key }]

# If the table does not exist, it's probably because it was already deleted in a faulty attempt to delete the process.
# At least, let us not prevent the guy from trying to delete the process again.


db_transaction {

    db_dml del_index "
    	   delete from acs_object_context_index 
    	   where 
	   	 object_id in (
	   	 	select object_id 
		 	from acs_objects 
		 	where object_type = :workflow_key
	    	 ) OR
	   	 ancestor_id in (
	   	 	select object_id 
		 	from acs_objects 
		 	where object_type = :workflow_key
	    	 )
    "

    db_dml context "
	update acs_objects
	set context_id = null
	where context_id in (
		select object_id 
		from acs_objects 
		where object_type = :workflow_key
	)
    "

    # Delete tokens
    db_dml del_tokens "delete from wf_tokens where workflow_key = :workflow_key"

    # Delete attributes audit
    db_dml del_tokens "delete from wf_attribute_value_audit where case_id in (select case_id from wf_cases where workflow_key = :workflow_key)"

    # Delete workflow cases
    db_dml del_objes "delete from acs_objects where object_type = :workflow_key"

    # Reset the context ID from objects in the context of the WF (which one? Cases?)
    db_dml reset_context "
       update acs_objects set context_id = null 
       where context_id in (
       	     select object_id 
	     from acs_objects 
	     where object_type = :workflow_key
       )
   "

    if { [db_table_exists $cases_table] } {
	db_exec_plsql delete_cases {
	begin 
	    workflow.delete_cases(workflow_key => :workflow_key);
	end;
	}
    
	db_dml drop_cases_table "
	drop table $cases_table
        "   
    }

    # object type may be referenced from REST interface
    if { [db_table_exists im_rest_object_types] } {
	db_dml del_rest_otype "delete from im_rest_object_types where object_type = :workflow_key"
    }

    db_exec_plsql delete_workflow {
	begin
        workflow.drop_workflow(workflow_key => :workflow_key);
	end;
    }
}

ad_returnredirect ""

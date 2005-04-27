ad_page_contract {
    Delete the attribute.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 15, 2000
    @cvs-id $Id$
} {
    workflow_key
    attribute_id
    {return_url "attributes?[export_vars -url {workflow_key}]"}
}

db_transaction {

    db_dml drop_from_map {
	delete from wf_transition_attribute_map 
	where  workflow_key = :workflow_key
	and    attribute_id = :attribute_id
    }

    set sql {
	select attribute_name
	from   acs_attributes
	where  attribute_id = :attribute_id
    }
    set attribute_name [db_string attribute_name_from_id $sql]

    db_exec_plsql drop_attribute {
        begin
            workflow.drop_attribute(
                workflow_key => :workflow_key,
                attribute_name => :attribute_name
            );
	end;
    }
}

ad_returnredirect $return_url


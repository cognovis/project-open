ad_page_contract {
    Edit name of workflow.
} {
    workflow_key:notnull
    workflow_name:notnull
    description
    {return_url "workflow?[export_url_vars workflow_key]"}
}

db_transaction {
    
    db_dml object_type_update {
	update acs_object_types
	set    pretty_name = :workflow_name,
	       pretty_plural = :workflow_name
	where  object_type = :workflow_key
    }
    
    db_dml workflow_update {
	update wf_workflows
	set    description = :description
	where  workflow_key = :workflow_key
    }
}

wf_workflow_changed $workflow_key

ad_returnredirect $return_url
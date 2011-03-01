ad_page_contract {
    Delete place.
} {
    workflow_key
    place_key
    {return_url "define?[export_url_vars workflow_key]"}
}

db_transaction {
    db_dml arcs_delete {
	delete from wf_arcs
	where  workflow_key = :workflow_key
	and    place_key = :place_key
    }

    db_dml place_delete {
	delete from wf_places
	where  workflow_key = :workflow_key
	and    place_key = :place_key
    }
}

wf_workflow_changed $workflow_key

ad_returnredirect $return_url


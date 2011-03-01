ad_page_contract {} {
    workflow_key:notnull
    transition_key:notnull
    place_key:notnull
    direction:notnull
    {return_url "define?[export_url_vars workflow_key]"}
}

if { [db_string num_arcs { 
    select count(*) 
    from   wf_arcs 
    where  workflow_key = :workflow_key
    and    transition_key = :transition_key
    and    place_key = :place_key
    and    direction = :direction
}] == 0 } {
    db_dml insert_arc {
	insert into wf_arcs (workflow_key, transition_key, place_key, direction) 
	values (:workflow_key, :transition_key, :place_key, :direction)
    }
}

wf_workflow_changed $workflow_key

ad_returnredirect $return_url

ad_page_contract {
    Make assignment manual.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 13, 2000
    @cvs-id $Id$
} {
    workflow_key
    transition_key
    role_key
    {return_url ""}
}

db_transaction {
    db_1row num_rows {
	select count(*) as num_rows 
	  from wf_transition_role_assign_map 
         where workflow_key = :workflow_key
	   and transition_key = :transition_key
	   and assign_role_key = :role_key
    }
    
    if { $num_rows == 0 } {
	db_dml make_manual {
	    insert into wf_transition_role_assign_map (workflow_key, transition_key, assign_role_key)
	    values (:workflow_key, :transition_key, :role_key)
	}
    }
}

ad_returnredirect $return_url
   
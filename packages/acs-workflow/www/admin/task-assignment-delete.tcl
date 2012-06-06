ad_page_contract {
    Make assignment static for the given transition.

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
    db_dml assignment_delete {
	delete from wf_transition_role_assign_map
	 where workflow_key = :workflow_key
  	   and transition_key = :transition_key
	   and assign_role_key = :role_key
    }
}

ad_returnredirect $return_url
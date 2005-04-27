ad_page_contract {
    Add new context.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 September 2000
    @cvs-id $Id$
} {
    context_key
    context_name
    workflow_key:optional
    {return_url ""}
}

db_dml context_insert {
    insert into wf_contexts (context_key, context_name)
    values (:context_key, :context_name)
}

ad_returnredirect $return_url

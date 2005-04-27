ad_page_contract {
    Add a workflow attribute.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 15, 2000
    @cvs-id $Id$
} {
    workflow_key
    return_url:optional
} -properties {
    context
    workflow_name
    datatypes:multirow
    export_vars
}

db_1row workflow_name {
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key
}

set context [list [list "workflow?[export_vars -url {workflow_key}]" "$workflow_name"] [list "attributes?[export_vars -url {workflow_key}]" "Attributes"] "Add attribute"]

set export_vars [export_vars -form {workflow_key return_url}]

db_multirow datatypes datatype {
    select datatype
    from acs_datatypes
    order by datatype
}

ad_return_template




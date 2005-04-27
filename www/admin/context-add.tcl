ad_page_contract {
    Add new context.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 September 2000
    @cvs-id $Id$
} {
    {workflow_key ""}
    {return_url ""}
} -properties {
    context
    export_vars
}

set context [list "Add Context"]
set export_vars [export_form_vars workflow_key return_url]

ad_return_template

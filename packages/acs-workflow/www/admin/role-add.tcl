# /packages/acs-workflow/www/admin/role-add.tcl
ad_page_contract {
     Adds a role to a workflow

     @author Jesse Koontz  [jkoontz@arsdigita.com]
     @creation-date Thu Jan 25 09:29:57 2001
     @cvs-id $Id$
} {
    workflow_key:notnull
    return_url:optional
} -properties {
    context
    export_vars
}

db_1row workflow_info {
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key
}

set context [list [list "workflow?[export_vars -url {workflow_key {tab roles}}]" "$workflow_name"] "Add role"]

set export_vars [export_vars -form {workflow_key return_url}]

ad_return_template


# /packages/acs-workflow/www/admin/role-edit.tcl
ad_page_contract {
     Edit a role.

     @author Lars Pind (lars@pinds.com)
     @creation-date Feb 27, 2001
     @cvs-id $Id$
} {
    workflow_key:notnull
    role_key:notnull
    return_url:optional
} -properties {
    context
    export_vars
    role_key
    role_name
}

db_1row workflow_info {
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key
}

set context [list [list "workflow?[export_vars -url {workflow_key {tab roles}}]" "$workflow_name"] "Edit role"]

set export_vars [export_vars -form {workflow_key role_key return_url}]

db_1row role_info {
    select role_key,
           role_name
      from wf_roles
     where workflow_key = :workflow_key
       and role_key = :role_key
}

ad_return_template


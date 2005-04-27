# /packages/acs-workflow/www/admin/role-manual.tcl
ad_page_contract {
    Makes a role manually assigned
    
    @author Lars Pind (lars@pinds.com)
    @creation-date Feb 27, 2001
    @cvs-id $Id$
} {
    workflow_key:notnull
    role_key:notnull
    {return_url "workflow?[export_vars -url {workflow_key {tab roles}}]"}
} -properties {
    context
    export_vars
    transitions
    role_name
}

db_1row workflow_info {
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key
}

db_1row role_info {
    select role_name
      from wf_roles
     where workflow_key = :workflow_key
       and role_key = :role_key
}

set context [list [list "$return_url" "$workflow_name"] "Manually Assign $role_name"]

set export_vars [export_vars -form {workflow_key role_key return_url}]

db_multirow transitions transitions {
    select t.transition_key,
           t.transition_name
      from wf_transitions t
     where t.workflow_key = :workflow_key
       and not exists (select 1 
                         from wf_transition_role_assign_map m 
                        where m.workflow_key = t.workflow_key  
                          and m.transition_key = t.transition_key 
                          and m.assign_role_key = :role_key)
     order by t.sort_order
}


ad_return_template


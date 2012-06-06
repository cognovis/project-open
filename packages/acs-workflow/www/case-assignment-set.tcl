# /packages/acs-workflow/www/case-assignment-set.tcl
ad_page_contract {
     Set case assignments for a role.
    
     @author Jesse Koontz  [jkoontz@arsdigita.com]
     @creation-date Thu Jan 25 14:39:44 2001
     @cvs-id $Id$
} {
    case_id:integer
    role_key
    return_url:optional
} -properties {
    context
    export_vars
    widget
}

set write_p [ad_permission_p $case_id "write"]

db_1row case_info {
    select case_id, 
           acs_object.name(object_id) as object_name, 
           state,
           workflow_key
    from   wf_cases
    where  case_id = :case_id
} -column_array case

set workflow_key $case(workflow_key)

set role_name [db_string role_name_select "
select role_name
from wf_roles
where role_key = :role_key
and workflow_key = :workflow_key" -default ""]

set context [list [list "case?[export_vars -url {{case_id $case(case_id)}}]" "$case(object_name) case"] "Assign $role_name"]

set export_vars [export_form_vars case_id role_key workflow_key return_url]

set current_assignments [db_list assignment_select "
    select party_id
      from wf_case_assignments
     where case_id = :case_id
       and role_key = :role_key
       and workflow_key = :workflow_key
"]

set widget "<select name=\"assignments\" multiple size=10>"
db_foreach party_with_at_least_one_member {
    sselect p.party_id,
           acs_object.name(p.party_id) as name, 
           decode(p.email, '', '', '('||p.email||')') as email
    from   parties p
    where  0 < (select count(*)
                from   users u, party_approved_member_map m
                where  m.party_id = p.party_id
                and    u.user_id = m.member_id)
} {
    append widget "<option value=\"$party_id\""
    if { [lsearch -exact $current_assignments $party_id] >= 0} {
        append widget " selected"
    }
    append widget ">$name $email</option>"
}
append widget "</select>"

ad_return_template

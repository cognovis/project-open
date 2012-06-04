ad_page_contract {
    Displays deadlines set for a case.
    
    @author Jesse Koontz (jkoontz@arsdigita.com)
    @creation-date 11 January 2001
    @cvs-id $Id$
} {
    case_id:integer,notnull
} -properties {
    case:onerow
    context
    return_url
    done_export_vars
}

db_1row case_info {
    select case_id, 
           acs_object.name(object_id) as object_name, 
           state,
           workflow_key
    from   wf_cases
    where  case_id = :case_id
} -column_array case

set workflow_key $case(workflow_key)

set return_url "case-deadlines?[export_vars -url {{case_id $case(case_id)}}]"

set context [list [list "case?case_id=$case_id" "$case(object_name) case"] "Deadlines"]

set done_export_vars [export_vars -form {{case_id $case(case_id)}}]

ad_return_template




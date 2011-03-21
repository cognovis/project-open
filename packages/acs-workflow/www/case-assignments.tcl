# /packages/acs-workflow/www/case-assignments.tcl
ad_page_contract {
     View/change role assignments for a case.

     @author Jesse Koontz  [jkoontz@arsdigita.com]
     @creation-date Thu Jan 25 14:23:36 2001
     @cvs-id $Id: case-assignments.tcl,v 1.1 2005/04/27 22:50:59 cvs Exp $
} {
    case_id:integer,notnull
} -properties {
    case:onerow
    context
    case_id
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

set return_url "case-assignments?[export_vars -url {{case_id $case(case_id)}}]"

set context [list [list "case?case_id=$case_id" "$case(object_name) case"] "Assignments"]

set done_export_vars [export_vars -form {{case_id $case(case_id)}}]


ad_return_template

# /packages/acs-workflow/www/case-deadline-set.tcl
ad_page_contract {
     Set the deadline for a transition in a case.

     @author Jesse Koontz  [jkoontz@arsdigita.com]
     @creation-date Mon Jan 15 10:05:21 2001
     @cvs-id $Id$
} {
    case_id:integer
    transition_key
    return_url:optional
} -properties {
    context
    export_vars
    date_widget
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

set transition_name [db_string transition_name_select "
select transition_name
from wf_transitions
where transition_key = :transition_key
      and workflow_key = :workflow_key" -default ""]

set context [list [list "case?[export_vars -url {{case_id $case(case_id)}}]" "$case(object_name) case"] "Deadline for $transition_name "]

set export_vars [export_form_vars case_id transition_key workflow_key return_url]

set deadline [db_string deadline_select "
    select deadline
      from wf_case_deadlines
     where case_id = :case_id
       and transition_key = :transition_key
       and workflow_key = :workflow_key
" -default [db_string a_week_from_now "select sysdate+7 from dual"]]


set date_widget [ad_dateentrywidget deadline $deadline]

ad_return_template





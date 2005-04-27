# /packages/acs-workflow/www/task-deadline-set-2.tcl
ad_page_contract {
     Update deadline for a task

     @author Jesse Koontz  [jkoontz@arsdigita.com]
     @creation-date Wed Jan 10 16:28:05 2001
     @cvs-id $Id$
} {
    task_id:integer
    return_url:optional
    deadline:array,date
}

set deadline_date $deadline(date)

db_dml deadline_update "
update wf_tasks set deadline = :deadline_date
where task_id = :task_id"

ad_returnredirect $return_url
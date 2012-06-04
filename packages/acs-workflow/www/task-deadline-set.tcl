# /packages/acs-workflow/www/task-deadline-set.tcl
ad_page_contract {
     Set the deadline for a task

     @author Jesse Koontz  [jkoontz@arsdigita.com]
     @creation-date Wed Jan 10 16:18:17 2001
     @cvs-id $Id$
} {
    task_id:integer
    return_url:optional
} -properties {
    context
    export_vars
    date_widget
}

set write_p [ad_permission_p $task_id "write"]

array set task [wf_task_info $task_id]

set context [list [list "case?case_idf=$task(case_id)" "Case \"$task(object_name)\""] [list "task?[export_url_vars task_id]" "Task \"$task(task_name)\""] "Set deadline"]

set export_vars [export_form_vars task_id return_url]

set deadline [db_string deadline_select "
select deadline
from wf_tasks
where task_id = :task_id" -default ""]

set date_widget [ad_dateentrywidget deadline $deadline]

ad_return_template



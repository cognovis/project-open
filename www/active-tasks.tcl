#
# Active tasks for a case
#
# Expects:
#   case_id
#   date_format (optional)
#   return_url (optional)
# Data sources:
#   active_tasks
#
# cvs-id: $Id$
# Creation date: Feb 21, 2001
# Author: Lars Pind (lars@pinds.com)
#

if { ![info exists date_format] } {
    set date_format "Mon fmDDfm, YYYY HH24:MI:SS"
}

db_multirow active_tasks active_tasks {} {
    set holding_user_url "/shared/community-member?[export_vars -url {{user_id $holding_user}}]"
    if { [string equal $assignee_object_type "user"] } {
	set assignee_url "/shared/community-member?[export_vars -url {{user_id $assignee_party_id}}]"
    }
    if { [string equal $state "enabled"] } {
	set reassign_url "task-assignees?[export_vars -url {task_id return_url}]"
    }
}

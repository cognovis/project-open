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

db_multirow active_tasks active_tasks {
    select t.task_id, 
           t.transition_key, 
           t.state, 
           t.case_id,
           tr.transition_name,
           to_char(t.enabled_date, :date_format) as enabled_date_pretty,
           to_char(t.started_date, :date_format) as started_date_pretty,
           to_char(t.deadline, :date_format) as deadline_pretty,
           p.party_id as assignee_party_id,
           p.email as assignee_email,
           acs_object.name(p.party_id) as assignee_name,
           '' as assignee_url,
           assignee_o.object_type as assignee_object_type,
           '' as reassign_url
      from wf_tasks t, wf_transitions tr, wf_task_assignments tasgn, parties p, acs_objects assignee_o
     where t.case_id = :case_id
       and t.state in ('enabled', 'started')
       and tr.workflow_key = t.workflow_key
       and tr.transition_key = t.transition_key
       and tasgn.task_id (+) = t.task_id
       and p.party_id (+) = tasgn.party_id
       and assignee_o.object_id (+) = p.party_id
    order by t.enabled_date desc
} {
    if { [string equal $assignee_object_type "user"] } {
	set assignee_url "/shared/community-member?[export_vars -url {{user_id $assignee_party_id}}]"
    }
    if { [string equal $state "enabled"] } {
	set reassign_url "task-assignees?[export_vars -url {task_id return_url}]"
    }
}

#
# Display deadlines for a case
# 
# Expects:
#   case_id
#   date_format (optional)
#   return_url (optional)
# Data sources:
#   deadlines
#
# Cvs-id $Id$
# Author: Lars Pind (lars@pinds.com)
# Creation-date: Feb 21, 2001
#

if { ![info exists date_format] } {
    set date_format "Mon fmDDfm, YYYY HH24:MI:SS"
}



db_multirow deadlines deadlines {
    select tr.transition_name, 
           tr.transition_key, 
           to_char(cd.deadline, :date_format) as deadline_pretty,
           '' as edit_url,
           '' as remove_url
    from   (select c.case_id, tr.sort_order, tr.transition_name, tr.transition_key, tr.workflow_key from wf_cases c, wf_transitions tr
            where c.case_id = :case_id and c.workflow_key = tr.workflow_key) tr,
            wf_case_deadlines cd
    where  tr.case_id = cd.case_id(+)
    and    tr.transition_key = cd.transition_key(+)
    and    tr.workflow_key = cd.workflow_key(+)
    order by tr.sort_order
} {
    set edit_url "case-deadline-set?[export_vars -url {case_id transition_key return_url}]"
    if { ![empty_string_p $deadline_pretty] } {
	set remove_url "case-deadline-remove-2?[export_vars -url {case_id transition_key return_url}]"
    }
}


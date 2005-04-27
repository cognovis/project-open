#
# Table of manual assignments for a case
#
# Expects:
#   case_id
#   return_url (optional)
# Data sources:
#   manual_assignments
#
# cvs-id: $Id$
# Creation date: Feb 21, 2001
# Author: Lars Pind (lars@pinds.com)
#

db_multirow manual_assignments manual_assignments {
    select p.party_id,
           acs_object.name(p.party_id) as name,
           p.email,
           '' as url,
           '' as remove_url,
           '' as edit_url,
           o.object_type,
           r.role_key,
           r.role_name
      from wf_cases c, wf_roles r, wf_case_assignments ca, parties p, acs_objects o
     where c.case_id = :case_id
       and r.workflow_key = c.workflow_key
       and ca.case_id (+) = :case_id
       and ca.role_key (+) = r.role_key 
       and p.party_id (+) = ca.party_id 
       and o.object_id (+) = p.party_id 
     order by r.sort_order, r.role_key, name
} {
    if { [string equal $object_type "user"] } {
	set url "/shared/community-member?[export_vars -url { { user_id $party_id }}]"
    }
    set remove_url "case-assignment-remove-2?[export_vars -url {case_id role_key party_id return_url}]"
    set edit_url "case-assignment-set?[export_vars -url {case_id role_key return_url}]"
}


#
# Display transitions for a process.
#
# Input:
#   workflow_key
#   return_url (optional)
#   context (optional)
#
# Data sources:
#   roles
#
# Author: Lars Pind (lars@pinds.com)
# Creation-date: Feb 26, 2001
# Cvs-id: $Id$

if { ![info exists context_key] } {
    set context_key "default"
}

set last_role_key {}
db_multirow roles roles {} {
    if { ![string equal $role_key $last_role_key] } {
	set counter 0
	set user_select_widget "<select name=party_id><option>--Please select--</option>"
	db_foreach parties {
            select p.party_id as sel_party_id,
                   acs_object.name(p.party_id) as sel_name,
                   p.email as sel_email
            from   parties p
            where  p.party_id not in (
			select	ca.party_id 
			from	wf_context_assignments ca
			where	ca.workflow_key = :workflow_key 
				and    ca.context_key = :context_key 
				and    ca.role_key = :role_key
		   )
		   and p.party_id in (select group_id from groups)
	} {
            incr counter
            append user_select_widget "<option value=\"$sel_party_id\">$sel_name[ad_decode $sel_email "" "" " ($sel_email)"]</option>\n"
	}   
	append user_select_widget "</select>"
	if { $counter == 0 } {
	    set user_select_widget ""
	}
	set last_user_select_widget $user_select_widget
	set last_role_key $role_key
    } else {
	set user_select_widget $last_user_select_widget
    }
    set add_export_vars [export_vars -form {workflow_key context_key role_key return_url}]
    if { ![empty_string_p $party_id] } {
	set remove_url "static-assignment-delete?[export_vars -url { workflow_key context_key role_key party_id return_url }]"
    }
}

ad_return_template



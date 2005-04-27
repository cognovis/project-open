#
# Attributes table.
#
# Input:
#   workflow_key
#   return_url (optional)
#   modifiable_p (optional)
#
# Data sources:
#   attributes
#   add_url
#
# Author: Lars Pind (lars@pinds.com)
# Creation-date: Feb 26, 2001
# Cvs-id: $Id$
#

if { ![info exists modifiable_p] } {
    set modifiable_p 1
}

db_multirow attributes attributes {
    select a.attribute_id,
           a.sort_order,
           a.attribute_name,
           a.pretty_name,
           a.datatype,
           '' as delete_url,
           (select count(*) from wf_transition_attribute_map m
            where  m.workflow_key = a.object_type
            and    m.attribute_id = a.attribute_id) as used_p
    from   acs_attributes a
    where  a.object_type = :workflow_key
    order by sort_order
} {
    if { $modifiable_p } {
	set delete_url "attribute-delete?[export_vars -url {workflow_key attribute_id return_url}]"
    }
}

set add_url "attribute-add?[export_vars -url {workflow_key return_url}]"





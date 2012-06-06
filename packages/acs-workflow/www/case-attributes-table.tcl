#
# Table of attributes for a case.
#
# Expects:
#   case_id
# Data sources:
#   attributes
#
# cvs-id: $Id$
# Creation date: Feb 21, 2001
# Author: Lars Pind (lars@pinds.com)
#

db_multirow attributes attributes {
    select a.attribute_id,
           a.sort_order,
           a.attribute_name,
           a.pretty_name,
           a.datatype,
           '' as edit_url,
           workflow_case.get_attribute_value(:case_id, a.attribute_name) as value,
           '' as value_pretty
      from acs_attributes a, wf_cases c
     where c.case_id = :case_id
       and a.object_type = c.workflow_key
     order by a.sort_order
} {
    # set edit_url "case-attribute-edit?[export_vars -url {case_id attribute_name}]"
    set value_pretty [wf_attribute_value_pretty [list datatype $datatype value $value]]
}

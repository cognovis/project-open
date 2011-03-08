<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="attributes">      
      <querytext>
      
    select a.attribute_id,
           a.sort_order,
           a.attribute_name,
           a.pretty_name,
           a.datatype,
           '' as edit_url,
           workflow_case__get_attribute_value (:case_id, a.attribute_name) as value,
           '' as value_pretty
      from acs_attributes a, wf_cases c
     where c.case_id = :case_id
       and a.object_type = c.workflow_key
     order by a.sort_order

      </querytext>
</fullquery>

 
</queryset>

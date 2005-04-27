<?xml version="1.0"?>
<queryset>

<fullquery name="attributes">      
      <querytext>
      
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

      </querytext>
</fullquery>

 
</queryset>

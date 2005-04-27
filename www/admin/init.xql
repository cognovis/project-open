<?xml version="1.0"?>
<queryset>

<fullquery name="context">      
      <querytext>
      
    select context_key, context_name, '' as selected
    from wf_contexts 
    order by context_name 

      </querytext>
</fullquery>

 
<fullquery name="workflow_name">      
      <querytext>
      select pretty_name from acs_object_types where object_type = :workflow_key
      </querytext>
</fullquery>

 
</queryset>

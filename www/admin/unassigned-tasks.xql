<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_info">      
      <querytext>
      
    select  ot.pretty_name
    from    wf_workflows wf, acs_object_types ot
    where   wf.workflow_key = :workflow_key
    and     ot.object_type = wf.workflow_key

      </querytext>
</fullquery>

 
</queryset>

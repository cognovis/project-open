<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_info">      
      <querytext>
      
    select ot.pretty_name as workflow_name, w.description
    from   acs_object_types ot, wf_workflows w
    where  ot.object_type = w.workflow_key
    and    w.workflow_key = :workflow_key

      </querytext>
</fullquery>

 
</queryset>

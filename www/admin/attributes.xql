<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_exists">      
      <querytext>
      
	select 1 from wf_workflows 
	where workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="workflow_name">      
      <querytext>
      
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key

      </querytext>
</fullquery>

 
</queryset>

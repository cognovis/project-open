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
      
    select pretty_name as workflow_name
    from   acs_object_types
    where  object_type = :workflow_key

      </querytext>
</fullquery>

 
<fullquery name="context_slider">      
      <querytext>
      
    select context_key as context_key_from_db,
           context_name as title,
           '' as url,
           0 as selected_p
    from   wf_contexts
    order by context_name

      </querytext>
</fullquery>
 
</queryset>

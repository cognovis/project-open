<?xml version="1.0"?>
<queryset>

<fullquery name="get_name">      
      <querytext>
      
      select 
        transition_name 
      from 
        wf_transitions
      where 
        transition_key = :transition
      and 
        workflow_key = 'publishing_wf'
    
      </querytext>
</fullquery>

 
</queryset>

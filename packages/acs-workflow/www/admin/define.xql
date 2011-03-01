<?xml version="1.0"?>
<queryset>

<fullquery name="wf_exists">      
      <querytext>
       select count(*) from wf_workflows where workflow_key = :workflow_key 
      </querytext>
</fullquery>

 
<fullquery name="num_cases">      
      <querytext>
      
    select count(*) as num_cases from wf_cases where workflow_key = :workflow_key

      </querytext>
</fullquery>

 
</queryset>

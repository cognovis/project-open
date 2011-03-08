<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_exists">      
      <querytext>
      
	select 1 from wf_workflows 
	where workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="cases_table">      
      <querytext>
       select table_name from acs_object_types where object_type = :workflow_key 
      </querytext>
</fullquery>

 
<fullquery name="drop_cases_table">      
      <querytext>
      
	drop table $cases_table
    
      </querytext>
</fullquery>

 
</queryset>

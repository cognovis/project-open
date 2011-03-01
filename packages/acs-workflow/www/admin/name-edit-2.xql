<?xml version="1.0"?>
<queryset>

<fullquery name="object_type_update">      
      <querytext>
      
	update acs_object_types
	set    pretty_name = :workflow_name,
	       pretty_plural = :workflow_name
	where  object_type = :workflow_key
    
      </querytext>
</fullquery>

 
<fullquery name="workflow_update">      
      <querytext>
      
	update wf_workflows
	set    description = :description
	where  workflow_key = :workflow_key
    
      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>
<queryset>

<fullquery name="num_roles">      
      <querytext>
      
	    select count(*) 
	    from   wf_roles
	    where  workflow_key = :workflow_key
	    and    role_name = :role_name
	
      </querytext>
</fullquery>

 
</queryset>

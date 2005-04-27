<?xml version="1.0"?>
<queryset>

<fullquery name="num_roles">      
      <querytext>
      
	    select count(*) 
	    from   wf_roles
	    where  workflow_key = :workflow_key
	    and    role_name = :role_name
            and    role_key != :role_key
	
      </querytext>
</fullquery>

 
<fullquery name="edit_role">      
      <querytext>
      
	update wf_roles
	   set role_name = :role_name
	 where workflow_key = :workflow_key
	   and role_key = :role_key
    
      </querytext>
</fullquery>

 
</queryset>

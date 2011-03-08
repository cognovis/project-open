<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="grant_permissions">      
      <querytext>
      
	declare
	  cursor c_item_cur is
	    select item_id from cr_items
	    connect by parent_id = prior item_id
	    start with parent_id = 0;
	
          cursor c_module_cur is
	    select module_id from cm_modules;

	begin
  
	  for item_row in c_item_cur loop 
	    acs_permission.grant_permission (
	        object_id  => item_row.item_id, 
	        grantee_id => :user_id, 
	        privilege  => 'cm_admin'
	    );
	  end loop;

	  for v_module in c_module_cur loop
	    acs_permission.grant_permission (
	        object_id  => v_module.module_id,
	        grantee_id => :user_id,
	        privilege  => 'cm_admin'
            );
	  end loop;

	end;

      </querytext>
</fullquery>

</queryset>

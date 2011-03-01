<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="grant_permissions">      
      <querytext>

	declare
          v_module      record;
          item_row      record;
	begin
  
	  for item_row in 
	    select c1.item_id from cr_items c1, cr_items c2
            where c2.parent_id = 0
              and c1.tree_sortkey between c2.tree_sortkey and tree_right(c2.tree_sortkey)
          LOOP 
	    PERFORM acs_permission__grant_permission (
	        item_row.item_id, 
	        :user_id, 
	        'cm_admin'
	    );
	  end loop;

	  for v_module in
	    select module_id from cm_modules
          LOOP
	    PERFORM acs_permission__grant_permission (
	        v_module.module_id,
	        :user_id,
	        'cm_admin'
            );
	  end loop;

          return null;
	end;
      </querytext>
</fullquery>

</queryset>

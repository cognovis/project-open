<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="drop_attribute">      
      <querytext>

	select workflow__drop_attribute(
                :workflow_key,
                :attribute_name
            );
    
      </querytext>
</fullquery>

 
</queryset>

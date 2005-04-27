<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="drop_attribute">      
      <querytext>
      
        begin
            workflow.drop_attribute(
                workflow_key => :workflow_key,
                attribute_name => :attribute_name
            );
	end;
    
      </querytext>
</fullquery>

 
</queryset>

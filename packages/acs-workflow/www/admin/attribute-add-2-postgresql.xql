<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="create_attribute">      
      <querytext>

	select workflow__create_attribute(
          :workflow_key,
          :attribute_name,
          :datatype,
          :pretty_name,
	  null,
	  null,
	  null,
          :default_value,
	  1,
	  1,
	  null,
	  'generic'
      );

      </querytext>
</fullquery>

 
</queryset>

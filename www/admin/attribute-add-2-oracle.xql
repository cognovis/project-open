<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_attribute">      
      <querytext>
      
    declare
      v_attribute_id integer;
    begin
      v_attribute_id := workflow.create_attribute(
          workflow_key => :workflow_key,
          attribute_name => :attribute_name,
          datatype => :datatype,
          pretty_name => :pretty_name,
          default_value => :default_value
      );
    end;

      </querytext>
</fullquery>

 
</queryset>

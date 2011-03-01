<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="unregister">      
      <querytext>
      
  begin
  cm_form_widget.unregister_attribute_widget (
      content_type   => :content_type,
      attribute_name => :attribute_name
  );
  end;

      </querytext>
</fullquery>

 
</queryset>

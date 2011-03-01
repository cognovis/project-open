<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="content_method_unregister">      
      <querytext>
      
  begin
  content_method.remove_method (
      content_type   => :content_type,
      content_method => :content_method
  );
  end;

      </querytext>
</fullquery>

 
</queryset>

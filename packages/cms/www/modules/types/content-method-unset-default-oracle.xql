<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="unset_content_method_default">      
      <querytext>
      
  begin
    content_method.unset_default_method (
      content_type   => :content_type
    );
  end;

      </querytext>
</fullquery>

 
</queryset>

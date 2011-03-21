<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="unregister_template">      
      <querytext>
      
  begin
    content_type.unregister_template(
      template_id  => :template_id,
      content_type => :content_type,
      use_context  => :context );
  end;
      </querytext>
</fullquery>

 
</queryset>

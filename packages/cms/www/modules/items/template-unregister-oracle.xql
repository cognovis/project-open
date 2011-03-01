<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="template_unregister">      
      <querytext>
      begin
         content_item.unregister_template(
             template_id => :template_id, 
             item_id     => :item_id, 
             use_context => :context ); 
         end;
      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="register_template_to_item">      
      <querytext>

        begin content_item.register_template(
            item_id     => :item_id,
            template_id => :template_id,
            use_context => :context ); 
         end;
  
      </querytext>
</fullquery>

 
</queryset>

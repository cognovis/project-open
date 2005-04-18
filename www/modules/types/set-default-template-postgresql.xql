<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="set_default_template">      
      <querytext>

        select content_type__set_default_template(
                        :content_type,
                        :template_id,
                        :context );
  
      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="new_template">      
      <querytext>

        select content_template__new(
            :name,
            :parent_id,
            :template_id,
            now(),
            :user_id,
            :ip_address
        );
        
      </querytext>
</fullquery>

<fullquery name="get_template_id">      
      <querytext>
      
        select acs_object_id_seq.nextval

      </querytext>
</fullquery>
 
</queryset>

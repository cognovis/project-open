<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="new_template">      
      <querytext>

        select content_template__new(
                :name,
                :folder_id,
                :template_id,
                now(),
                :creation_user,
                :creation_ip
        );

      </querytext>
</fullquery>

<fullquery name="get_path">      
      <querytext>

        select content_item__get_path(:folder_id, null)

      </querytext>
</fullquery>
 
</queryset>

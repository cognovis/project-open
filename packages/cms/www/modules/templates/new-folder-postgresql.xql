<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_path">      
      <querytext>

        select content_item__get_path(:parent_id, null)

      </querytext>
</fullquery>

<fullquery name="new_folder">      
      <querytext>

   select content_folder__new(
         :name,
         :label,
         :description,
         :parent_id,
         null,
         :folder_id,
         now(),
         :creation_user,
         :creation_ip
  )
       </querytext>
</fullquery>
  
</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="">      
      <querytext>

        select parent_id, 
                 content_folder__is_folder(item_id) as folder_p
                 from cr_items
                 where item_id = :resolved_id  
      </querytext>
</fullquery>

 
</queryset>

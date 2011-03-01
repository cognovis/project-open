<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="do_folder_check">      
      <querytext>

        select parent_id, 
                 content_folder.is_folder(item_id) as folder_p
                 from cr_items
                 where item_id = :resolved_id

      </querytext>
</fullquery>

 
</queryset>

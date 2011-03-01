<?xml version="1.0"?>
<queryset>

<fullquery name="get_info">      
      <querytext>
      
    select
      i.name, f.label, f.description
    from 
      cr_items i, cr_folders f
    where
      i.item_id = :item_id
    and
      f.folder_id = :item_id
      </querytext>
</fullquery>

 
</queryset>

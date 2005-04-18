<?xml version="1.0"?>
<queryset>

<fullquery name="insert_images">      
      <querytext>
      
      insert into images (
        image_id, width, height
      ) values (
        :revision_id, :width, :height
      )
      </querytext>
</fullquery>


<fullquery name="get_item_info">      
      <querytext>

  select 
    i.name, i.latest_revision, r.title 
  from 
    cr_items i, cr_revisions r
  where 
    i.item_id = :item_id
  and
    i.item_id = r.item_id
  and
    i.latest_revision = r.revision_id

      </querytext>
</fullquery>

 
</queryset>

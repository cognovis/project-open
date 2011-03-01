<?xml version="1.0"?>
<queryset>

<fullquery name="get_revision">      
      <querytext>
      
  select
    i.item_id, content_type, title as name, mime_type
  from
    cr_revisions r, cr_items i
  where
    i.item_id = r.item_id
  and
    r.revision_id = :revision_id

      </querytext>
</fullquery>

 
</queryset>

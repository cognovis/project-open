<?xml version="1.0"?>
<queryset>

<fullquery name="get_item">      
      <querytext>

  select 
    i.content_type, i.name, coalesce(r.title, i.name) as title, i.latest_revision
  from
    cr_items i left outer join cr_revisions r on i.latest_revision = r.revision_id 
  where
   i.item_id = :item_id

      </querytext>
</fullquery>

 
</queryset>

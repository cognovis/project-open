<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_item">      
      <querytext>
      
  select 
    i.content_type, i.name, nvl(r.title, i.name) title, i.latest_revision
  from
    cr_items i, cr_revisions r
  where
   i.item_id = :item_id
  and
   i.latest_revision = r.revision_id (+)

      </querytext>
</fullquery>

 
</queryset>

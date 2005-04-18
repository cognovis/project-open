<?xml version="1.0"?>
<queryset>

<fullquery name="get_revision">      
      <querytext>
      
  select
    item_id, title as name
  from
    cr_revisions
  where
    revision_id = :revision_id

      </querytext>
</fullquery>

 
</queryset>

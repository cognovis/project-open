<?xml version="1.0"?>
<queryset>

<fullquery name="get_live_revision">      
      <querytext>

        select live_revision from cr_items where item_id = :template_id

      </querytext>
</fullquery>


<fullquery name="get_revision_count">      
      <querytext>

  select
    count(*) 
  from 
    cr_revisions
  where
    item_id = :template_id

      </querytext>
</fullquery>

 
</queryset>

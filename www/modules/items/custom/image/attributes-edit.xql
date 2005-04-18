<?xml version="1.0"?>
<queryset>

<fullquery name="abort">      
      <querytext>
      abort transaction
      </querytext>
</fullquery>

 
<fullquery name="update_revisions">      
      <querytext>
      
      update cr_revisions
        set title = :title,
        description = :description
        where revision_id = :revision_id
      </querytext>
</fullquery>

 
<fullquery name="update_images">      
      <querytext>
      
      update images
        set width = :width,
        height = :height
        where image_id = :revision_id
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

 
<fullquery name="get_latest">      
      <querytext>
      
      select
        latest_revision
      from
        cr_items
      where
        item_id = :item_id
    
      </querytext>
</fullquery>

 
<fullquery name="get_clicks">      
      <querytext>
      
	  select
	    count(1)
	  from
	    cr_revisions
	  where
	    revision_id = :revision_id
	
      </querytext>
</fullquery>

 
</queryset>

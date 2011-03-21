<?xml version="1.0"?>
<queryset>

<fullquery name="abort">      
      <querytext>
      abort transaction
      </querytext>
</fullquery>

 
<fullquery name="insert_images">      
      <querytext>
      
      insert into images (
        image_id, width, height
      ) values (
        :revision_id, :width, :height
      )
      </querytext>
</fullquery>

 
<fullquery name="get_clicks">      
      <querytext>
      
	  select
	    count(1)
	  from
	    cr_items
	  where
	    item_id = :item_id
	
      </querytext>
</fullquery>

 
</queryset>

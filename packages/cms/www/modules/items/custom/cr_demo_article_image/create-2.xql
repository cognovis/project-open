<?xml version="1.0"?>
<queryset>

<fullquery name="abort">      
      <querytext>
      abort transaction
      </querytext>
</fullquery>

 
<fullquery name="insert_image">      
      <querytext>
      
      insert into images (
        image_id, width, height
      ) values (
        :revision_id, :width, :height
      )
      </querytext>
</fullquery>

 
<fullquery name="insert_art_image">      
      <querytext>
      
      insert into cr_demo_article_images (
        article_image_id, caption
      ) values (
        :revision_id, :caption
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

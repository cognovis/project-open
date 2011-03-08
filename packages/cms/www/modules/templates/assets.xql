<?xml version="1.0"?>
<queryset>

<fullquery name="get_image_info">      
      <querytext>
      
          select width, height from images 
          where image_id = :revision_id
        
      </querytext>
</fullquery>

 
</queryset>

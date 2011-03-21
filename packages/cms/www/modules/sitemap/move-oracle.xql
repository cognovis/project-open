<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="move_items">      
      <querytext>
      
	    begin
            content_item.move(
                item_id          => :mv_item_id,
                target_folder_id => :folder_id
            ); 
            end;
      </querytext>
</fullquery>

 
<fullquery name="get_path">      
      <querytext>
      
  select
    content_item.get_path( :folder_id )
  from 
    dual

      </querytext>
</fullquery>

 
<fullquery name="get_marked">      
      <querytext>
      
  select
    content_item.get_title(item_id) title, 
    content_item.get_path(item_id,:root_id) name, 
    item_id, parent_id
  from
    cr_items
  where
    item_id in ([join $clip_items ","])
  and
    -- only for those items which user has cm_write
    cms_permission.permission_p(item_id, :user_id, 'cm_write') = 't'

      </querytext>
</fullquery>

 
</queryset>

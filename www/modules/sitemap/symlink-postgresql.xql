<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="new_link">      
      <querytext>


        select content_symlink__new(
                :name, 
                :label,
                :sym_item_id, 
                :folder_id,
                null,
                current_timestamp, 
                :user_id, 
                :ip
            ); 
            
      </querytext>
</fullquery>

 
<fullquery name="get_marked">      
      <querytext>
      
  select
    content_item__get_title(item_id,'f') as title, 'symlink_to_' || name as name, 
    item_id
  from
    cr_items
  where
    item_id in ([join $clip_items ","])
  and
    -- only items which have are not symlinks
    content_type != 'content_symlink'
  and
    -- only for those item which user has cm_examine
    cms_permission__permission_p(item_id, :user_id, 'cm_examine') = 't'

      </querytext>
</fullquery>

 
</queryset>

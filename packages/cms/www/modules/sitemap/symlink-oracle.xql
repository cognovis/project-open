<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="new_link">      
      <querytext>
      
	    begin
            :symlink_id := content_symlink.new(
                name          => :name, 
                label         => :label,
                target_id     => :sym_item_id, 
                parent_id     => :folder_id,
                creation_date => sysdate, 
                creation_user => :user_id, 
                creation_ip   => :ip
            ); 
            end;
      </querytext>
</fullquery>

 
<fullquery name="get_marked">      
      <querytext>
      
  select
    content_item.get_title(item_id) title, 'symlink_to_' || name as name, 
    item_id
  from
    cr_items
  where
    item_id in ([join $clip_items ","])
  and
    -- only items which have are not symlinks
    content_type ^= 'content_symlink'
  and
    -- only for those item which user has cm_examine
    cms_permission.permission_p(item_id, :user_id, 'cm_examine') = 't'

      </querytext>
</fullquery>

 
</queryset>

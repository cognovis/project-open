<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_marked_items">      
      <querytext>

  select
    item_id,
    nvl(content_item.get_title(item_id),name) title, 
    content_item.get_path(item_id) path,
    pretty_name as content_type_pretty,
    content_symlink.is_symlink(item_id) is_symlink,
    content_folder.is_folder(item_id) is_folder,
    content_template.is_template(item_id) is_template
  from
    cr_items i, acs_object_types t
  where
    i.content_type = t.object_type
  and
    item_id in ([join $clip_items ","])
  and
    -- permissions check
    cms_permission.permission_p( item_id, :user_id, 'cm_write' ) = 't'
  order by
    -- this way parents are deleted after their children
    item_id desc

      </querytext>
</fullquery>


<fullquery name="delete_items">      
      <querytext>
      
	  begin
	  $delete_proc (
	    $delete_key => :del_item_id
          );
          end;
      </querytext>
</fullquery>

<partialquery name="symlink_delete">      
      <querytext>

        content_symlink.del

      </querytext>
</partialquery>

<partialquery name="folder_delete">      
      <querytext>

        content_folder.del

      </querytext>
</partialquery>

<partialquery name="template_delete">      
      <querytext>

        content_template.del

      </querytext>
</partialquery>

<partialquery name="item_delete">      
      <querytext>

        content_item.del

      </querytext>
</partialquery>

</queryset>

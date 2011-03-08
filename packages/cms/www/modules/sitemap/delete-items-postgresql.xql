<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_marked_items">      
      <querytext>

  select
    item_id,
    coalesce(content_item__get_title(item_id,'f'),name) as title, 
    content_item__get_path(item_id, null) as path,
    pretty_name as content_type_pretty,
    content_symlink__is_symlink(item_id) as is_symlink,
    content_folder__is_folder(item_id) as is_folder,
    content_template__is_template(item_id) as is_template
  from
    cr_items i, acs_object_types t
  where
    i.content_type = t.object_type
  and
    item_id in ([join $clip_items ","])
  and
    -- permissions check
    cms_permission__permission_p( item_id, :user_id, 'cm_write' ) = 't'
  order by
    -- this way parents are deleted after their children
    item_id desc

      </querytext>
</fullquery>

<fullquery name="delete_items">      
      <querytext>
	 
	  select $delete_proc (
	    :del_item_id
          );

         
      </querytext>
</fullquery>


<partialquery name="symlink_delete">      
      <querytext>

        content_symlink__delete

      </querytext>
</partialquery>

<partialquery name="folder_delete">      
      <querytext>

        content_folder__delete

      </querytext>
</partialquery>

<partialquery name="template_delete">      
      <querytext>

        content_template__delete

      </querytext>
</partialquery>

<partialquery name="item_delete">      
      <querytext>

        content_item__delete

      </querytext>
</partialquery>
 
</queryset>

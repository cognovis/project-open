<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>


<partialquery name="index_page_p">      
      <querytext>

      decode( nvl( 
        content_folder.get_index_page( :item_id ),0)
        ,0,'f','t') has_index_page,

      </querytext>
</partialquery>

<fullquery name="get_context">      
      <querytext>
      
  select
    t.tree_level, t.parent_id, 
    content_folder.is_folder(i.item_id) is_folder,
    content_item.get_title(t.parent_id) as title
  from 
    cr_items i,
    (
      select 
        parent_id, level as tree_level
      from 
        cr_items
      where
        parent_id ^= 0
      connect by
        prior parent_id = item_id
      start with
        item_id = :item_id
    ) t
  where
    i.item_id = t.parent_id
  order by
    tree_level desc
      </querytext>
</fullquery>

 
<fullquery name="get_preview_info">      
      <querytext>
      
  select
    $index_page_sql 
    -- does it have a template
    content_item.get_template( item_id, 'public' ) template_id,
    -- symlinks to this folder will have the path of this item
    content_item.get_virtual_path( item_id, :root_id ) virtual_path,
    content_item.get_path( 
      content_symlink.resolve( item_id ), :root_id ) physical_path,
    content_folder.is_folder( item_id ) is_folder,
    live_revision
  from
    cr_items
  where 
    item_id = :item_id
      </querytext>
</fullquery>

 
<fullquery name="get_template_id">      
      <querytext>
      
      select 
        content_item.get_template( 
          nvl( content_folder.get_index_page( :item_id ), 0), 'public' )
      from
        dual
    
      </querytext>
</fullquery>

 
</queryset>

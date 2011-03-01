<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<partialquery name="index_page_p">      
      <querytext>

      case when coalesce( 
        content_folder__get_index_page( :item_id ),0) =  0 then 'f' else 't' end as has_index_page,

      </querytext>
</partialquery>

<fullquery name="get_context">      
      <querytext>

  select
    t.tree_level, t.parent_id, 
    content_folder__is_folder(i.item_id) as is_folder,
    content_item__get_title(t.parent_id,'f') as title
  from 
    cr_items i,
    (
      select 
        i2.parent_id, tree_level(i2.tree_sortkey) as tree_level
      from 
        (select * from cr_items where item_id = :item_id) i1, cr_items i2
      where
        i2.parent_id != 0
      and
        i1.tree_sortkey between i2.tree_sortkey and tree_right(i2.tree_sortkey)
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
    content_item__get_template( item_id, 'public' ) as template_id,
    -- symlinks to this folder will have the path of this item
    content_item__get_virtual_path( item_id, :root_id ) as virtual_path,
    content_item__get_path( 
      content_symlink__resolve( item_id ), :root_id ) as physical_path,
    content_folder__is_folder( item_id ) as is_folder,
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
        content_item__get_template( 
          coalesce( content_folder__get_index_page( :item_id ), 0), 'public' )
      from
        dual
    
      </querytext>
</fullquery>

 
</queryset>

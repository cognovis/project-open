<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_item_info">      
      <querytext>
      
    select 
      content_item__get_title(i.item_id,'f') as title,
      i.content_type
    from 
      cr_items i
    where
      i.item_id = :item_id

      </querytext>
</fullquery>

 
<fullquery name="get_options">      
      <querytext>

    select 
      lpad(' ', tree_level(ot1.tree_sortkey), '-') || ot1.pretty_name as pretty_name, 
      ot1.object_type
    from
      acs_object_types ot1, acs_object_types ot2
    where ot2.object_type = 'cr_item_rel'
      and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)

      </querytext>
</fullquery>

 
<fullquery name="get_clip_items">      
      <querytext>
      
    select
      i.item_id as related_id, 
      content_item__get_title(i.item_id,'f') as title,
      content_item__get_path(i.item_id,null) as path,   
      tr.relation_tag
    from
      cr_items i, cr_type_relations tr
    where
      content_item__is_subclass(i.content_type, tr.target_type) = 't'
    and
      content_item__is_subclass(:item_type, tr.content_type) = 't'
    and (
      tr.max_n is null 
      or 
      (select count(*) from cr_item_rels 
	where item_id = :item_id 
	and relation_tag = tr.relation_tag) < tr.max_n
      )
    and 
      i.item_id in $sql_items
    and
      i.item_id != :item_id
    order by
      path, i.item_id, tr.relation_tag
      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_item_info">      
      <querytext>
      
    select 
      content_item.get_title(i.item_id) as title,
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
      lpad(' ', level, '-') || pretty_name as pretty_name, 
      object_type
    from
      acs_object_types
    connect by
      prior object_type = supertype
    start with
      object_type = 'cr_item_rel'
      </querytext>
</fullquery>

 
<fullquery name="get_clip_items">      
      <querytext>
      
    select
      i.item_id as related_id, 
      content_item.get_title(i.item_id) as title,
      content_item.get_path(i.item_id) as path,   
      tr.relation_tag
    from
      cr_items i, cr_type_relations tr
    where
      content_item.is_subclass(i.content_type, tr.target_type) = 't'
    and
      content_item.is_subclass(:item_type, tr.content_type) = 't'
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
      i.item_id ^= :item_id
    order by
      path, i.item_id, tr.relation_tag
      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_info">      
      <querytext>
      
  select
    NVL(initcap(publish_status), 'Production') publish_status, 
    NVL(to_char(start_when, 'MM/DD/YY HH:MI AM'), 'Immediate') start_when,
    NVL(to_char(end_when, 'MM/DD/YY HH:MI AM'), 'Indefinite') end_when,
    content_item.is_publishable(:item_id) is_publishable,
    live_revision
  from
    cr_items i, cr_release_periods r
  where
    i.item_id = :item_id
  and
    i.item_id = r.item_id (+)
      </querytext>
</fullquery>

 
<fullquery name="get_publish_info">      
      <querytext>
      
  select 
    content_item.is_publishable( item_id ) is_publishable, 
    live_revision
  from
    cr_items
  where
    item_id = :item_id

      </querytext>
</fullquery>

 
<fullquery name="unfinished_exists">      
      <querytext>
      
  select content_workflow.unfinished_workflow_exists( :item_id ) from dual

      </querytext>
</fullquery>

 
<fullquery name="get_child_types">      
      <querytext>
      
  select
    child_type, relation_tag, min_n, 
    o.pretty_name as child_type_pretty, 
    o.pretty_plural as child_type_plural, 
    case when max_n = null then '-' else to_char(max_n) end as max_n,
    (
      select
        count(*)
      from
        cr_child_rels
      where
        parent_id = i.item_id
      and
        content_item.get_content_type( child_id ) = c.child_type
      and
        relation_tag = c.relation_tag
    ) as child_count
  from
    cr_type_children c, cr_items i, acs_object_types o
  where
    c.parent_type = i.content_type
  and
    c.child_type = o.object_type
  and
    -- this item is the parent
    i.item_id = :item_id

      </querytext>
</fullquery>

 
<fullquery name="get_rel_types">      
      <querytext>
      
  select
    target_type, relation_tag, min_n, 
    o.pretty_name as target_type_pretty,
    o.pretty_plural as target_type_plural,
    case when max_n = null then '-' else to_char(max_n) end max_n,
    (
      select
        count(*)
      from
        cr_item_rels
      where
        item_id = i.item_id
      and
        content_item.get_content_type( related_object_id ) = r.target_type
      and
        relation_tag = r.relation_tag
    ) rel_count
  from
    cr_type_relations r, cr_items i, acs_object_types o
  where
    o.object_type = r.target_type
  and
    r.content_type = i.content_type
  and
    i.item_id = :item_id

      </querytext>
</fullquery>

 
</queryset>

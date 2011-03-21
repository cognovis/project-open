<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_info">      
      <querytext>

  select
    coalesce(initcap(publish_status), 'Production') as publish_status, 
    coalesce(to_char(start_when, 'MM/DD/YY HH:MI AM'), 'Immediate') as start_when,
    coalesce(to_char(end_when, 'MM/DD/YY HH:MI AM'), 'Indefinite') as end_when,
    content_item__is_publishable(:item_id) as is_publishable,
    live_revision
  from
    cr_items i left outer join cr_release_periods r using (item_id)
  where
    i.item_id = :item_id

      </querytext>
</fullquery>

 
<fullquery name="get_publish_info">      
      <querytext>
      
  select 
    content_item__is_publishable( item_id ) as is_publishable, 
    live_revision
  from
    cr_items
  where
    item_id = :item_id

      </querytext>
</fullquery>

 
<fullquery name="unfinished_exists">      
      <querytext>
      
  select content_workflow__unfinished_workflow_exists( :item_id ) 

      </querytext>
</fullquery>

 
<fullquery name="get_child_types">      
      <querytext>
      
  select
    child_type, relation_tag, min_n, 
    o.pretty_name as child_type_pretty, 
    o.pretty_plural as child_type_plural, 
    case when max_n = null then '-'::text else max_n::text end as max_n,
    (
      select
        count(*)
      from
        cr_child_rels
      where
        parent_id = i.item_id
      and
        content_item__get_content_type( child_id ) = c.child_type
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
    case when max_n is null then '-'::text else max_n::text end as max_n,
    (
      select
        count(*)
      from
        cr_item_rels
      where
        item_id = i.item_id
      and
        content_item__get_content_type( related_object_id ) = r.target_type
      and
        relation_tag = r.relation_tag
    ) as rel_count
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

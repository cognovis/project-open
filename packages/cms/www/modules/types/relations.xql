<?xml version="1.0"?>
<queryset>

<fullquery name="get_module_id">      
      <querytext>
      
  select module_id from cm_modules where key = 'types'

      </querytext>
</fullquery>

 
<fullquery name="get_rel_types">      
      <querytext>
      
  select
    pretty_name, target_type, relation_tag, min_n, max_n
  from
    cr_type_relations r, acs_object_types o
  where
    o.object_type = r.target_type
  and
    r.content_type = :type
  order by
    pretty_name, relation_tag

      </querytext>
</fullquery>

 
<fullquery name="get_child_types">      
      <querytext>
      
  select
    pretty_name, child_type, relation_tag, min_n, max_n
  from
    cr_type_children c, acs_object_types o
  where
    c.child_type = o.object_type
  and
    c.parent_type = :type
  order by
    pretty_name, relation_tag

      </querytext>
</fullquery>

 
</queryset>

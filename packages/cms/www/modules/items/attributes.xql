<?xml version="1.0"?>
<queryset>

<fullquery name="get_type_info">      
      <querytext>
      
  select 
    o.object_type, t.table_name 
  from 
    acs_objects o, acs_object_types t
  where 
    o.object_id = :revision_id
  and
    o.object_type = t.object_type

      </querytext>
</fullquery>

 
</queryset>

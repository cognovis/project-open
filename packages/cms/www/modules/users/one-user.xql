<?xml version="1.0"?>
<queryset>

<fullquery name="get_groups">      
      <querytext>
      
  select 
    g.group_name, g.group_id
  from
    groups g, group_member_map m
  where
    m.group_id = g.group_id
  and
    m.member_id = :id

      </querytext>
</fullquery>

 
</queryset>

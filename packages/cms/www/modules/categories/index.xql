<?xml version="1.0"?>
<queryset>

<fullquery name="get_parent_id">      
      <querytext>
      
    select
      context_id
    from
      acs_objects
    where
      object_id = :id

      </querytext>
</fullquery>

 
</queryset>

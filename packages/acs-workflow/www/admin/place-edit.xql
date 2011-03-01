<?xml version="1.0"?>
<queryset>

<fullquery name="place_info">      
      <querytext>
      
    select p.place_name, p.sort_order,
           ot.pretty_name as workflow_name
    from   wf_places p, acs_object_types ot
    where  p.place_key = :place_key
    and    p.workflow_key = :workflow_key
    and    ot.object_type = p.workflow_key

      </querytext>
</fullquery>

 
</queryset>

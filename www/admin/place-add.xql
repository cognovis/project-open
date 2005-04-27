<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_info">      
      <querytext>
      
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key

      </querytext>
</fullquery>

 
<fullquery name="num_start_places">      
      <querytext>
       
    select case when count(*) = 0 then 0 else 1 end from wf_places 
    where  workflow_key = :workflow_key
    and    place_key = 'start'

      </querytext>
</fullquery>

 
<fullquery name="num_start_places">      
      <querytext>
       
    select case when count(*) = 0 then 0 else 1 end from wf_places 
    where  workflow_key = :workflow_key
    and    place_key = 'start'

      </querytext>
</fullquery>

 
</queryset>

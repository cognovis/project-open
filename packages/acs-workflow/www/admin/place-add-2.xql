<?xml version="1.0"?>
<queryset>

<fullquery name="num_places">      
      <querytext>
      
	    select count(*) 
	    from   wf_places
	    where  workflow_key = :workflow_key
	    and    place_name = :place_name
	
      </querytext>
</fullquery>

 
<fullquery name="num_places">      
      <querytext>
      
	    select count(*) 
	    from   wf_places
	    where  workflow_key = :workflow_key
	    and    place_name = :place_name
	
      </querytext>
</fullquery>

 
<fullquery name="place_keys">      
      <querytext>
      select place_key from wf_places where workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="place_add">      
      <querytext>
      
    insert into wf_places (place_key, place_name, workflow_key, sort_order)
    values (:place_key, :place_name, :workflow_key, :sort_order)

      </querytext>
</fullquery>

 
</queryset>

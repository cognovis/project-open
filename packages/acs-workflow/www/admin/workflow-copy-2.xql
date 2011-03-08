<?xml version="1.0"?>
<queryset>

<fullquery name="object_types">      
      <querytext>
      select object_type from acs_object_types
      </querytext>
</fullquery>

 
<fullquery name="pretty_names">      
      <querytext>
      select pretty_name from acs_object_types
      </querytext>
</fullquery>

 
<fullquery name="pretty_names">      
      <querytext>
      select pretty_name from acs_object_types
      </querytext>
</fullquery>

 
<fullquery name="workflow_info">      
      <querytext>
      
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key

      </querytext>
</fullquery>

 
</queryset>

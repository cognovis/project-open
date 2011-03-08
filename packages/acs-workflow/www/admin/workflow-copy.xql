<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_info">      
      <querytext>
      
    select ot.pretty_name as workflow_name
    from   acs_object_types ot
    where  ot.object_type = :workflow_key

      </querytext>
</fullquery>

 
<fullquery name="pretty_names">      
      <querytext>
      
    select pretty_name, pretty_plural
    from acs_object_types
    where object_type = :workflow_key

      </querytext>
</fullquery>

 
<fullquery name="object_types">      
      <querytext>
      select object_type from acs_object_types
      </querytext>
</fullquery>

 
<fullquery name="pretty_name">      
      <querytext>
      select pretty_name from acs_object_types
      </querytext>
</fullquery>

 
<fullquery name="pretty_plural_names">      
      <querytext>
      select pretty_plural from acs_object_types
      </querytext>
</fullquery>

 
</queryset>

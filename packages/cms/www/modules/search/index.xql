<?xml version="1.0"?>
<queryset>

<fullquery name="get_mime_types">      
      <querytext>
      
  select
    label, mime_type as value
  from 
    cr_mime_types

      </querytext>
</fullquery>

 
<fullquery name="get_results">      
      <querytext>
      
    select count(*) from ($sql_query) x
  
      </querytext>
</fullquery>

 
</queryset>

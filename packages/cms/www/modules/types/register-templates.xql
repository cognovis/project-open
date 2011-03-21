<?xml version="1.0"?>
<queryset>

<fullquery name="get_pretty_type">      
      <querytext>
      
  select 
    pretty_name
  from
    acs_object_types
  where
    object_type = :content_type  

      </querytext>
</fullquery>

 
<fullquery name="get_use_contexts">      
      <querytext>

         select use_context, use_context 
           from cr_template_use_contexts
       order by 1     

      </querytext>
</fullquery>

 
</queryset>

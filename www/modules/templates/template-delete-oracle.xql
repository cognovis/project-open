<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="delete_template">      
      <querytext>
      
      begin 
        content_template.del(:template_id); 
      end;
      </querytext>
</fullquery>


<fullquery name="get_status">      
      <querytext>
      
  select 't' from dual 
    where not exists (
      select 
        1 
      from
        cr_templates t, acs_objects o
      where
        o.object_id = t.template_id
      and
        o.context_id = :template_id
      and not exists (select 1 from cr_revisions 
                        where revision_id = t.template_id))

      </querytext>
</fullquery>

 
</queryset>

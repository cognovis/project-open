<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="delete_template">      
      <querytext>

        select content_template__delete(:template_id); 
      
      </querytext>
</fullquery>

<fullquery name="get_status">      
      <querytext>
      
  select 't'::text from dual 
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

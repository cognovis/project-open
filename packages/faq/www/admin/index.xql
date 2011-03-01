<?xml version="1.0"?>
<queryset>

<fullquery name="faq_select">
    <querytext>
      select faq_id, faq_name, disabled_p, 
      (select count(*) from faq_q_and_as where faq_id = f.faq_id) as num_q_and_as
         from  acs_objects o, faqs f
        where object_id = faq_id
          and context_id = :package_id
        order by lower(faq_name), faq_name
    </querytext>
</fullquery>

</queryset>
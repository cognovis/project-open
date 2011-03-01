<?xml version="1.0"?>
<queryset>

<fullquery name="faq_select">      
  <querytext>
      
    select faq_id, faq_name
      from acs_objects o, faqs f
      where object_id = faq_id
        and context_id = :package_id     
        and disabled_p = 'f'
    order by faq_name

  </querytext>
</fullquery>

</queryset>

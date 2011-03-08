<?xml version="1.0"?>
<queryset>

<fullquery name="disable_faq">
    <querytext>
          update faqs set disabled_p = 't' where faq_id = :faq_id
    </querytext>
</fullquery>

</queryset>
<?xml version="1.0"?>

<queryset>
    <fullquery name="get_faq">
        <querytext>
           select faq_name, separate_p from faqs where faq_id = :faq_id
        </querytext>
    </fullquery>

    <fullquery name="edit_faq">
        <querytext>
            update faqs  
            set    faq_name   = :faq_name, 
                   separate_p = :separate_p 
            where  faq_id     = :faq_id
        </querytext>
    </fullquery>

</queryset>

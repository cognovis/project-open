<?xml version="1.0"?>
<queryset>

  <fullquery name="question_info">
    <querytext>
	select question, answer,faq_name, f.faq_id 
        from faq_q_and_as qa, faqs f
        where entry_id = :entry_id
         and qa.faq_id = f.faq_id
    </querytext>
  </fullquery>

</queryset>
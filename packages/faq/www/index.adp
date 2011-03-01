<master>
<property name="context">@context;noquote@</property>
<property name="title">#faq.FAQs#</property>

<h1>#faq.FAQs#</h1>

<p>
      @notification_chunk;noquote@ 
</p>
<if @admin_p@ eq 1>
  <p>
    <a href="./admin" class="button" title="#faq.administer#">#faq.administer#</a>
  </p>
</if>


<if @faqs:rowcount@ eq 0>
 <p><i>#faq.lt_no_FAQs#</i></p>
</if>

<else>
 <ul>
  <multiple name=faqs>
   <li><a href="one-faq?faq_id=@faqs.faq_id@" title="#faq.View# @faqs.faq_name@">@faqs.faq_name@</a>
   </li>
  </multiple>
 </ul>
</else>






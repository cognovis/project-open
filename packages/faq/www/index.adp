<master>
<property name="context">@context;noquote@</property>
<property name="title">#faq.FAQs#</property>

<if @admin_p@ eq 1>
  <p>
    <a href="./admin" class="button">#faq.administer#</a>
  </p>
</if>


<if @faqs:rowcount@ eq 0>
 <i>#faq.lt_no_FAQs#</i><p>
</if>

<else>
 <ul>
  <multiple name=faqs>
   <li><a href="one-faq?faq_id=@faqs.faq_id@">@faqs.faq_name@</a>
   </li>
  </multiple>
 </ul>
</else>






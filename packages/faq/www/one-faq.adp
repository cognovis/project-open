<master>
<property name="context">@context;noquote@</property>
<property name="title">@faq_name;noquote@</property>

<if @one_question:rowcount@ eq 0>
  <i>#faq.lt_no_questions#</i>
  <p>
</if>
<else>

  <ol>
<multiple name="one_question">
<if @separate_p@ true>
    <li>
      <a href="one-question?entry_id=@one_question.entry_id@">@one_question.question;noquote@</a>
    </li>
</if>
<if @separate_p@ false>
    <li>
      <a href="#@one_question.entry_id@">@one_question.question;noquote@</a>
    </li>
</if>
</multiple>
  </ol>

<if @separate_p@ false>
  <hr>
  <ol>
<multiple name="one_question">
    <li>
      <a name=@one_question.entry_id@></a>
      <b>#faq.Q#</b> <i>@one_question.question;noquote@</i>
      <p>
      <b>#faq.A#</b> @one_question.answer;noquote@
      <p>
    </li>
</multiple>
  </ol>
</if>

</else>


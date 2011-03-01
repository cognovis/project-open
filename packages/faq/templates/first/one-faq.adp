<master src="master">
<property name="context_bar">@context_bar;noquote@</property>
<property name="title">@faq_name;noquote@</property>

<if @one_question:rowcount@ eq 0>
 <i>#faq.lt_no_questions#</i><p>
</if>

<else>
<table>
 <tr valign=top>
 <td width="30%">
 <ol>
  <multiple name=one_question>
   <if @separate_p@ eq "t">
   
   <li>
	<a href="one-question?entry_id=@one_question.entry_id@">@one_question.question@</a>

    </li>
	</if>
    <if @separate_p@ eq "f">

   <li>
      <a href="#@one_question.entry_id@">@one_question.question@</a>

    </li>
   </if>
  </multiple>
 </ol>
</td>
<if @separate_p@ eq "f">
<td>
 <ol>
  <multiple name=one_question>
   <li>
    <a name=@one_question.entry_id@></a>
     <b>#faq.Q#</b> @one_question.question@
     <P>
     <b>#faq.A#</b> @one_question.answer@
     <p>

   </li>
  </multiple>
 </ol>

</if>
</td>
</tr>
</table>
</else>



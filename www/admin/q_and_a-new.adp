<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>
<property name="focus">question.question</property>

<form action="@target@" name="question">
 <input type="hidden" name="insert_p" value="@insert_p@">
 <input type="hidden" name="faq_id" value="@faq_id@">


 <if @insert_p@ eq "t">
 	<input type="hidden" name="entry_id" value="@entry_id@">
 </if>

 <blockquote>
  <table>
  
   <tr valign="top">
    <th align="right"><br>#faq.Question#</td>
    <td><textarea name="question" rows="3" cols="50" wrap>@question_q@</textarea></td>
   </tr>
   <tr>
  <tr valign="top">
    <th align="right"><br>#faq.Answer#</td>
    <td><textarea name="answer" rows="10" cols="50" wrap>@answer_q@</textarea></td>
   </tr>
   <tr>
    <th></th>
    <td><input type="submit" value="@submit_label@"></td>
   </tr>
  </table>
 </blockquote>
</form>


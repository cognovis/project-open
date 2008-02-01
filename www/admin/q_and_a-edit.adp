<master>
<property name="context">@context;noquote@</property>
<property name="title">#faq.One_Question#</property>

<form action="@action@" method=post>
<input type=hidden name=entry_id value=@entry_id@>
 <table>
  <tr>
   <th align=right>#faq.Question#</th>
   <td>
    <textarea rows=4 cols=50 name=question>@question@</textarea>
   </td>
  </tr>
  <tr>
   <th align=right>#faq.Answer#</th>
   <td>
    <textarea rows=10 cols=50 name=answer>@answer@</textarea>
   </td>
  </tr>
  <tr>
   <td>&nbsp;</td>
   <td><input type=submit value="@submit_label@"></td>
  </tr>
  <tr>
   <td>&nbsp;</td>
   <td> <a href="@delete_url@">#faq.Delete_This_QA#</a></td>
  </tr>
 </table>
</form>




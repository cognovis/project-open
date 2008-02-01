<master></master>
<property name="context">@context;noquote@</property>
<property name="title">@title;noquote@</property>
<property name="focus">faq.faq_name</property>
  
<form action="@action@" name="faq">
  <input type="hidden" name="faq_id" value="@faq_id@">
  <blockquote>
    <table>
      <tr>
        <th align="right">#faq.Name#</th>
        <td><input size="50" name="faq_name" value="@faq_name@"></td>
      </tr>
      <tr>
        <th align="right">#faq.QA_on_Separate_Pages#</th>
        <td><select name="separate_p">
    	<option value=f>#faq.No#</option>
    	<option value=t>#faq.Yes#</option>
    	</select>
        </td>
      </tr>
      
      <tr>
        <th></th>
        <td><input type="submit" value="@submit_label@"></td>
    </table>
  </blockquote>
</form>

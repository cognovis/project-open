<master>
<property name="context">@context;noquote@</property>
<property name="title">@title;noquote@</property>

<form action="@action@">
 <input type="hidden" name="faq_id" value="@faq_id@">
 <blockquote>
  <table>
   <tr>
    <th align="right">#faq.Name#</th>
    <td><input size="50" name="faq_name" value="@faq_name@"></td>
   </tr>
   <tr>
    <th align="right">#faq.QA_On_Separate_Pages#</th>
    <td><select name=separate_p>
	<if @separate_p@ eq "t">
	<option value="t" selected>#faq.Yes#</option>
	<option value="f">#faq.No#</option>
	</if>
	<else>
	<option value="t">#faq.Yes#</option>
	<option value="f" selected>#faq.No#</option>
	</else>
	</select>
	
    </td>
   </tr>
  
   <tr>
    <th></th>
    <td><input type="submit" value="@submit_label@"></td>
  </table>
 </blockquote>
</form>


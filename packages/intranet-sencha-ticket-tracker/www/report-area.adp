<master>

<form>
<%= [export_form_vars invoice_id] %>
<table border=0 cellspacing=1 cellpadding=1>
		<tr>
		  <td class=rowtitle colspan=2 align=center>#intranet-core.Date#</td>
		</tr>
		<tr>
		  <td class=form-label>#intranet-core.Start_Date#</td>
		  <td class=form-widget>
		    <input type=textfield name=start_date value="@start_date@">
		  </td>
		</tr>
		<tr>
		  <td class=form-label>#intranet-core.End_Date#</td>
		  <td class=form-widget>
		    <input type=textfield name=end_date value="@end_date@">
		  </td>
		</tr>
		<tr>
		  <td class=form-label></td>
		  <td class=form-widget colspan=2>
		    <input type=submit>
		  </td>
		</tr>
</table>
</form>


@body;noquote@





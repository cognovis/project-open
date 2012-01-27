<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="main_navbar_label">expenses</property>

<h2>@page_title@</h2>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<form action=new-multiple-2 method=POST>
<%= [export_form_vars user_id_from_search return_url] %>
<table>
<tr class=rowtitle align=center>
<td class=rowtitle>#intranet-core.No#</td>
<td class=rowtitle>#intranet-expenses.Project#</td>
<td class=rowtitle>#intranet-expenses.Amount#</td>
<td class=rowtitle>#intranet-expenses.Currency#</td>
<if 1 ne @auto_vat_p@>
<td class=rowtitle>#intranet-expenses.Vat_Included#</td>
</if>
<td class=rowtitle>#intranet-expenses.Expense_Date#</td>
<td class=rowtitle>#intranet-core.Company#</td>
<td class=rowtitle>#intranet-expenses.Expense_Type#</td>
<td class=rowtitle>#intranet-expenses.Billable_p#</td>
<td class=rowtitle>#intranet-expenses.Expense_Payment_Type#</td>
<td class=rowtitle>#intranet-expenses.Receipt_reference#</td>
<td class=rowtitle>#intranet-expenses.Note#</td>
</tr>
@form_html;noquote@
<tr>
<td></td>
<td colspan=9><input type=submit name=#intranet-core.Submit#></td>
</tr>
</table>
</form>



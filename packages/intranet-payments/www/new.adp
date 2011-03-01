<master src="master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">finance</property>

@navbar;noquote@

<form action=new-2 method=POST>
@export_form_vars;noquote@

<table border=0>
<tr> 
  <td colspan=2 class=rowtitle>#intranet-payments.Payment_Details#</td>
</tr>
<tr> 
  <td>#intranet-payments.Cost_Name#</td>
  <td>
    <input type=hidden name=cost_id value=@cost_id@>
    <A HREF=/intranet-invoices/view?invoice_id=@cost_id@>@cost_name@</A>
  </td>
</tr>
<tr> 
  <td>#intranet-payments.Amount#</td>
  <td> 
     <input type=text name=amount value="@amount@" size=8>
     <%= [im_currency_select currency $currency] %>
  </td>
</tr>
<tr> 
  <td>#intranet-payments.Received#</td>
  <td>
     <input name=received_date value="@received_date@" size=10>
  </td>
</tr>
<tr>
  <td>#intranet-payments.Payment_Type#</td>
  <td><%= [im_payment_type_select payment_type_id $payment_type_id]%></td>
</tr>
<tr>
  <td>#intranet-payments.Note#</td>
  <td>
     <TEXTAREA NAME=note COLS=45 ROWS=5 wrap="<%=[im_html_textarea_wrap]%>">@note@</textarea>
  </td>
</tr>
 <tr> 
  <td valign=top> </td>
  <td>
    <input type=submit value="@button_name@" name=submit2>
    <input type=checkbox name=mark_document_as_paid_p value=1 checked>
    <%= [lang::message::lookup "" intranet-payments.Mark_invoice_as_paid "Mark %fin_document_type% as paid."] %>
  </td>
</tr>
</table>
</form>


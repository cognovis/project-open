<master src="master">
<property name="title">@page_title@</property>

@navbar;noquote@

<form action=new-2 method=POST>
<%= [export_form_vars payment_id provider_id return_url] %>

<table border=0>
<tr> 
  <td colspan=2 class=rowtitle>Payment Details</td>
</tr>
<tr> 
  <td>Cost Name</td>
  <td>
    <input type=hidden name=cost_id value=@cost_id@>
    <A HREF=/intranet-costs/view?cost_id=@cost_id@>@cost_name@</A>
  </td>
</tr>
<tr> 
  <td>Amount</td>
  <td> 
     <input type=text name=amount value="@amount@" size=8>
     <%= [im_currency_select currency $currency] %>
  </td>
</tr>
<tr> 
  <td>Received</td>
  <td>
     <input name=received_date value="@received_date@" size=10>
  </td>
</tr>
<tr>
  <td>Payment Type</td>
  <td><%= [im_payment_type_select payment_type_id $payment_type_id]%></td>
</tr>
<tr>
  <td>Note</td>
  <td>
     <TEXTAREA NAME=note COLS=45 ROWS=5 wrap=soft>@note@</textarea>
  </td>
</tr>
 <tr> 
  <td valign=top> </td>
  <td><input type=submit value="@button_name@" name=submit2></td>
</tr>
</table>
</form>

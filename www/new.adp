<master src="master">
<property name="title">@page_title@</property>

@navbar;noquote@

<form action=new-2 method=POST>
@export_form_vars;noquote@

<table border=0>
<tr> 
  <td colspan=2 class=rowtitle><#Payment_Details Payment Details#></td>
</tr>
<tr> 
  <td><#Cost_Name Cost Name#></td>
  <td>
    <input type=hidden name=cost_id value=@cost_id@>
    <A HREF=/intranet-costs/view?cost_id=@cost_id@>@cost_name@</A>
  </td>
</tr>
<tr> 
  <td><#Amount Amount#></td>
  <td> 
     <input type=text name=amount value="@amount@" size=8>
     <%= [im_currency_select currency $currency] %>
  </td>
</tr>
<tr> 
  <td><#Received Received#></td>
  <td>
     <input name=received_date value="@received_date@" size=10>
  </td>
</tr>
<tr>
  <td><#Payment_Type Payment Type#></td>
  <td><%= [im_payment_type_select payment_type_id $payment_type_id]%></td>
</tr>
<tr>
  <td><#Note Note#></td>
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


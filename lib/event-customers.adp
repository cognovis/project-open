<listtemplate name="customer_list"></listtemplate>

<form action=customer-add method=POST>
<%= [export_form_vars event_id return_url] %>
<table>
<tr>
<td><%= [im_company_select customer_id] %></td>
</tr>
<tr>
<td><input type=submit value="<%= [lang::message::lookup "" intranet-events.Add_Customers "Add Customer"] %>"></td>
</tr>
</table>
</form>

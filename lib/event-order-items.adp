
<form action="/intranet-events/order-item-update" method=GET>
<%= [export_form_vars event_id return_url] %>
<table>
<tr>
<td>
<listtemplate name="order_item_list"></listtemplate>
</td>
</tr>
<tr>
<td>
<input type=submit value="<%= [lang::message::lookup "" intranet-events.Update_Order_Items "Update Order Items"] %>">
</td>
</tr>
</table>
</form>

<form action=order-item-add method=POST>
<%= [export_form_vars event_id return_url] %>
<table>
<tr>
<td><%= [im_select -multiple_p 1 -size 10 -ad_form_option_list_style_p 1 -translate_p 0 order_item_id $order_item_options] %></td>
</tr>
<tr>
<td><input type=submit value="<%= [lang::message::lookup "" intranet-events.Add_Order_Items "Add Order Items"] %>"></td>
</tr>
</table>
</form>

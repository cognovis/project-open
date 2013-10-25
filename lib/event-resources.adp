<listtemplate name="resource_list"></listtemplate>

<form action=resource-add method=GET>
<%= [export_form_vars event_id return_url] %>
<table>
<tr>
<td><%= [im_select -ad_form_option_list_style_p 1 -translate_p 0 conf_item_id $conf_item_options] %></td>
</tr>
<tr>
<td><input type=submit value="<%= [lang::message::lookup "" intranet-events.Add_Resources "Add Resource"] %>"></td>
</tr>
</table>
</form>

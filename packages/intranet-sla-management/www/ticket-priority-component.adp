<if @sla_read@>
<listtemplate name="map_list"></listtemplate>

<br>
<b>@create_new_entry_msg@</b>:
<br>&nbsp;

<form action=/intranet-sla-management/ticket-priority-add method=GET>
<%= [export_form_vars project_id return_url] %>
<table>
<tr class=rowtitle>
<td class=rowtitle><%= [lang::message::lookup "" intranet-sla-management.Ticket_Type "Ticket Type"] %></td>
<td class=rowtitle><%= [lang::message::lookup "" intranet-sla-management.Ticket_Severity "Severity"] %></td>
<td class=rowtitle><%= [lang::message::lookup "" intranet-sla-management.Prio "Prio"] %></td>
</tr>
<tr>
<td><%= [im_category_select "Intranet Ticket Type" ticket_type_id ""] %></td>
<td><%= [im_category_select "Intranet Ticket Status" ticket_severity_id ""] %></td>
<td><%= [im_category_select "Intranet Ticket Priority" ticket_prio_id ""] %></td>
</tr>
<tr><td colspan=3><input type=submit value='@create_new_entry_msg@'></td></tr>
</table>
</form>

</if>


<form action="/intranet-events/participant-update" method=GET>
<%= [export_form_vars event_id return_url] %>
<table>
<tr>
<td>
<listtemplate name="participant_list"></listtemplate>
</td>
</tr>
<tr>
<td>
<input type=submit value="<%= [lang::message::lookup "" intranet-events.Update_Participants "Update Participants"] %>">
</td>
</tr>
</table>
</form>

<form action=participant-add method=POST>
<%= [export_form_vars event_id return_url] %>
<table>
<tr>
<td><%= [im_select -ad_form_option_list_style_p 1 -translate_p 0 user_id $participant_options] %></td>
<td><input type=submit value="<%= [lang::message::lookup "" intranet-events.Add_Participants "Add Participant"] %>"></td>
</tr>
</table>
</form>

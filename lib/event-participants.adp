<listtemplate name="participant_list"></listtemplate>

<form action=participant-add method=POST>
<%= [export_form_vars event_id return_url] %>
<table>
<tr>
<td><%= [im_select -ad_form_option_list_style_p 1 -translate_p 0 user_id $participant_options] %></td>
</tr>
<tr>
<td><input type=submit value="<%= [lang::message::lookup "" intranet-events.Add_Participants "Add Participant"] %>"></td>
</tr>
</table>
</form>

<master src="../../intranet-core/www/master">
<property name=title>#intranet-core.Add_a_user#</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">user</property>

<H1>#intranet-core.Send_Notification#</H1>
To: <%=$name_recipient%>
<table>
<form method="post" action="member-notify">
@export_vars;noquote@

<tr>
  <td>
<textarea name=subject rows=1 cols=70 wrap="<%=[im_html_textarea_wrap]%>">
#intranet-cust-koernigweber.Mail_Reminder_Log_Hours_Subject#
</textarea>
  </td>
</tr>

<tr>
  <td>
<textarea name=message rows=10 cols=70 wrap="<%=[im_html_textarea_wrap]%>">
#intranet-cust-koernigweber.Mail_Reminder_Log_Hours_Text#
</textarea>
  </td>
</tr>

<tr>
  <td>
<center>
<input type="submit" value="Erinnerung senden" />
<input type=checkbox name=send_me_a_copy value=1 checked>
<%= [lang::message::lookup "" intranet-core.Send_me_a_copy "Send me a copy"] %>
</center>
  </td>
</tr>
</form>
</table>

</p>




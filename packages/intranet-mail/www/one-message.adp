<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>

<a href="@return_url;noquote@">#intranet-mail.Go_Back#</a> | <a href="@forward_url;noquote@">#intranet-mail.Forward#</a> | <a href="@reply_url;noquote@">#intranet-mail.Reply_To#</a>
<br><br>
<div style="background-color: #eee; padding: .5em;">
<table>
<tr><td>
#intranet-mail.Sender#:</td><td>@sender;noquote@</tr><td>
#intranet-mail.Recipient#:</td><td>@recipient;noquote@</tr><td>
#intranet-mail.CC#:</td><td>@cc_string;noquote@</tr><td>
#intranet-mail.BCC#:</td><td>@bcc_string;noquote@</tr><td>
#intranet-mail.Subject#:</td><td>@subject;noquote@</tr><td>
#intranet-mail.Attachments#:</td><td>@download_files;noquote@</tr><td>
#intranet-mail.MessageID#:</td><td>@message_id;noquote@</tr>
</table>
</div>
<p>
@body;noquote@

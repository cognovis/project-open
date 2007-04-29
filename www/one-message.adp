<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>

<a href="@return_url;noquote@">#mail-tracking.Go_Back#</a> | <a href="forward?log_id=@log_id@">#mail-tracking.Forward#</a>
<br><br>
<div style="background-color: #eee; padding: .5em;">
<table>
<tr><td>
#mail-tracking.Sender#:</td><td>@sender;noquote@</tr><td>
#mail-tracking.Recipient#:</td><td>@recipient;noquote@</tr><td>
#mail-tracking.CC#:</td><td>@cc_string;noquote@</tr><td>
#mail-tracking.BCC#:</td><td>@bcc_string;noquote@</tr><td>
#mail-tracking.Subject#:</td><td>@subject;noquote@</tr><td>
#mail-tracking.Attachments#:</td><td>@download_files;noquote@</tr><td>
#mail-tracking.MessageID#:</td><td>@message_id;noquote@</tr>
</table>
</div>
<p>
@body;noquote@

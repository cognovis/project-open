<master>
<property name="title">@pretty_action;noquote@ a Subscription</property>
<property name="context">@context;noquote@</property>

<form action=subscr-ae-2>
<table cellpadding=2 cellspacing=2 border=0 bgcolor=e0e0e0>
<tr bgcolor=efefef align=left valign=top><th>Channel:</th>
<td><if @channel_link@ nil>@channel_title@</if><else>
<a href="@channel_link@">@channel_title@</a></else></td></tr>
<tr bgcolor=efefef align=left valign=top><th>Impl Name:</th>
<td><code>@impl_name@</code></td></tr>
<tr bgcolor=efefef align=left valign=top><th>Timeout:</th>
<td><input type=text name=timeout value="@timeout@"><br>
<input type=radio name=timeout_units value="s" checked>secs
<input type=radio name=timeout_units value="m">mins
<input type=radio name=timeout_units value="h">hours
<input type=radio name=timeout_units value="d">days
</td></tr>
<tr bgcolor=efefef><td colspan=2 align=center><input type=submit value="@pretty_action@"></tr>
</table>
@formvars;noquote@
</form>


<if @sla_read@>

<form action="/intranet-sla-management/service-hours-save" method=POST>
<%= [export_form_vars return_url sla_id] %>
<table cellspacing=0 cellpadding=0>
<tr class=rowtitle>
<td class=rowtitle><%= [lang::message::lookup "" intranet-sla-management.Day "Day"] %></td>
	<multiple name=hours>
	<td class=rowtitle align=center>@hours.hour@</td>
	</multiple>
</tr>
@body_html;noquote@
<tr>
<td colspan=25>
	<input type=submit value=#intranet-core.Submit#>
</td>
</tr>
</table>
</form>

</if>

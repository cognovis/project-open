<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">helpdesk</property>

<h1>@page_title@</h1>

<p>
<%= [lang::message::lookup "" intranet-sla-management.Associate_Params_Msg "This page allows you to associated your params with other objects."] %>
</p>
<br>

<form action=related-objects-associate-2 method=GET>
<%= [export_form_vars tid return_url] %>
<table>
	<tr>
	<th colspan=2><%= [lang::message::lookup "" intranet-sla-management.Associate_With "Associate With"] %></th>
	<th>	<%= [lang::message::lookup "" intranet-sla-management.Object Object] %></th>
	<th>	<%= [lang::message::lookup "" intranet-sla-management.Comment Comment] %></th>
	</tr>

	<tr>
	<td>	<input type=radio name=target_object_type value=indicator checked></td>
	<td>	<%= [lang::message::lookup "" intranet-sla-management.Object_Type_Indicator "Indicator"] %></td>
	<td>	<%= [im_report_select -report_type_id [im_report_type_indicator] -indicator_object_type "im_sla_parameter" indicator_id] %><br>
	</td>
	<td>	<%= [lang::message::lookup "" intranet-sla-management.Associate_Msg_Indicator "
		Add a new indicator to this SLA parameter."] %>
	</td>
	</tr>

	<tr>
	<td>&nbsp;</td>
	<td><input type=submit name=submit value="<%= [lang::message::lookup "" intranet-sla-management.Associate_Assoc_Action Associate] %>"></td>
	<td>&nbsp;</td>
	</tr>

</table>
</form>
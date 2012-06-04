<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>
<property name="main_navbar_label">reporting</property>

<h1>@page_title@</h1>

<table>
<tr>
<td>

	<form action="/intranet-reporting-openoffice/test-list.odp" method=GET>
	<table>
	<tr class=rowtitle>
	<td><%= [lang::message::lookup "" intranet-reporting-openoffice.Start_date "Start Date"] %></td>
	<td><input type=text name=report_start_date value="@report_start_date@"></td>
	</tr>
	<tr>
	<td></td>
	<td><input type=submit name="<%= [lang::message::lookup "" intranet-core.Submit "Sumit"] %>"></td>
	</tr>
	</table>
	</form>


</td>
<td>
	

</td>
</tr>
</table>

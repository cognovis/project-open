<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>
<property name="main_navbar_label">reporting</property>

<h1>@page_title@</h1>

<table>
<tr>
<td>

	<form action="/intranet-reporting-openoffice/presupuestario-avance-accumulado-clientes.odp" method=GET>
	<table>
	<tr class=roweven>
		<td><%= [lang::message::lookup "" intranet-reporting-openoffice.Start_date "Start Date"] %></td>
		<td><input type=text name=report_start_date value="@report_start_date@"></td>
	</tr>
	<tr class=roweven>
		<td><%= [lang::message::lookup "" intranet-reporting-openoffice.End_date "End Date"] %></td>
		<td><input type=text name=report_end_date value="@report_end_date@"></td>
	</tr>
	<tr class=rowodd>
		<td><%= [lang::message::lookup "" intranet-reporting-openoffice.Customer "Customer"] %></td>
		<td><%= [im_company_select -include_empty_p 0 report_customer_id] %></td>
	</tr>
	<tr class=rowodd>
		<td><%= [lang::message::lookup "" intranet-reporting-openoffice.Project_Type "Project Type"] %></td>
		<td><%= [im_category_select "Intranet Project Type" report_project_type_id 2501] %></td>
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

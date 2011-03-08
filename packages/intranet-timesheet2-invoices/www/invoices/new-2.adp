<!-- packages/intranet-timesheet2-invoices/www/invoices/new-2.adp -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../../intranet-core/www/master">
<property name="title"></property>
<property name="main_navbar_label">finance</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<table cellspacing=5 cellpadding=0>
<tr valign=top>
<td>

	<table cellspacing=0 cellpadding=1>
	<tr class=rowtitle>
	    <td class=rowtitle>Filter Reported Hours</td>
	</tr>
	<tr valign=top>
	    <td><formtemplate id=filter></formtemplate></td>
	</tr>
	</table>

</td>
<td>
	<table cellspacing=0 cellpadding=1>
	<tr>
	<td>
		<h4><%= [lang::message::lookup "" intranet-timesheet2-invoices.Timesheet_Invoicing_Wizard "Timesheet Invoicing Wizard"] %></h4>
		<%= [lang::message::lookup "" intranet-timesheet2-invoices.Timesheet_Invoicing_Wizard_help "
		This wizard allows you to create a '@target_cost_type@' financial 
		document from project data in four different ways:"] %>
		<ul>
		<li><%= [lang::message::lookup "" intranet-timesheet2-invoices.Planned_Units_help "Planned Units: Estimated number of hours for each task, as specified during project planning."] %>
		<li><%= [lang::message::lookup "" intranet-timesheet2-invoices.Billable_Units_help "Billable Units: Billable number of hours for each task. Tends to be equal to Planned Units."] %>
		<li><%= [lang::message::lookup "" intranet-timesheet2-invoices.All_Reported_Hours_help "All Reported Hours: All timesheet hours logged by anybody since the creation of the task or project."] %>
		<li><%= [lang::message::lookup "" intranet-timesheet2-invoices.Reported_Units_Interval_help "Reported Units in Interval: Hours logged between 'Start Date' and 'End Date' (see filter above)."] %>
		</ul>
	</td>
	</tr>
	</table>
</td>
</tr>
</table>

<form action=new-3 method=POST>
<%= [export_form_vars company_id invoice_currency cost_center_id target_cost_type_id return_url select_project start_date end_date] %>

<table cellpadding=1 cellspacing=1 border=0>
    @task_table_rows;noquote@

    <tr>
	<td colspan=10 align=right>
		<input type=checkbox name=aggregate_tasks_p value=1 checked>
		<%= [lang::message::lookup "" intranet-timesheet2-invoices.Aggregate_tasks_of_the_same_material "Aggregate tasks of the same Material"] %>

		<input type=submit name=submit value='<%= [lang::message::lookup "" intranet-timesheet2-invoices.lt_Select_Tasks_for_Invo "Select Tasks for Invoicing"] %>'>

        </td>
    </tr>
    <tr><td>&nbsp;</td></tr>

</table>
</form>

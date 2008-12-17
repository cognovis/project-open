<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">helpdesk</property>
<property name="sub_navbar">@ticket_navbar_html;noquote@</property>

<h1>@page_title@</h1>

<p>
<%= [lang::message::lookup "" intranet-helpdesk.No_SLA_associated_with_you "It seems that there is currently no 'Service Level Agreement' (SLA) associated with your account. <br>"] %>
<%= [lang::message::lookup "" intranet-helpdesk.A_SLA_is_required "A SLA is required in order to associate the cost of your service requests to your company."] %>

</p>
<p>&nbsp;</p>

<p>
<%= [lang::message::lookup "" intranet-helpdesk.To_request_a_new_SLA "To request a new SLA please let us know about your company and how to contact you:"] %>
</p>

<form action=request-sla-2 method=POST>
<table>
<tr>
<td class="form-label"><%= [lang::message::lookup "" intranet-helpdesk.Your_Company "Your Company"] %></td>
<td class="form-widget">
	<input type=text size=40 name=company_name>
</td>
</tr>

<tr>
<td class="form-label"><%= [lang::message::lookup "" intranet-helpdesk.Contact_Email_Tel "Contact (Email or Tel)"] %></td>
<td class="form-widget">
	<input type=text size=40 name=contact>
</td>
</tr>

<tr>
<td class="form-label"><%= [lang::message::lookup "" intranet-helpdesk.Comment "Comment"] %></td>
<td class="form-widget">
	<textarea cols=40 rows=6 name=comment></textarea>
</td>
</tr>

<tr>
<td class="form-label"> </td>
<td class="form-widget">
	<input type=submit value='<%= [lang::message::lookup "" intranet-helpdesk.Submit "Submit"] %>'>
</td>
</tr>

</table>
</form>
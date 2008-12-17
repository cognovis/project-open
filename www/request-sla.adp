<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">helpdesk</property>
<property name="sub_navbar">@ticket_navbar_html;noquote@</property>

<h1>@page_title@</h1>

<p>
It seems that there is currently no "Service Level Agreement" (SLA)
associated with your account. <br>
A SLA is required in order to bill the cost of your service requests
to a specific customer. 
</p>
<p>&nbsp;</p>

<p>
To request a new SLA please let us know about your company and how 
to contact you:
</p>

<form action=request-sla-2 method=POST>
<table>
<tr>
<td class="form-label">Your Company</td>
<td class="form-widget">
	<input type=text size=40 name=company_name>
</td>
</tr>

<tr>
<td class="form-label">Contact (Email or Tel)</td>
<td class="form-widget">
	<input type=text size=40 name=contact>
</td>
</tr>

<tr>
<td class="form-label">Comment</td>
<td class="form-widget">
	<textarea cols=40 rows=6 name=comment></textarea>
</td>
</tr>

<tr>
<td class="form-label"> </td>
<td class="form-widget">
	<input type=submit value="Submit">
</td>
</tr>

</table>
</form>
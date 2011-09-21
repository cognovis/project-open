<!-- packages/intranet-forum/www/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->
<!-- @author Klaus Hofeditz (klaus.hofeditz@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">reporting</property>


<form>
<%= [export_form_vars opened_projects project_id] %>

<table border=0 cellspacing=1 cellpadding=1>
<tr valign=top>
	<td>
	<table border=0 cellspacing=1 cellpadding=1>
	<tr>
	  <td class=form-label>Start Date</td>
	  <td class=form-widget>
	    <input type=textfield name=start_date value=@start_date@>
	  </td>
	</tr>
	<tr>
	  <td class=form-label>End Date</td>
	  <td class=form-widget>
	    <input type=textfield name=end_date value=@end_date@>
	  </td>
	</tr>
	<tr>
	  <td class=form-label>Customer</td>
	  <td class=form-widget>
	    <%= [im_company_select customer_id $customer_id] %>
	  </td>
	</tr>
	<tr>
	  <td class=form-label></td>
	  <td class=form-widget><input type=submit value=Submit></td>
	</tr>
	</table>
	</td>
	<td>
	<ul>
		<li>Report tracks actual hours worked per task against planned hours per task (Planned Value)</li>
		<li>List of projects can be filetered by start/end date and customer</li>
		<li>Hours for project members are only shown when logged btw. start and end date</li>
	</ul>
	</td>
</tr>
</table>
</form>


<listtemplate name="project_list"></listtemplate>
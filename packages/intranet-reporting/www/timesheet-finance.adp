<!-- packages/intranet-forum/www/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">reporting</property>


<form>
<%= [export_form_vars opened_projects project_id] %>

<table border=0 cellspacing=1 cellpadding=1>
<tr valign=top><td>

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
	  <td class=form-label>User</td>
	  <td class=form-widget>
	    <%= [im_employee_select_multiple employee_id $employee_id 6 multiple] %>
	  </td>
	</tr>
	<tr>
	  <td class=form-label></td>
	  <td class=form-widget><input type=submit value=Submit></td>
	</tr>
	</table>

</td><td>

	<table border=0 cellspacing=1 cellpadding=1>
	<tr>
	  <td class=form-label>Show<br>Fields</td>
	  <td class=form-widget>
	    <%= [im_select -translate_p 0 -multiple_p 1 -size 15 display_fields $display_field_options $display_fields] %>
	  </td>
	</tr>
	</table>

</td></tr>
</table>
</form>



<listtemplate name="project_list"></listtemplate>
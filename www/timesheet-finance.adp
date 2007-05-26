<!-- packages/intranet-forum/www/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../intranet-core/www/master">
<property name="title">project employee report</property>
<property name="main_navbar_label">reporting</property>


<form>
<table border=0 cellspacing=1 cellpadding=1>
<tr valign=top><td>
	<table border=0 cellspacing=1 cellpadding=1>
	<tr>
	  <td class=form-label>Level of Details</td>
	  <td class=form-widget>
	    <%= [im_select -translate_p 0 level_of_detail $level_options $level_of_detail] %>
	  </td>
	</tr>
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
	    <%= [im_company_select company_id $company_id] %>
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
</td></tr>
</table>
</form>



<listtemplate name="project_list"></listtemplate>
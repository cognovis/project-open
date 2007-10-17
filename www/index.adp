<!-- packages/intranet-forum/www/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">@main_navbar_label@</property>

<br>
@project_menu;noquote@

<table border=0 cellpadding=0 cellspacing=0>
<tr>
  <td> <!-- TD for the left hand filter HTML -->

	<form method=get action='index'>
	<%= [export_form_vars orderby] %>

	<table>
	<tr>
	    <td colspan='2' class=rowtitle align=center>
	      <%= [lang::message::lookup "" intranet-expenses.Filter_Expenses "Filter Expenses"] %>
	    </td>
	</tr>

	<tr>
	    <td class=form-label><%= [lang::message::lookup "" intranet-expenses.Unassigned_items "Unassigned:"] %></td>
	    <td class=form-widget><%= [im_select -translate_p 0 unassigned $unassigned_p_options $unassigned] %></td>
	</tr>

<!--
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
-->

	<tr>
	    <td class=form-label><%= [lang::message::lookup "" intranet-expenses.Project "Project"] %></td>
	    <td class=form-widget><%= [im_project_select -include_all 0 -exclude_status_id [im_project_status_closed] project_id $org_project_id] %></td>
	</tr>

	<tr>
	    <td class=form-label><%= [lang::message::lookup "" intranet-expenses.Expense_Type "Type"] %></td>
	    <td class=form-widget><%= [im_category_select -include_empty_p 1 "Intranet Expense Type" expense_type_id $expense_type_id] %></td>
	</tr>

	<tr>
	    <td class=form-label></td>
	    <td class=form-widget><input type=submit></td>
	</tr>


	</table>
	</form>

  </td> <!-- end of left hand filter TD -->
  <td>&nbsp;</td>
  <td valign=top width='30%'>
    <table border=0 cellpadding=0 cellspacing=0>
    <tr>
      <td class=rowtitle align=center>
	#intranet-core.Admin_Links#
      </td>
    </tr>
    <tr>
      <td>
	@admin_links;noquote@
      </td>
    </tr>
    </table>
  </td>
</tr>
</table>

<br>

<h2>@page_title;noquote@</h2>
<listtemplate name="@list_id@"></listtemplate>


<h2>#intranet-expenses.Expense_Invoices#</h2>
<listtemplate name="@list2_id@"></listtemplate>


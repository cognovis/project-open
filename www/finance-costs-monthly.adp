<!-- ~/packages/intranet-reporting-finance/www/finance-costs-monthly.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">reporting</property>


<form>
<%= [export_form_vars project_id] %>

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
	  <td class=form-label>Provider</td>
	  <td class=form-widget>
	    <%= [im_company_select prov_id $prov_id "" "Provider"] %>
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
	  <td class=form-label>sdfg</td>
	  <td class=form-widget>
		asdf
	  </td>
	</tr>
	</table>

</td></tr>
</table>
</form>


<table>
@upper_dim_html;noquote@
@body_html;noquote@
</table>



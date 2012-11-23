<!-- ~/packages/intranet-reporting-finance/www/finance-costs-monthly-update-external-company.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">reporting</property>


<form action=finance-costs-monthly-update-external-company-2 method=GET>
<%= [export_form_vars return_url] %>
<table border=0 cellspacing=1 cellpadding=1>
	<tr>
	  <td class=form-label>Old external company name</td>
	  <td class=form-widget>
	    @external_company_name@
	    <input type=hidden name=old_external_company_name value="@external_company_name@">
	  </td>
	</tr>
	<tr>
	  <td class=form-label>New external company name</td>
	  <td class=form-widget>
	    <input type=textfield name=new_external_company_name value="@external_company_name@">
	  </td>
	</tr>
	<tr>
	  <td class=form-label></td>
	  <td class=form-widget><input type=submit value="<%= [lang::message::lookup "" intranet-reporting-finance.Replace_Name "Replace Name"] %>"></td>
	</tr>
</table>
</form>



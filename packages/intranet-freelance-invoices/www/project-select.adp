<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<form action=project-select-2 method=POST>
<%= [export_form_vars return_url] %>

        <table border=0 cellPadding=0 cellspacing=2>

	        <tr><td align=middle class=rowtitle colspan=2>
		  #intranet-invoices.Select_Customer#
		</td></tr>
	        <tr>
	          <td  class=rowodd>#intranet-core.Customer#</td>
	          <td  class=rowodd> 
		    @customer_select;noquote@
	          </td>
	        </tr>
	        <tr class=roweven>
	          <td colspan=2 align=right>
		    <input type=submit name=#intranet-core.Submit#>
		  </td>
	        </tr>

        </table>

</form>


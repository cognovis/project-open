<master src="../../intranet-core/www/master">
<property name="title">Purchase Orders</property>
<property name="main_navbar_label">finance</property>

<form action="/intranet-invoices/new-2" method=POST>
<%= [export_form_vars company_id invoice_id freelance_id provider_id project_id select_project cost_status_id return_url] %>

<%= [im_costs_navbar "none" "/intranet/invoicing/index" "" "" [list]] %>

<!-- Purchase Order Data and Receipient Tables -->

  <table cellpadding=0 cellspacing=0 bordercolor=#6699CC border=0 width=100%>
    <tr valign=top> 
      <td>
		<!-- Invoice Data -->
	        <table border=0 cellPadding=0 cellspacing=2>
	        <tr><td align=middle class=rowtitle colspan=2>Purchase Order Data</td></tr>
	        <tr>
	          <td  class=rowodd>Purchase Order nr.:</td>
	          <td  class=rowodd> 
	            <input type=text name=invoice_nr size=15 value='@invoice_nr@'>
	          </td>
	        </tr>
	        <tr> 
	          <td  class=roweven>Purchase Order date:</td>
	          <td  class=roweven> 
	            <input type=text name=invoice_date size=15 value='@invoice_date@'>
	          </td>
	        </tr>

	        <tr> 
	          <td class=roweven>@cost_center_label@</td>
	          <td class=roweven>@cost_center_select;noquote@</td>
	        </tr>
<!--
	        <tr> 
	          <td class=roweven>Payment terms</td>
	          <td class=roweven> 
	            <input type=text name=payment_days size=5 value='@default_payment_days@'>
	            days date of invoice</td>
	        </tr>
	        <tr> 
	          <td class=rowodd>Payment Method</td>
	          <td class=rowodd><%= [im_invoice_payment_method_select payment_method_id $default_payment_method_id] %></td>
	        </tr>
-->
	        <tr> 
	          <td class=roweven>Purchase Order template:</td>
	          <td class=roweven>
			<%= [im_cost_template_select template_id $default_invoice_template_id] %>
			<input type=hidden name=cost_type_id value=@target_cost_type_id@>
		  </td>
	        </tr>
<!--
                <tr>
                  <td class=roweven>Type</td>
                  <td class=roweven>
		    <%= [im_cost_type_select cost_type_id $target_cost_type_id [im_cost_type_provider_doc]] %>
		  </td>
                </tr>
-->
	        </table>

      </td>
      <td></td>
      <td align=right>

	        <table border=0 cellspacing=2 cellpadding=0 >
	        <tr>
		  <td align=center valign=top class=rowtitle colspan=2> Recipient</td>
		</tr>
	        <tr> 
	          <td  class=rowodd>Company name</td>
	          <td  class=rowodd>
	            <A href="/intranet/companies/view?company_id=@provider_id@">
			@company_name@
		    </A>
	          </td>
	        </tr>
	        <tr> 
	          <td  class=roweven>VAT</td>
	          <td  class=roweven>@vat_number@</td>
	        </tr>
	        <tr> 
	          <td  class=rowodd>#intranet-core.Contact#</td>
	          <td  class=rowodd>@company_contact_select;noquote@</td>
	        </tr>
	        <tr> 
	          <td  class=roweven>Adress</td>
	          <td  class=roweven>@address_line1@ <br> @address_line2@</td>
	        </tr>
	        <tr> 
	          <td  class=rowodd>Zip</td>
	          <td  class=rowodd>@address_postal_code@</td>
	        </tr>
	        <tr> 
	          <td  class=roweven>Country</td>
	          <td  class=roweven>@country_name@</td>

	        </tr>
	        <tr> 
	          <td  class=rowodd>Phone</td>
	          <td  class=rowodd>@phone@</td>
	        </tr>
	        <tr> 
	          <td  class=roweven>Fax</td>
	          <td  class=roweven>@fax@</td>
	        </tr>
	        <tr> 
	          <td  class=rowodd>Email</td>
	          <td  class=rowodd>@company_contact_email@</td>
	        </tr>
	        </table>


    </tr>
  </table>

  <!-- the list of tasks (invoicable items) -->
  <table cellpadding=2 cellspacing=2 border=0 width='100%'>
    @task_table;noquote@
  </table>

  <!-- the list of task sums, distinguised by type and UOM -->
  <table width=100%>
    <tr>
      <td align=right><table border=0 cellspacing=2 cellpadding=1>
        @task_sum_html;noquote@

		<!-- Grand Total -->
	        <tr>
	          <td> 
	          </td>
	          <td colspan=4 align=right> 
	            <table border=0 cellspacing=1 cellpadding=0>
	              <tr> 
	                <td>VAT&nbsp;</td>
	                <td><input type=text name=vat value='@default_vat@' size=4> % &nbsp;</td>
	              </tr>
	            </table>
	          </td>
	        </tr>
	        <tr> 
	          <td> 
	          </td>
	          <td colspan=4 align=right> 
	            <table border=0 cellspacing=1 cellpadding=0>
	              <tr> 
	                <td>TAX&nbsp;</td>
	                <td><input type=text name=tax value='@default_tax@' size=4> % &nbsp;</td>
	              </tr>
	            </table>
	          </td>
	        </tr>
	        <tr> 
	          <td>&nbsp; </td>
	          <td colspan=6 align=right> 
	              <input type=submit name=submit value='@button_text@'>
	          </td>
	        </tr>


      </td>
    </tr>
  </table>

</form>

<!-- the list of reference prices -->
<table>
  @reference_price_html;noquote@
</table>

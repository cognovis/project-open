<!-- packages/intranet-timesheet2-invoices/www/invoices/new-3.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">finance</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<form action=new-4 method=POST>
<%= [export_form_vars customer_id provider_id invoice_id cost_status_id start_date end_date select_project return_url invoice_hour_type] %>

@include_task_html;noquote@

  <!-- Invoice Data and Receipient Tables -->
  <table cellpadding=0 cellspacing=0 bordercolor=#6699CC border=0 width=100%>
    <tr valign=top> 
      <td>

        <table border=0 cellPadding=0 cellspacing=2>


	<!-- Invoice Data -->
        <tr>
	  <td align=middle class=rowtitle colspan=2>
	    #intranet-timesheet2-invoices.Invoice_Data#
	  </td>
	</tr>
        <tr>
          <td class=rowodd>#intranet-timesheet2-invoices.Invoice_nr#:</td>
          <td class=rowodd> 
            <input type=text name=invoice_nr size=15 value='@invoice_nr@'>
          </td>
        </tr>
        <tr> 
          <td class=roweven>#intranet-timesheet2-invoices.Invoice_date#:</td>
          <td class=roweven> 
            <input type=text name=invoice_date size=15 value='@invoice_date@'>
          </td>
        </tr>
        <tr>
          <td class=roweven>@cost_center_label@</td>
          <td class=roweven>
          @cost_center_select;noquote@
          </td>
        </tr>
        <tr> 
          <td class=rowodd>#intranet-timesheet2-invoices.Type#</td>
          <td class=rowodd>
	    <%= [im_cost_type_select cost_type_id $cost_type_id [im_cost_type_company_doc]] %>
	  </td>
        </tr>

<if @cost_type_id@ eq @cost_type_invoice@>
        <tr> 
          <td class=roweven>#intranet-timesheet2-invoices.Payment_terms#</td>
          <td class=roweven> 
            <input type=text name=payment_days size=5 value='@default_payment_days@'>
            days date of invoice</td>
        </tr>
        <tr> 
          <td class=rowodd>
	    #intranet-timesheet2-invoices.Payment_Method#
	  </td>
          <td class=rowodd>
	    <%= [im_invoice_payment_method_select payment_method_id $default_payment_method_id] %>
	  </td>
        </tr>
</if>

        <tr> 
          <td class=roweven>#intranet-timesheet2-invoices.Invoice_template#:</td>
          <td class=roweven>
	    <%= [im_cost_template_select template_id $default_template_id] %>
	  </td>
        </tr>
        </table>

      </td>
      <td></td>
      <td align=right>

        <table border=0 cellspacing=2 cellpadding=0 >
        <tr>
	  <td align=center valign=top class=rowtitle colspan=2>
	    #intranet-timesheet2-invoices.Recipient#
	  </td>
	</tr>
        <tr>
          <td  class=rowodd>#intranet-invoices.Company_name#</td>
          <td  class=rowodd>
            <A href="/intranet/companies/view?company_id=@company_id@">@company_name@</A>
          </td>
        </tr>
        <tr>
          <td  class=roweven>#intranet-invoices.VAT#</td>
          <td  class=roweven>@vat_number@</td>
        </tr>
        <tr>
          <td  class=rowodd>#intranet-invoices.Invoice_Address#</td>
          <td  class=rowodd><%= [im_company_office_select invoice_office_id $invoice_office_id $company_id] %></td>
        </tr>
        <tr>
          <td  class=rowodd>#intranet-core.Contact#</td>
          <td  class=rowodd>
            <%= [im_company_contact_select company_contact_id $company_contact_id $company_id] %>
          </td>
        </tr>
	<tr>
	  <td class=roweven>#intranet-invoices.Note#</td>
          <td class=roweven>
	    <textarea name=note rows=6 cols=40 wrap="<%=[im_html_textarea_wrap]%>"></textarea>
	  </td>
	</tr>
        </table>

    </tr>
  </table>

  <!-- the list of tasks (invoicable items) -->
  <div align=right>
  <table cellpadding=2 cellspacing=2 border=0>
    <%= [im_timesheet_invoicing_project_hierarchy \
			 -select_project $select_project \
			 -start_date $invoicing_start_date \
			 -end_date $invoicing_end_date \
			 -invoice_hour_type $invoice_hour_type \
			 -include_task $include_task \
	]
    %>

  </table>
  </div>

  <!-- the list of task sums, distinguised by type and UOM -->
  <table width=100%>
    <tr>
      <td align=right><table border=0 cellspacing=2 cellpadding=1>
        @task_sum_html;noquote@


	<!-- grand_total -->
        <tr>
          <td></td>
<if @material_enabled_p@>
          <td></td>
</if>
<if @project_type_enabled_p@>
          <td></td>
</if>
          <td colspan=4 align=right> 
            <table border=0 cellspacing=1 cellpadding=0>
              <tr> 
                <td>#intranet-timesheet2-invoices.VAT#</td>
                <td><input type=text name=vat value='@default_vat@' size=4> % &nbsp;</td>
              </tr>
            </table>
          </td>
        </tr>

<if @tax_enabled_p@>

        <tr> 
          <td></td>
<if @material_enabled_p@>
          <td></td>
</if>
<if @project_type_enabled_p@>
          <td></td>
</if>
          <td colspan=4 align=right> 
            <table border=0 cellspacing=1 cellpadding=0>
              <tr> 
                <td>#intranet-timesheet2-invoices.TAX#</td>
                <td><input type=text name=tax value='@default_tax@' size=4> % &nbsp;</td>
              </tr>
            </table>
          </td>
        </tr>
</if>
<else>
              <input type=hidden name=tax value='@default_tax@'>
</else>

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

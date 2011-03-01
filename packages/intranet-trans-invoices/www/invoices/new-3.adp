<!-- packages/intranet-trans-invoices/www/invoices/new-2.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">finance</property>


<%= [im_costs_navbar "none" "/intranet/invoicing/index" "" "" [list]] %>

<form action=new-4 method=POST>
<%= [export_form_vars customer_id provider_id invoice_id cost_status_id return_url] %>

<%
set include_task_html ""
foreach task_id $in_clause_list {
    append include_task_html "<input type=hidden name=include_task value=$task_id>\n"
}
%>
@include_task_html;noquote@


  <table cellpadding=0 cellspacing=0 bordercolor=#6699CC border=0 width=100%>
    <tr valign=top> 
      <td>

        <table border=0 cellPadding=0 cellspacing=2>

        <tr><td align=middle class=rowtitle colspan=2><%= [_ intranet-trans-invoices.Invoice_Data] %></td></tr>
        <tr>
          <td  class=rowodd><%= [_ intranet-trans-invoices.Invoice_nr] %>:</td>
          <td  class=rowodd> 
            <input type=text name=invoice_nr size=15 value='@invoice_nr@'>
          </td>
        </tr>
        <tr> 
          <td  class=roweven><%= [_ intranet-trans-invoices.Invoice_date] %>:</td>
          <td  class=roweven> 
            <input type=text name=invoice_date size=15 value='@invoice_date@'>
          </td>
        </tr>
        <tr>
          <td  class=roweven>@cost_center_label@</td>
          <td  class=roweven>
          @cost_center_select;noquote@
          </td>
        </tr>

<if @cost_type_id@ eq @cost_type_invoice_id@>
        <tr> 
          <td class=roweven><%= [_ intranet-trans-invoices.Payment_terms] %></td>
          <td class=roweven> 
            <input type=text name=payment_days size=5 value='@default_payment_days@'>
            days date of invoice</td>
        </tr>
        <tr> 
          <td class=rowodd><%= [_ intranet-trans-invoices.Payment_Method] %></td>
          <td class=rowodd><%= [im_invoice_payment_method_select payment_method_id $default_payment_method_id] %></td>
        </tr>
</if>


        <tr> 
          <td class=roweven><%= [_ intranet-trans-invoices.Invoice_template] %>:</td>
          <td class=roweven><%= [im_cost_template_select template_id $default_invoice_template_id] %></td>
        </tr>
        <tr> 
          <td class=rowodd><%= [_ intranet-trans-invoices.Type] %></td>
          <td class=rowodd>@type_name@<input type=hidden name=cost_type_id value=@target_cost_type_id@></td>
        </tr>



        </table>

      </td>
      <td></td>
      <td align=right>
        <table border=0 cellspacing=2 cellpadding=0 >

        <tr><td align=center valign=top class=rowtitle colspan=2><%= [_ intranet-trans-invoices.Recipient] %></td></tr>
        <tr> 
          <td  class=rowodd><%= [_ intranet-trans-invoices.Company_name] %></td>
          <td  class=rowodd>
            <A href=/intranet/companies/view?company_id=@company_id@>@company_name@</A>
          </td>
        </tr>
        <tr> 
          <td  class=roweven><%= [_ intranet-trans-invoices.VAT] %></td>
          <td  class=roweven>@vat_number@</td>
        </tr>
        <tr> 
          <td  class=rowodd><%= [lang::message::lookup "" intranet-invoices.Invoice_Address "Address"] %></td>
          <td  class=rowodd><%= [im_company_office_select invoice_office_id $invoice_office_id $company_id] %></td>
        </tr>
        <tr> 
          <td  class=rowodd><%= [_ intranet-core.Contact] %></td>
          <td  class=rowodd>
	    <%= [im_company_contact_select company_contact_id $company_contact_id $company_id] %>
          </td>
        </tr>


        </table>
    </tr>
  </table>

  <!-- the list of tasks (invoicable items) -->
  <table cellpadding=2 cellspacing=2 border=0 width='100%'>

@table_header_html;noquote@
<!--
	<tr> 
	  <td class=rowtitle><%= [_ intranet-trans-invoices.Task_Name] %></td>
	  <td class=rowtitle><%= [_ intranet-trans-invoices.Units] %></td>
	  <td class=rowtitle><%= [_ intranet-trans-invoices.Billable_Units] %></td>
	  <td class=rowtitle><%= [_ intranet-trans-invoices.Target] %></td>
	  <td class=rowtitle><%= [_ intranet-trans-invoices.UoM] %> <%= [im_gif help "Unit of Measure"] %></td>
	  <td class=rowtitle><%= [_ intranet-trans-invoices.Type] %></td>
	  <td class=rowtitle><%= [_ intranet-trans-invoices.Status] %></td>
	</tr>-->
	@task_table_rows;noquote@
  </table>

  <!-- the list of task sums, distinguised by type and UOM -->
  <table width=100%>
    <tr>
      <td align=right><table border=0 cellspacing=2 cellpadding=1>

       <tr align=center> 
          <td class=rowtitle><%= [_ intranet-trans-invoices.Order] %></td>
          <td class=rowtitle><%= [_ intranet-trans-invoices.Description] %></td>
          <td class=rowtitle><%= [_ intranet-trans-invoices.Units] %></td>
          <td class=rowtitle><%= [_ intranet-trans-invoices.UOM] %></td>
          <td class=rowtitle><%= [_ intranet-trans-invoices.Rate] %></td>
        </tr>

 <!--@task_sum_header_html;noquote@-->


        @task_sum_html;noquote@


	<!-- Grand Total -->
        <tr>
          <td> 
          </td>
          <td colspan=4 align=right> 
            <table border=0 cellspacing=1 cellpadding=0>
              <tr> 
                <td><%= [_ intranet-trans-invoices.VAT] %></td>
                <td><input type=text name=vat value='@default_vat;noquote@' size=4> % &nbsp;</td>
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
                <td><%= [_ intranet-trans-invoices.TAX] %></td>
                <td><input type=text name=tax value='@default_tax;noquote@' size=4> % &nbsp;</td>
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

<table>
        <tr><td align=middle class=rowtitle colspan=@price_colspan@><%= [_ intranet-trans-invoices.Reference_Prices] %></td></tr>
        <tr>
          <td class=rowtitle><%= [lang::message::lookup "" intranet-trans-invoices.Score "Score"] %></td>
          <td class=rowtitle><%= [_ intranet-trans-invoices.Company] %></td>
          <td class=rowtitle><%= [_ intranet-trans-invoices.UoM] %></td>
          <td class=rowtitle><%= [_ intranet-trans-invoices.Task_Type] %></td>
          <td class=rowtitle><%= [_ intranet-trans-invoices.Target] %></td>
          <td class=rowtitle><%= [_ intranet-trans-invoices.Source] %></td>
          <td class=rowtitle><%= [_ intranet-trans-invoices.Subject_Area] %></td>
	  @file_type_html;noquote@
<!--          <td class=rowtitle><%= [_ intranet-trans-invoices.Valid_From] %></td>	-->
<!--          <td class=rowtitle><%= [_ intranet-trans-invoices.Valid_Through] %></td>	-->
          <td class=rowtitle><%= [_ intranet-core.Note] %></td>
          <td class=rowtitle><%= [_ intranet-trans-invoices.Price] %></td>
          <td class=rowtitle><%= [lang::message::lookup "" intranet-trans-invoices.Min_Price "Min Price"] %></td>
        </tr>



  @reference_price_html;noquote@
</table>



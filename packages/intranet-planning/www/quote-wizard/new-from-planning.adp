<master>
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>
<property name="sub_navbar">@sub_navbar_html;noquote@</property>

<form action=/intranet-invoices/new-2 method=POST>
<% set invoice_id $new_invoice_id %>
<%= [export_form_vars invoice_id project_id select_project return_url reference_document_id] %>

<table border=0 width="100%">
<tr><td>

  <table cellpadding=0 cellspacing=0 bordercolor=#6699CC border=0>
    <tr valign=top> 
      <td>

        <table border=0 cellPadding=0 cellspacing=2 width="100%">


	        <tr><td align=middle class=rowtitle colspan=2>@target_cost_type@ Data</td></tr>
	        <tr>
	          <td  class=rowodd>@target_cost_type@ nr.:</td>
	          <td  class=rowodd> 
	            <input type=text name=invoice_nr size=15 value='@invoice_nr@'>
	          </td>
	        </tr>

                <tr>
                  <td  class=roweven>@cost_center_label@</td>
                  <td  class=roweven>
                  @cost_center_select;noquote@
                  </td>
                </tr>

	        <tr> 
	          <td  class=roweven>@target_cost_type@ date:</td>
	          <td  class=roweven> 
	            <input type=text name=invoice_date size=15 value='@effective_date@'>
	          </td>
	        </tr>
	        <tr> 
	          <td class=roweven>Payment terms</td>
	          <td class=roweven> 
	            <input type=text name=payment_days size=5 value='@payment_days@'>
	            days</td>
	        </tr>
	        <tr> 
	          <td class=roweven> @target_cost_type@ template:</td>
	          <td class=roweven>@template_select;noquote@</td>
	        </tr>
	        <tr> 
	          <td class=rowodd>@target_cost_type@ status</td>
	          <td class=rowodd>@status_select;noquote@</td>
	        </tr>
	        <tr> 
	          <td class=roweven>@target_cost_type@ type</td>
	          <td class=roweven>@type_select;noquote@</td>
	        </tr>

        </table>

      </td>
      <td></td>
      <td align=right>
        <table border=0 cellspacing=2 cellpadding=0 width="100%">

		<tr>
		  <td align=center valign=top class=rowtitle colspan=2>@company_type@</td>
		</tr>
		<tr>
		  <td class=roweven>@company_type@:</td>
		  <td class=roweven>@company_select;noquote@</td>
		</tr>
		<input type=hidden name=provider_id value=@provider_id@>

                <tr>
                  <td class=rowodd>@invoice_address_label@</td>
                  <td class=rowodd>@invoice_address_select;noquote@</td>
                </tr>

                <tr>
                  <td class=rowodd>#intranet-core.Contact#</td>
                  <td class=rowodd>@contact_select;noquote@</td>
                </tr>

                <tr>
                  <td class=roweven>#intranet-invoices.Note#</td>
                  <td class=roweven>
                    <textarea name=note rows=6 cols=40 wrap="<%=[im_html_textarea_wrap]%>">@cost_note@</textarea>
                  </td>
                </tr>

        </table>
    </tr>
  </table>

</td></tr>
<tr><td>

  <table width="100%">
    <tr>
      <td align=right>
 	<table border=0 cellspacing=2 cellpadding=1 width="100%">

	<!-- the list of task sums, distinguised by type and UOM -->
        <tr align=center> 
          <td class=rowtitle>#intranet-invoices.Line#</td>
          <td class=rowtitle>#intranet-invoices.Description#</td>

<if @material_enabled_p@>
          <td class=rowtitle>#intranet-invoices.Material#</td>
</if>
<if @project_type_enabled_p@>
          <td class=rowtitle>#intranet-invoices.Type#</td>
</if>
          <td class=rowtitle>#intranet-invoices.Units#</td>
          <td class=rowtitle>#intranet-invoices.UOM#</td>
          <td class=rowtitle>#intranet-invoices.Rate#</td>
        </tr>
	@task_sum_html;noquote@
        <tr> 
          <td>&nbsp; </td>
          <td colspan=6 align=right> 
              <input type=submit name=submit value='@button_text@'>
              <input type=hidden name=tax value='@tax@'>
   	      <input type=hidden name=vat value='@vat@'>
          </td>
        </tr>

        </table>
      </td>
    </tr>
  </table>


</td></tr>
</table>

</form>

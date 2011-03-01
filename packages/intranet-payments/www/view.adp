<master src="master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">finance</property>

<%= [im_costs_navbar "none" "/intranet-costs/index" "" "" [list] "payments_list"] %>

<form action=new method=POST>
<%= [export_form_vars payment_id cost_id return_url] %>

<table border=0>
	  <tr> 
	    <td colspan=2 class=rowtitle>#intranet-payments.Payment_Details#</td>
	  </tr>
	  <tr> 
	    <td>#intranet-payments.Cost_Nr#</td>
	    <td>
	      <A href=/intranet-cost/costs/new?form_mode=display&cost_id=@cost_id@>@cost_name@</A>
	    </td>
	  </tr>
	  <tr> 
	    <td>#intranet-payments.Client#</td>
	    <td>
	      <A href=/intranet/companies/view?company_id=@company_id@>
		@company_name@
	    </A>
	    </td>
	  </tr>
	  <tr> 
	    <td>#intranet-payments.Provider#</td>
	    <td>
	      <A href=/intranet/companies/view?company_id=@provider_id@>
		@provider_name@
	    </A>
	    </td>
	  </tr>
	  <tr> 
	    <td>#intranet-payments.Amount#</td>
	    <td>@amount@ @currency@</td>
	  </tr>
	  <tr> 
	    <td>#intranet-payments.Received#</td>
	    <td>@received_date@</td>
	  </tr>
          <tr>
            <td>#intranet-payments.Payment_Type#</td>
            <td>@payment_type@</td>
          </tr>
          <tr>
            <td>#intranet-payments.Note#</td>
            <td>@note@</td>
          </tr>
	  <tr> 
	    <td valign=top> </td>
	    <td><input type=submit value=Edit name=submit></td>
	  </tr>
</table>
</form>


<master src="master">
<property name="title">@page_title@</property>

<%= [im_costs_navbar "none" "/intranet-costs/index" "" "" [list] "payments_list"] %>

<form action=new method=POST>
<%= [export_form_vars payment_id cost_id return_url] %>

<table border=0>
	  <tr> 
	    <td colspan=2 class=rowtitle><#Payment_Details Payment Details#></td>
	  </tr>
	  <tr> 
	    <td><#Cost_Nr Cost Nr#></td>
	    <td>
	      <A href=/intranet-costs/view?cost_id=@cost_id@>@cost_name@</A>
	    </td>
	  </tr>
	  <tr> 
	    <td><#Client Client#></td>
	    <td>
	      <A href=/intranet/companies/view?company_id=@company_id@>
		@company_name@
	    </A>
	    </td>
	  </tr>
	  <tr> 
	    <td><#Provider Provider#></td>
	    <td>
	      <A href=/intranet/companies/view?company_id=@provider_id@>
		@provider_name@
	    </A>
	    </td>
	  </tr>
	  <tr> 
	    <td><#Amount Amount#></td>
	    <td>@amount@ @currency@</td>
	  </tr>
	  <tr> 
	    <td><#Received Received#></td>
	    <td>@received_date@</td>
	  </tr>
          <tr>
            <td><#Payment_Type Payment Type#></td>
            <td>@payment_type@</td>
          </tr>
          <tr>
            <td><#Note Note#></td>
            <td>@note@</td>
          </tr>
	  <tr> 
	    <td valign=top> </td>
	    <td><input type=submit value=Edit name=submit></td>
	  </tr>
</table>
</form>


<master src="master">
<property name="title">@page_title@</property>

<%= [im_costs_navbar "none" "/intranet-costs/index" "" "" [list] "payments_list"] %>

<form action=new method=POST>
<%= [export_form_vars payment_id cost_id return_url] %>

<table border=0>
	  <tr> 
	    <td colspan=2 class=rowtitle>Payment Details</td>
	  </tr>
	  <tr> 
	    <td>Cost Nr</td>
	    <td>
	      <A href=/intranet-costs/view?cost_id=@cost_id@>@cost_name@</A>
	    </td>
	  </tr>
	  <tr> 
	    <td>Client</td>
	    <td>
	      <A href=/intranet/customers/view?customer_id=@customer_id@>
		@customer_name@
	    </A>
	    </td>
	  </tr>
	  <tr> 
	    <td>Provider</td>
	    <td>
	      <A href=/intranet/customers/view?customer_id=@provider_id@>
		@provider_name@
	    </A>
	    </td>
	  </tr>
	  <tr> 
	    <td>Amount</td>
	    <td>@amount@ @currency@</td>
	  </tr>
	  <tr> 
	    <td>Received</td>
	    <td>@received_date@</td>
	  </tr>
          <tr>
            <td>Payment Type</td>
            <td>@payment_type@</td>
          </tr>
          <tr>
            <td>Note</td>
            <td>@note@</td>
          </tr>
	  <tr> 
	    <td valign=top> </td>
	    <td><input type=submit value=Edit name=submit></td>
	  </tr>
</table>
</form>

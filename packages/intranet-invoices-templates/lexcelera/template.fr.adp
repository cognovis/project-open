<%
    set doc_title [db_string title "select im_category_from_id($cost_type_id)" -default "Unknown"]
    regsub -all " " $doc_title "_" doc_title_key
    set doc_title [lang::message::lookup $locale intranet-core.$doc_title_key $doc_title]
%>

<html>
<head>
    <title><%= $doc_title %></title>
    <!-- link rel='stylesheet' href='/intranet/style/invoice.css' type='text/css' -->
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
	
    <style type="text/css">
	body {
	    background-image:url("/llogo.jpg");
	    background-repeat:no-repeat;
	    background-attachment:fixed; padding:0px;
	}
	p { font-family: verdana, arial, helvetica, sans-serif; color:black }
	.mybody { margin-left:10px; margin-top:2px; margin-right:2px; margin-bottom:2px; }
	.roweven { font-family: verdana, arial, helvetica, sans-serif; font-size: 8pt; }
	.rowodd { font-family: verdana, arial, helvetica, sans-serif; font-size: 8pt; }
	.invoiceroweven { font-family: verdana, arial, helvetica, sans-serif; font-size: 8pt; }
	.invoicerowodd { font-family: verdana, arial, helvetica, sans-serif; font-size: 8pt; }
	.address { font-family: verdana, arial, helvetica, sans-serif; font-size: 8pt; }
	.rowtitle { font-family: verdana, arial, helvetica, sans-serif; font-size: 9pt; font-weight: bold; }
	.blueheader { font-family: verdana, arial, helvetica, sans-serif; color: "#0065A3"; font-size: 7pt; }
	.cominfo { font-family: verdana, arial, helvetica, sans-serif; color: "#606060"; font-size: 6pt; }
    </style>
</head>

<body text="#000000">
<div class="mybody">
<table width="95%" border="0" cellpadding="1" cellspacing="1">
  <tr>
    <td>&nbsp; </td>
      <td align="left" valign="bottom"> <p><img src="/logo2.gif">
          <br>
      </td>
 </tr>
</table>
<p>

</p>
<table width="95%" border="0" cellspacing="1" cellpadding="1">
  <tr>
    <td colspan=2>
    <p><b><h1><%= $doc_title %></h1><b></p>
     </td>
  </tr>
  <tr>
    <td colspan=2>
      <p><b> <%= [lang::message::lookup $locale intranet-core.Project] %> <%= [join $related_project_nrs ", "] %> <b></p>
    </td>
  </tr>
  <tr>
    <td>
      <table border="0" cellspacing="1" cellpadding="1">
        <tr class=rowtitle><td colspan="2" class=rowtitle></td></tr>
        <tr><td class="address"><%=$company_name %></td></tr>
	<tr><td class="address"><%=$office_name %></td></tr>
	<tr><td class="address"><%=$address_line1 %> <%=$address_line2 %></td></tr>
	<tr><td class="address"><%=$address_postal_code %> <%=$address_city %></td></tr>
	<tr><td class="address"><%=$country_name %></td></tr>
	</td></tr>
      </table>
    </td>
    <td>
        <table border="0" cellspacing="1" cellpadding="1">
          <tr><td colspan="2" class="rowtitle"></td></tr>
          <tr><td class="address"><%= $internal_name %></td></tr>
          <tr><td class="address"><%= $internal_address_line1 %> <%= $internal_address_line2 %></td></tr>
          <tr><td class="address"><%= $internal_postal_code %> <%= $internal_city %></td></tr>
          <tr><td class="address"><%= $internal_country_name %></td></tr>
          <tr><td class="address">
	    <%= [lang::message::lookup $locale intranet-invoices.VAT "VAT"] %>:
	    <%= $internal_vat_number %>
	  </td></tr>
        </table>
    </td>
  </tr>
  <tr>
    <td>
      <table border="0" cellspacing="1" cellpadding="1">
	<tr><td class="address"><%=$company_contact_name%></td><td class="address">&nbsp;</td></tr>
	<tr>
	  <td class="address"><%= [lang::message::lookup $locale intranet-core.Phone "Phone"] %>:&nbsp;</td>
	  <td class="address"><%= $contact_person_work_phone %></td>
	</tr>
	<tr>
	  <td class="address"><%= [lang::message::lookup $locale intranet-core.Fax "Fax"] %>:&nbsp;</td>
	  <td class="address"><%= $contact_person_work_fax %></td>
	</tr>
	<tr>
		  <td class="address"><%= [lang::message::lookup $locale intranet-core.Email "Email"] %>:&nbsp;</td>
		  <td class="address"><%= $contact_person_email %></td>
	</tr>
      </table>
    </td>
    <td align="left" valign="top">
      <table border="0" cellspacing="1" cellpadding="1">
	<tr>
	  <td colspan="2" class="rowtitle"></td>
	</tr>
        <tr>
	  <td class="address"><%= $internal_contact_name %></td>
	  <td class="address">&nbsp;</td>
	</tr>
        <tr>
	  <td class="address"><%= [lang::message::lookup $locale intranet-core.Phone "Phone"] %>:&nbsp;</td>
	  <td class="address"><%= $internal_phone %></td>
	</tr>
        <tr>
	  <td class="address"><%= [lang::message::lookup $locale intranet-core.Fax "Fax"] %>:&nbsp;</td>
	  <td class="address"><%= $internal_fax %></td>
	</tr>
        <tr>
	  <td class="address"><%= [lang::message::lookup $locale intranet-core.Email "Email"] %>:&nbsp;</td>
	  <td class="address"><%= $internal_contact_email %></td>
	</tr>
        </table>
    </td>
  </tr>
</table>
<br>
<br>
<br>

<table border="0" cellspacing="1" cellpadding="1">
<tr>
	<td class="rowtitle"><%= $doc_title %>:&nbsp;</td>
	<td class="address"><%=$invoice_nr %></td>
</tr>	
<tr>
	<td class="rowtitle">
	  <%= [lang::message::lookup $locale intranet-invoices.Date "Date"] %>:&nbsp;
	</td>
	<td class="address"><%=$invoice_date_pretty %></td>
</tr>
<tr>
	<td class="rowtitle">&nbsp;</td>
	<td class="address">&nbsp;</td>
</tr>
<tr> 	
	<td class="rowtitle"><%= [lang::message::lookup $locale intranet-core.Project_name "Project Name"] %>:&nbsp;</td>
	<td class="address"> <%= [join $related_project_names ", "] %></td>
</tr>
<tr>
	<td class="rowtitle"><%= [lang::message::lookup $locale intranet-invoices.Your_Reference "Your Reference"] %>:&nbsp;</td>
	<td class="address"><%= [join $related_customer_project_nrs ", "] %></td>
</tr>
</table>
<p>


<%
	set payment_method_string ""
	set payment_method_text ""
	set payment_cond_string ""
	set payment_cond_text ""

	if {$cost_type_id == [im_cost_type_invoice] || $cost_type_id == [im_cost_type_bill]} {
		set payment_cond_string "[lang::message::lookup $locale intranet-invoices.Payment_Terms "Payment Terms"] &nbsp;"
		set payment_cond_text [lang::message::lookup $locale intranet-invoices.lt_This_invoice_is_past_]

		set payment_method_string "[lang::message::lookup $locale intranet-invoices.Payment_Method "Payment Method"]:&nbsp;"
		set payment_method_text $invoice_payment_method_desc
	}

	set vat_incl "$invoice_item_html"
	set sub_total "
	    <tr>
		<td class=roweven colspan=4 align=right><B>[lang::message::lookup $locale intranet-invoices.Total "Total"]</B></td>
		<td class=roweven align=right><B><nobr>$subtotal_pretty $currency</nobr></B></td>
	    </tr>
	"
	if { $cost_type_id == [im_cost_type_invoice] || $cost_type_id == [im_cost_type_po] } { set vat_incl "$item_list_html" }
	if { $cost_type_id == [im_cost_type_invoice] || $cost_type_id == [im_cost_type_po] } { set sub_total "" }
%>

<table border="0" cellspacing="2" cellpadding="2">
	<%=$vat_incl %>
	<%=$sub_total%>
</table>
<p>


<table width="737" border="0" cellpadding="1" cellspacing="1">
<tr>
	<td class="rowtitle"><nobr><%= $payment_cond_string%></nobr></font></td>
	<td width="90%" class="address"><%= $payment_cond_text %></td>
</tr>
<tr valign=top>
	<td class="rowtitle"><nobr><%=$payment_method_string %></nobr></td>
	<td width="90%" class="address"><%=$payment_method_text%></td>
</tr>
<tr>

	<td class=address colspan=3><%= $vat_not_incl %></td>
</tr>
<tr>
	<td><br/></td>
	<td><br/></td>
</tr>
<tr valign=top>
	<td colspan="2"><pre><div class="address"><%=$cost_note %></div></pre></td>
	<td class="rowtitle"><!-- Note: --></td>
</tr>
</table>

<%
set deadline_text "undefined"
switch $num_related_projects {
    0 {
	# No project associated - don't write any text
	set deadline_text ""
    }
    1 {
	# Exactly one project associated - go for it.
	set deadline_days 2
	set deadline_days [db_string deadline_days "select project_turnaround_days from im_projects where project_id = $rel_project_id" -default ""]

	if {"" != $deadline_days} {
	    # Yes, we found a deadline. 
	    set deadline_text "Deadline: $deadline_days after you accepted the quote"
	} else {
	    # No, no deadline. Use the project_end_date for deadline
	    set deadline_date_pretty [db_string deadline_days "select to_char(end_date, 'YYYY-MM-DD HH24:mm') from im_projects where project_id = $rel_project_id" -default ""]
	    set deadline_text "Deadline: $deadline_date_pretty"
	}
    }
    default {
	# More then one project associated - write error
	set deadline_text "<font color=red>There is more then one project associated with this document</font>"
    }
}
%>

<%= $deadline_text %>

<div style="rowtitle"> 
Afin de lancer votre projet, merci de nous retourner le devis sign&eacute; par fax <b>(au +33 1 55 28 88 10)</b>, ou donner votre accord par email en mentionnant le numéro de devis. <br><br>	
N'hésitez pas &agrave; nous contacter pour toute compl&eacute;ment d'information.
</div>
<br>

</tr>
</table>

<%
    set signature_table ""
    if { $cost_type_id == [im_cost_type_delivery_note] } {
	set signature_table "
 	<tr valign=top>
 		<td class=rowtitle>[lang::message::lookup $locale intranet-invoices.Cordially_komma "Cordially,"]</td>
		<td colspan=2><span class=rowtitle>[lang::message::lookup $locale intranet-invoices.Confirmation_komma "Confirmation,"]</span></td>
	</tr>
	<tr valign=top>
		<td height=77 class=rowtitle>&nbsp;</td>
		<td colspan=2>&nbsp;</td>
	</tr>
	<tr valign=top>
		<td class=address width=70>
		  <div style='width: 300px;' class=address>$internal_contact_name</div>
		</td>
		<td colspan=2 width=70>
		  <div style='width: 300px;' class=address>$company_contact_name</div>
		</td>
	</tr>"

	set signature_table "
		<table width=737 border=0 cellspacing=2 cellpadding=2>
		$signature_table
		</table><br>
	"
    }
%>

<%= $signature_table %>


<table width="95%">
<tr valign="top">
<td class="cominfo">
	<%= $internal_name %><br>
	<%= $internal_address_line1 %> <%= $internal_address_line2 %><br>
	<%= $internal_postal_code %> <%= $internal_city %><br>
	<%= $internal_country_name %>
</td>
<td>
	<table cellspacing="1" cellpadding="0">
	<tr>
	  <td class="cominfo"><%= [lang::message::lookup $locale intranet-core.Phone "Phone"] %></td>
	  <td class="cominfo"><%= $internal_phone %></td>
	</tr>
	<tr>
	  <td class="cominfo"><%= [lang::message::lookup $locale intranet-core.Fax "Fax"] %></td>
	  <td class="cominfo"><%= $internal_fax %></td>
	</tr>
	<tr>
	  <td class="cominfo" colspan="2"><%= $internal_accounting_contact_email %> </td>
	</tr>
	<tr>
	  <td class="cominfo" colspan="2"><%= $internal_web_site %></td>
	</tr>
	</table>
</td>
<td class="cominfo">
	<%= $internal_payment_method_desc %><br>
</td>
</tr>
</table>


</div>
</body>
</html>


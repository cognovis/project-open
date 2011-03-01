<!-- -------------------------------------------------------------------------- -->
<!-- ]project-open[ Default Template for HTMLDOC				-->
<!-- 										-->
<!-- This template can be used to render all financial documents.		-->
<!-- Features: 									-->
<!-- 	- Designed for HTMLDOC: Doesn't use advanced HTML			-->
<!-- 	- Localized: Output strings in template.<lang>.adp language		-->
<!-- 	- No payment info for Quotes & POs					-->
<!-- 	- Shows the Project_NR as the main information, not FinDoc_NR		-->
<!-- 										-->
<!-- -------------------------------------------------------------------------- -->


<!-- -------------------------------------------------------------------------- -->
<!-- Head with some basic variable definitions					-->
<!-- -------------------------------------------------------------------------- -->

<%
	# Enable debugging? Valid values include "1" (debugging enabled) and "0" (debugging disabled)
	set debug 0

	# Calculate a suitable document title
	set doc_title [db_string title "select im_category_from_id($cost_type_id)" -default "Unknown"]
	regsub -all " " $doc_title "_" doc_title_key
	set doc_title [lang::message::lookup $locale intranet-core.$doc_title_key $doc_title]
%>

<html>
<head>
    <title><%= $doc_title %></title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body text="#000000">

<!-- -------------------------------------------------------------------------- -->
<!-- Logo at the top - Must bie an absolute file reference			-->
<!-- -------------------------------------------------------------------------- -->

<table width="100%" border="<%=$debug%>" cellspacing="0" cellpadding="0">

  <!-- Maring above the logo -->
  <tr height="0"><td>&nbsp;</td></td>

  <!-- The logo -->
  <tr><td align="right"><img src="/web/pcdemo/www/project_open.38.10frame.jpg"></td></tr>

  <!-- Maring below the logo -->
  <tr height="70"><td>&nbsp;</td></td>
</table>
<p>


<!-- -------------------------------------------------------------------------- -->
<!-- Small Blue Line above Address with Company Information			-->
<!-- -------------------------------------------------------------------------- -->

<font size="-2" face="helvetica" color="blue">
	<%= $internal_name %> |
	<%= $internal_address_line1 %> <%= $internal_address_line2 %> |
	<%= $internal_postal_code %> <%= $internal_city %> |
	<%= $internal_country_name %>
</font>
</p>


<!-- -------------------------------------------------------------------------- -->
<!-- Provider and Customer Address						-->
<!-- -------------------------------------------------------------------------- -->

<table width="100%" border="<%=$debug%>">
  <tr>
    <td colspan=2>
      <p><b><%= $doc_title %> <%= [join $related_project_nrs ", "] %> <b></p>
    </td>
  </tr>
  <tr>
    <td>
	<!-- -------------------------------------------------------------------------- -->
	<!-- Customer Address								-->
	<table border="<%=$debug%>">
          <tr><td colspan="2"></td></tr>
          <tr><td><%=$company_name %></td></tr>
	  <tr><td><%=$office_name %></td></tr>
	  <tr><td><%=$address_line1 %> <%=$address_line2 %></td></tr>
	  <tr><td><%=$address_postal_code %> <%=$address_city %></td></tr>
	  <tr><td><%=$country_name %></td></tr>
	  <tr><td><%= [lang::message::lookup $locale intranet-invoices.VAT "VAT"] %>: <%=$vat_number %></td></tr>
	</table>
    </td>
    <td>
	<!-- -------------------------------------------------------------------------- -->
	<!-- Provider Address								-->
        <table border="<%=$debug%>">
          <tr><td colspan="2"></td></tr>
          <tr><td><%= $internal_name %></td></tr>
          <tr><td><%= $internal_address_line1 %> <%= $internal_address_line2 %></td></tr>
          <tr><td><%= $internal_postal_code %> <%= $internal_city %></td></tr>
          <tr><td><%= $internal_country_name %></td></tr>
          <tr><td><%= [lang::message::lookup $locale intranet-invoices.VAT "VAT"]%>: <%= $internal_vat_number %></td></tr>
        </table>
    </td>
  </tr>
  <tr height="5"><td colspan=2></td></tr>
  <tr>
    <td>

	<!-- -------------------------------------------------------------------------- -->
	<!-- Customer Contact								-->
	<table border="<%=$debug%>">
	<tr><td colspan=2><%=$company_contact_name%> &nbsp;</td></tr>
	<tr>
	  <td width="50"><%= [lang::message::lookup $locale intranet-core.Phone "Phone"] %>:&nbsp;</td>
	  <td width="200"><%= $contact_person_work_phone %> &nbsp;</td>
	</tr>
	<tr>
	  <td><%= [lang::message::lookup $locale intranet-core.Fax "Fax"] %>:&nbsp;</td>
	  <td><%= $contact_person_work_fax %> &nbsp;</td>
	</tr>
        <tr>
	  <td><%= [lang::message::lookup $locale intranet-core.Email "Email"] %>:&nbsp;</td>
	  <td><%= $contact_person_email %> &nbsp;</td>
	</tr>
	</table>

    </td>
    <td>

	<!-- -------------------------------------------------------------------------- -->
	<!-- Provider Contact								-->
	<table border="<%=$debug%>">
        <tr><td colspan=2><%= $internal_contact_name %> &nbsp;</td></tr>
        <tr>
	  <td width="50"><%= [lang::message::lookup $locale intranet-core.Phone "Phone"] %>:&nbsp;</td>
	  <td width="200"><%= $internal_phone %></td>
	</tr>
        <tr>
	  <td><%= [lang::message::lookup $locale intranet-core.Fax "Fax"] %>:&nbsp;</td>
	  <td><%= $internal_fax %></td>
	</tr>
        <tr>
	  <td><%= [lang::message::lookup $locale intranet-core.Email "Email"] %>:&nbsp;</td>
	  <td><%= $internal_contact_email %></td>
	</tr>
        </table>

    </td>
  </tr>
</table>
<br>


<!-- -------------------------------------------------------------------------- -->
<!-- Document#, Project# and Date						-->
<!-- -------------------------------------------------------------------------- -->

<table border="<%=$debug%>">
    <tr>
	<td width="120"><b><%= [lang::message::lookup $locale intranet-invoices.Document_hash_simbol "Document Nr."] %></b>:&nbsp;</td>
	<td width="560"><%=$invoice_nr %></td>
    </tr>	
    <tr>
	<td><b><%= [lang::message::lookup $locale intranet-invoices.Date "Date"] %></b>:&nbsp;</td>
	<td><%=$invoice_date_pretty %></td>
    </tr>
    <tr>
	<td>&nbsp;</td>
	<td>&nbsp;</td>
    </tr>
    <tr>
	<td><b><%= [lang::message::lookup $locale intranet-core.Project_Name "Project Name"] %></b>:&nbsp;</td>
	<td> <%= [join $related_project_names ", "] %> &nbsp;</td>
    </tr>
    <tr>
	<td><b><%= [lang::message::lookup $locale intranet-invoices.Your_Reference "Your Reference"] %></b>:&nbsp;</td>
	<td><%= [join $related_customer_project_nrs ", "] %> &nbsp;</td>
    </tr>
</table>
<p>

<!-- -------------------------------------------------------------------------- -->
<!-- Payment Method & Condition							-->
<!-- -------------------------------------------------------------------------- -->

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

	set items $invoice_item_html

	regsub -all {<td class=rowtitle(.*?)>(.*?)</td>} $items "<td align=right bgcolor='FFFFFF'><b>\\2</b></td>" items
	regsub -all {<td class=invoiceroweven(.*?)>(.*?)</td>} $items "<td align=right bgcolor='FFFFFF'>\\2</td>" items
	regsub -all {<td class=invoicerowodd(.*?)>(.*?)</td>} $items "<td align=right bgcolor='FFFFFF'>\\2</td>" items
	regsub -all {<td class=roweven(.*?)>(.*?)</td>} $items "<td align=right bgcolor='FFFFFF'>\\2</td>" items
	regsub -all {<td class=rowodd(.*?)>(.*?)</td>} $items "<td align=right bgcolor='FFFFFF'>\\2</td>" items

	set total_colspan [expr 1 + $show_qty_rate_p*3 + $show_company_project_nr + $show_our_project_nr]

	set sub_total "
	    <tr>
		<td align=right colspan=$total_colspan><B>[lang::message::lookup $locale intranet-invoices.Total "Total"]</B></td>
		<td align=right bgcolor='FFFFFF'><B><nobr>$subtotal_pretty $currency</nobr></B></td>
	    </tr>
	"
	if { $cost_type_id == [im_cost_type_invoice] || $cost_type_id == [im_cost_type_po] } { set items "$item_list_html" }
	if { $cost_type_id == [im_cost_type_invoice] || $cost_type_id == [im_cost_type_po] } { set sub_total "" }

	set vat_not_incl [lang::message::lookup $locale intranet-invoices.The_indicated_prices_dont_include_VAT "The indicated prices don't include VAT."]

	if { $cost_type_id == [im_cost_type_invoice] | $cost_type_id == [im_cost_type_bill] | $cost_type_id == [im_cost_type_po]} { 
	    set vat_not_incl "" 
	}

	set canned_notes_sql "
		select	c.category as canned_note,
			c.aux_string1 as canned_note_text
		from	acs_attributes a,
			im_dynfield_attributes d,
			im_dynfield_attr_multi_value v,
			im_categories c
		where	a.attribute_name = 'canned_note_id'
			and a.attribute_id = d.acs_attribute_id
			and d.attribute_id = v.attribute_id
			and v.object_id = :invoice_id
			and v.value::integer = c.category_id
	"
	set canned_notes ""
	db_foreach canned_notes $canned_notes_sql {
		append canned_notes "<tr><td colspan=2>$canned_note_text</td></tr>\n"
	}

%>



<!-- -------------------------------------------------------------------------- -->
<!-- Outer table to keep the footer at the bottom				-->

<table width="100%" height="400" border="<%=$debug%>">
<tr valign=top>
<td>

	
	<!-- -------------------------------------------------------------------------- -->
	<!-- Show the main invoice elements						-->

	<table border="<%=$debug%>" width="100%">
		<tr><td colspan=<%=[expr 1+$total_colspan]%>><hr size="0.5"></td></tr>
		<%=$items %>
		<tr><td colspan=<%=[expr 1+$total_colspan]%>><hr size="0.5"></td></tr>
		<%=$sub_total %>
	</table>
	<p>


	<!-- -------------------------------------------------------------------------- -->
	<!-- Show some messages								-->

	<table width="100%" border="<%=$debug%>">
	    <tr>
		<td width="100"><%= $payment_cond_string%></td>
		<td width="560"><%= $payment_cond_text %></td>
	    </tr>
	    <tr valign=top>
		<td><%=$payment_method_string %></td>
		<td><%=$payment_method_text %></td>
	    </tr>
	    <tr>
		<td class=address colspan=2><%= $vat_not_incl %></td>
	    </tr>

	    <%= $canned_notes %>

	    <tr valign=top>
		<td colspan="2"><pre><font size="+0"><%=$cost_note %></font></pre></td>
	    </tr>
	</table>
</td>
</tr>
</table>


<!-- -------------------------------------------------------------------------- -->
<!-- Signature									-->
<!-- -------------------------------------------------------------------------- -->

<%
    set signature_table ""
    if { $cost_type_id == [im_cost_type_delivery_note] } {
	set signature_table "
 	<tr valign=top>
 		<td>Con cordiales saludos,</td>
		<td colspan=2><span >Conforme,</span></td>
	</tr>
	<tr valign=top>
		<td height=77>&nbsp;</td>
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


<!-- -------------------------------------------------------------------------- -->
<!-- Footer									-->
<!-- -------------------------------------------------------------------------- -->

<font color="#606060" size="-1">
<table width="100%">
<tr valign="top">

	<!-- -------------------------------------------------------------------------- -->
	<!-- 1/4 Col: Company Name & City						-->
	<td class="cominfo">
	    <%= $internal_name %><br>
	    <%= $internal_address_line1 %> <%= $internal_address_line2 %><br>
	    <%= $internal_postal_code %> <%= $internal_city %><br>
	    <%= $internal_country_name %>
	</td>

	<!-- -------------------------------------------------------------------------- -->
	<!-- 2/4 Col: Company Phone & Fax						-->
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

	<!-- -------------------------------------------------------------------------- -->
	<!-- 3/4 Col: Payment Method							-->
	<td class="cominfo">
	    <%= $invoice_payment_method_desc %><br>
	</td>

	<!-- -------------------------------------------------------------------------- -->
	<!-- 4/4 Col: General Manager (Primary Contact) Contact & Email			-->

	<td class="cominfo">
	    <%= [lang::message::lookup $locale intranet-invoices.General_Manager "General Manager"] %>:<br>
	    <%= $internal_primary_contact_name %>,<br>
	    <%= $internal_primary_contact_email %>
	</td>
</tr>
</table>
</font>



</body>
</html>


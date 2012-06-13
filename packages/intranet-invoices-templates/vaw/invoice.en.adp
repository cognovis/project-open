<html>
<head>
<title><%= $cost_type_l10n %></title>
<!-- link rel='stylesheet' href='/intranet/style/invoice.css' type='text/css' -->
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">

<style type="text/css">
body {
    background-image:url(/arc.1200.gif); 
    background-repeat:no-repeat;
    background-attachment:fixed; padding:0px; 
}
div.mybody {
 margin-left:10px; margin-top:2px; margin-right:2px; margin-bottom:2px; 
}

p { 
	font-family: verdana, arial, helvetica, sans-serif; 
	color:black 
}
.roweven { 
	font-family: verdana, arial, helvetica, sans-serif; 
	font-size: 8pt;
}
.rowodd { 
	font-family: verdana, arial, helvetica, sans-serif; 
	font-size: 8pt;
}

.invoiceroweven { 
	font-family: verdana, arial, helvetica, sans-serif; 
	font-size: 8pt;
}
.invoicerowodd { 
	font-family: verdana, arial, helvetica, sans-serif; 
	font-size: 8pt;
}

.address {
	font-family: verdana, arial, helvetica, sans-serif; 
	font-size: 8pt;
}

.rowtitle {
	font-family: verdana, arial, helvetica, sans-serif; 
	font-size: 9pt;
	font-weight: bold;
}

.blueheader {
	font-family: verdana, arial, helvetica, sans-serif; 
	color: "#0065A3";
	font-size: 7pt;
}

.cominfo {
	font-family: verdana, arial, helvetica, sans-serif; 
	color: "#606060";
	font-size: 6pt;
}


</style>


</head>

<body text="#000000">
<div class=mybody>

<table width="95%" height="158" border="0" cellpadding="1" cellspacing="1">
  <tr> 
    <td>&nbsp; </td>
      <td align="right" valign="bottom"> <p><img src="/vaw-doclogo.gif" width="125" height="90"> 
          <br>
      </td>
  </tr>
</table>
<p>
<div class=blueheader>
Verlag Automobil Wirtschaft S.L. | Alcalde Ferrer i Mon&eacute;s, 23 | 08820 Barcelona | Spain
</div>
</p>
<table width="100%" border="0" cellspacing="1" cellpadding="1">
  <tr> 
    <td valign="top"> 

      <table border="0" cellspacing="1" cellpadding="1">
          <tr class=rowtitle> 
            <td colspan="2" class=rowtitle></td>
          </tr>
          <tr> 
            <td class="address"><%=$company_name %></td>
          </tr>
          <tr> 
            <td class="address"><%=$office_name %></td>
          </tr>
          <tr> 
            <td class=address><%=$address_line1 %></td>
          </tr>
          <tr> 
            <td class="address"><%=$address_postal_code %> <%=$address_city %> 
            </td>
          </tr>
          <tr> 
            <td class="address"><%=$country_name %></td>
          </tr>
<%
    set address1 ""
    if {![string equal "" $address_line1]} {
	set address1 "
        <tr> 
          <td class=address>Direcci&oacute;n</td>
          <td class=address>$address_line1</td>
        </tr>"
    }
%>
	
<!--
<%
    set address2 ""
    if {![string equal "" $address_line2]} {
	set address2 "
        <tr> 
          <td class=address>&nbsp;</td>
          <td class=address>$address_line2</td>
        </tr>"
    }
%>

	<%=$address2 %>
-->
        </table>
        <br>
       
        <table border="0" cellspacing="1" cellpadding="1">
          <tr class=address> 
            <td colspan="2" class=address></td>
          </tr>

<!--
<%
    set address1 ""
    if {![string equal "" $address_line1]} {
	set address1 "
        <tr> 
          <td class=address>Direcci&oacute;n</td>
          <td class=address>$address_line1</td>
        </tr>"
    }
%>
	
<%
    set address2 ""
    if {![string equal "" $address_line2]} {
	set address2 "
        <tr> 
          <td class=address>&nbsp;</td>
          <td class=address>$address_line2</td>
        </tr>"
    }
%>

	<%=$address2 %>
-->
          <tr> 
            <td class="address">Phone&nbsp;</td>
            <td class="address"><%=$phone %></td>
          </tr>
          <tr> 
            <td class="address">Fax</td>
            <td class="address"><%=$fax %></td>
          </tr>
<!--
          <tr> 
            <td class=address>NIF</td>
            <td class=address><%=$vat_number %></td>
          </tr>
-->
          <tr> 
            <td class="address">&nbsp;</td>
            <td class="address">&nbsp;</td>
          </tr>
        </table>
        <p>&nbsp; </p></td>
    <td align="left" valign="top"> 
	

<%
    set doc_title "Unknown"
    if {$cost_type_id == [im_cost_type_invoice]} { set doc_title "Invoice" }
    if {$cost_type_id == [im_cost_type_quote]} { set doc_title "Presupuesto" }
    if {$cost_type_id == [im_cost_type_bill]} { set doc_title "Factura" }
%>

      <p><b><%= $doc_title %><b></p>

        <table border="0" cellspacing="1" cellpadding="1">
          <tr> 
            <td colspan="2" class="rowtitle"></td>
          </tr>
          <tr> 

            <td class=address>Verlag Automobil Wirtschaft S.L.</td>
          </tr>
          <tr> 

            <td class=address>Alcalde Ferrer i Mon&eacute;s, 23</td>
          </tr>
          <tr> 

            <td class=address>08820 Barcelona</td>
          </tr>
          <tr> 

            <td class=address>Spain</td>
          </tr>
        </table>
        <br>
		<table border="0" cellspacing="1" cellpadding="1">
          <tr> 
            <td colspan="2" class="rowtitle"></td>
          </tr>
          <tr> 
            <td class=address>Phone&nbsp;</td>
            <td class=address>+34 934 787 971</td>
          </tr>
          <tr> 
            <td class=address>Fax</td>
            <td class=address>+34 934 788 255</td>
          </tr>
<!--      <tr> 
            <td class=address>NIF</td>
            <td class=address>B62753207</td>
          </tr>
-->
          <tr> 
            <td class=address>E-Mail</td>
            <td class=address>info@vaw-online.com</td>
          </tr>
        </table>
    </td>
  </tr>
</table>
<br>

  <table border="0" cellspacing="1" cellpadding="1">
    <tr> 
      <td class=rowtitle>Date:&nbsp;</td>
      <td class=address><%=$invoice_date_pretty %></td>
    </tr>
    <tr> 
      <td class=rowtitle>Document no:&nbsp;</td>
      <td class=address><%=$invoice_nr %></td>
    </tr>

    <tr> 
      <td class=rowtitle>Your purchase order no:&nbsp;</td>
      <td class=address></td>
    </tr>

  </table>
<br>

<%
    set nota_string "Nota:"
    if {"" == [string trim $cost_note]} { 
	set cost_note "-"
    }

#  ad_return_complaint 1 $invoice_payment_method

    set forma_pago_string ""
    set cond_pago_string ""
    set cond_pago_text ""
    if {$cost_type_id == [im_cost_type_invoice] || $cost_type_id == [im_cost_type_bill]} {

	set cond_pago_string "Payment Terms:&nbsp;"
	set cond_pago_text [lang::message::lookup $locale intranet-invoices.lt_This_invoice_is_past_]
	if {"" != [string trim $invoice_payment_method_desc]} { 
	    set forma_pago_string "Forma de pago:" 
        }
    }

%>


<table border="0" cellspacing="2" cellpadding="2">
<%=$item_list_html %>
</table>
  <table border="0" cellpadding="1" cellspacing="1">
<!--
    <tr> 
      <td class=rowtitle><nobr>Albaranes:&nbsp;</nobr></td>
      <td class=rowodd> nothing defined yet </td>
    </tr>
-->
    <tr> 
      <td class=rowtitle><nobr><%= [lang::message::lookup &locale intranet-invoices.Payment_Terms]  %></nobr></font></td>
      <td class=address> <%= [lang::message::lookup &locale  intranet-invoices.lt_This_invoice_is_past_]  %>  </td>
    </tr>
    <tr> 
      <td class=rowtitle>
	
<%= [lang::message::lookup &locale intranet-invoices.Payment_Method_1] %> </td>
      <td class=address>
<%= [lang::message::lookup $locale intranet-core.[lang::util::suggest_key $invoice_payment_method] $invoice_payment_method] %></td>

    </tr>
    <tr valign=top> 
      <td class=rowtitle> <%= [lang::message::lookup &locale intranet-invoices.Note] %>  </td>
      <td>
       <pre><div class=address><%=$cost_note %></div></pre>
       </td>
    </tr>
  </table>
<br>


<P>&nbsp;</P>
<table width="100%">
<tr valign=top>
<td class=cominfo>
	Verlag Automobil Wirtschaft S.L. <br>
	Alcalde Ferrer i Mon&eacute;s, 23<br>
	08820 El Prat del Llobregat<br>
	Barcelona<br>
	Spain
</td>
<td>
	<table cellspacing=1 cellpadding=0>
	<tr>
	  <td class=cominfo>Tel&eacute;fono&nbsp;</td>
	  <td class=cominfo>+34 934 787 971</td>
	</tr>
	<tr>
	  <td class=cominfo>Telefax</td>
	  <td class=cominfo>+34 934 788 255</td>
	</tr>
	<tr><td class=cominfo colspan=2>vaw@vaw.es</td></tr>
	<tr><td class=cominfo colspan=2>http://www.vaw.es/</td></tr>
	</table>
</td>
<td class=cominfo>
	Bank: BBVA, Banco Bilbao Vizcaya Argentaria<br>
	Of. Banca Corporativa, Av. Diagonal 662<br>
	08034 Barcelona<br>
	Bank Account: 0182-0999-89-0201512103<br>
</td>
<td class=cominfo>
	General Managers:<br>
	Wolfgang Rentmeister<br>
	David Garc&iacute;a Mart&iacute;nez<br>
</td>
</tr>
</table>


</div>
</body>
</html>

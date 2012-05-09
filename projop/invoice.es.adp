<html>
<head>
<title>Factura</title>
<link rel='stylesheet' href='http://www.project-open.com/css/invoice.css' type='text/css'>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>

<body text="#000000">
<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td align=left>
      <P><b><font size="5">FACTURA</font></b></P>
    </td>
    <td align="right"> 
      <img src="http://www.project-open.com/images/logos/project_open.38.10frame.gif"><br>
    </td>
  </tr>
</table>
<hr>

<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td valign="top"> 
      <br><br>
      <table border="0" cellspacing="1" cellpadding="1">
        <tr class=rowtitle> 
          <td colspan="2" class=rowtitle><!--Detalles de Cliente--></td>
        </tr>
        <tr> 
          <td class="roweven"><!--Empresa-->&nbsp;</td>
          <td class="roweven"><%=$company_name %></td>
        </tr>
        <tr>
          <td class=roweven><!--NIF-->&nbsp;</td>
          <td class=roweven>NIF: <%=$vat_number %></td>
        </tr>

<%
    set address1 ""
    if {![string equal "" $address_line1]} {
	set address1 "
        <tr> 
          <td class=roweven><!--Direcci&oacute;n-->&nbsp;</td>
          <td class=roweven>$address_line1</td>
        </tr>"
    }
%>
	<%=$address1 %>
<%
    set address2 ""
    if {![string equal "" $address_line2]} {
	set address2 "
        <tr> 
          <td class=roweven>&nbsp;</td>
          <td class=roweven>$address_line2</td>
        </tr>"
    }
%>
	<%=$address2 %>
        <tr> 
          <td class="roweven"><!--Ciudad-->&nbsp;</td>
          <td class="roweven"><%=$address_postal_code %> <%=$address_city %> </td>
        </tr>
        <tr> 
          <td class="rowodd"><!--Pa&iacute;s-->&nbsp;</td>
          <td class="rowodd"><%=$country_name %></td>
        </tr>
<!--
        <tr> 
          <td class="roweven">Tel</td>
          <td class="roweven"><%=$phone %></td>
        </tr>
        <tr> 
          <td class="rowodd">Fax</td>
          <td class="rowodd"><%=$fax %></td>
        </tr>
-->
        <tr> 
          <td class="rowodd">&nbsp;</td>
          <td class="rowodd">&nbsp;</td>
        </tr>
      </table>
    </td>
    <td align="left" valign="top"> 
      <table border="0" cellspacing="1" cellpadding="1">
        <tr> 
          <td colspan="2" class="rowtitle">Detalles del Proveedor</td>
        </tr>
        <tr> 
          <td class=roweven>Empresa</td>
          <td class=roweven>]project-open[</td>
        </tr>
        <tr> 
          <td class=roweven>NIF</td>
          <td class=roweven>X2461483-T</td>
        </tr>
        <tr> 
          <td class=roweven>Direcci&oacute;n</td>
          <td class=roweven>Ronda Sant Antoni 51, 1o 2a</td>
        </tr>
        <tr> 
          <td class=roweven>Ciudad</td>
          <td class=roweven>E-08011 Barcelona</td>
        </tr>
        <tr> 
          <td class=rowodd>Pa&iacute;s</td>
          <td class=rowodd>Espa&ntilde;a</td>
        </tr>
        <tr> 
          <td class=roweven>Tel</td>
          <td class=roweven>+34 609 953 751</td>
        </tr>
        <tr> 
          <td class=rowodd>Fax</td>
          <td class=rowodd>+34 93 289 07 29</td>
        </tr>
        <tr> 
          <td class=roweven>E-Mail</td>
          <td class=roweven>accounting@project-open.com</td>
        </tr>
      </table>
    </td>
  </tr>
</table>
<br>

<table border="0" cellspacing="1" cellpadding="1">
  <tr> 
    <td><b><font size=2>Fecha</font></b></td>
    <td><font size=2><%=$invoice_date_pretty %></font></td>
  </tr>
  <tr> 
    <td><b><font size=2>Factura Nr. </font></b></td>
    <td><font size=2><%=$invoice_nr %></font></td>
  </tr>
</table>
<br>

<table border="0" cellspacing="2" cellpadding="2">
<%=$item_html %>
</table>

</body>
</html>

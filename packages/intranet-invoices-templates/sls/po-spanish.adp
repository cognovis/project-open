<html>
<head>
<title>Untitled Document</title>
<link rel='stylesheet' href='/intranet/style/invoice.css' type='text/css'>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>

<!-- <body text="#000000" background="/intranet/images/sls10.gif"> -->
<body text="#000000">
<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td>
      <img src="/intranet/images/sls10.gif" width=206 height=111><br>
      <P><b><font size="5">PEDIDO</font></b></P>
    </td>
    <td align="right">      <p><font size="6"><b>SLS international</b></font><br>
        <font size="4"><b>Traducci&oacute;n y Localizaci&oacute;n</b></font></p>
      <b><font size="3">www.sls-international.com</font></b>
    </td>
  </tr>
</table>
<hr>
<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td width="40%" valign="top"> 

      <table border="0" cellspacing="1" cellpadding="1">
        <tr class=rowtitle> 
          <td colspan="2" class=rowtitle>Proveedor:</td>
        </tr>
        <tr> 
          <td width="82" class="roweven">Empresa</td>
          <td width="108" class="roweven"><%=$customer_name %></td>
        </tr>
        <tr>
          <td class="roweven">NIF</td>
          <td class="roweven"><%=$vat_number%></td>
        </tr>
<%
    set address1 ""
    if {![string equal "" $address_line1]} {
	set address1 "
        <tr> 
          <td class=roweven>Address</td>
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
          <td class="roweven">C.P/Ciudad</td>
          <td class="roweven"><%=$address_postal_code %> <%=$address_city %> </td>
        </tr>
        <tr> 
          <td class="rowodd">Pa&iacute;s</td>
          <td class="rowodd"><%=$country_name %></td>
        </tr>
        <tr> 
          <td class="roweven">Tel&eacute;fono</td>
          <td class="roweven"><%=$phone %></td>
        </tr>
        <tr> 
          <td class="rowodd">Fax</td>
          <td class="rowodd"><%=$fax %></td>
        </tr>
        <tr> 
          <td class="rowodd">E-Mail</td>
          <td class="rowodd"><%=$customer_contact_email %></td>
        </tr>
      </table>
    </td>
    <td width="60%" align="left" valign="top"> 
      <table border="0" cellspacing="1" cellpadding="1">
        <tr> 
          <td colspan="2" class="rowtitle">&nbsp;</td>
        </tr>
        <tr>
          <td class=roweven>Empresa</td>
          <td class=roweven>SLS international</td>
        </tr>
        <tr> 
          <td class=roweven>NIF</td>
          <td class=roweven>B-63.244.669</td>
        </tr>
        <tr> 
          <td class=roweven>Direcci&oacute;n</td>
          <td class=roweven>Thos i Codina 15</td>
        </tr>
        <tr> 
          <td class=roweven>C.P./Ciudad</td>
          <td class=roweven>08302 Matar&oacute;, Barcelona</td>
        </tr>
        <tr> 
          <td class=rowodd>Pa&iacute;s</td>
          <td class=rowodd>Espa&ntilde;a</td>
        </tr>
        <tr> 
          <td class=roweven>Tel&eacute;fono</td>
          <td class=roweven>+34 93 741 1234</td>
        </tr>
        <tr> 
          <td class=rowodd>Fax</td>
          <td class=rowodd>+34 93 741 1235</td>
        </tr>
        <tr> 
          <td class=roweven>E-Mail</td>
          <td class=roweven>accounting@sls-international.com</td>
        </tr>
      </table>
    </td>
  </tr>
</table>
<br>

<table border="0" cellspacing="1" cellpadding="1">
  <tr> 
    <td><b><font size=2>Fecha</font></b></td>
    <td><font size=2><%=$invoice_date %></font></td>
  </tr>
  <tr> 
    <td><b><font size=2>N&uacute;mero. </font></b></td>
    <td><font size=2><%=$invoice_nr %></font></td>
  </tr>
</table>
<br>

<table border="0" cellspacing="2" cellpadding="2">
<%=$item_html %>
</table>

<br>
<%=$note%>
<P>
<font size="-2">
SLS international se reserva el derecho de retener el pago si el trabajo realizado no satisface los criterios de calidad esperados. El precio de un trabajo queda reflejado en este pedido y no est&aacute; sujeto a ning&uacute;n otro tipo de c&aacute;lculo. Al aceptar este trabajo, el proveedor se compromete a que &eacute;l, sus empleados, agentes o personal subcontratado, o en nombre de o junto con una persona, empresa, asociaci&oacute;n o corporaci&oacute;n, no revelar&aacute;n en ning&uacute;n momento informaci&oacute;n propietaria y confidencial, como informaci&oacute;n sobre el proyecto, el cliente, la tecnolog&iacute;a utilizada, temas relativos a marketing o finanzas.
</font>
</P>

</body>
</html>

<html>
<head>
<title>Presupuesto</title>
<link rel='stylesheet' href='/intranet/style/invoice.css' type='text/css'>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>

<!-- <body text="#000000" background="/intranet/images/sls10.gif"> -->
<body text="#000000">
<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td>
<!--      <img src="/vaw-arvato.gif"><br> -->

    </td>
    <td align="right"> <p>
        <img src="/vaw-arvato.gif"><br>
     </td>
  </tr>
</table>

<p>
<font color="#0065A3" size="-2">
Verlag Automobil Wirtschaft S.L. | Alcalde Ferrer i Mon&eacute;s, 23 | 08820 Barcelona | Espa&ntilde;a
</font>
</p>
<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td valign="top"> 

      <table border="0" cellspacing="1" cellpadding="1">
        <tr class=rowtitle> 
          <td colspan="2" class=rowtitle></td>
        </tr>
        <tr> 
          <td class="roweven">Empresa</td>
          <td class="roweven"><%=$company_name %></td>
        </tr>
        <tr>
          <td class=roweven>NIF</td>
          <td class=roweven><%=$vat_number %></td>
        </tr>

<%
    set address1 ""
    if {![string equal "" $address_line1]} {
	set address1 "
        <tr> 
          <td class=roweven>Direcci&oacute;n</td>
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
          <td class="roweven">Ciudad</td>
          <td class="roweven"><%=$address_postal_code %> <%=$address_city %> </td>
        </tr>
        <tr> 
          <td class="rowodd">Pa&iacute;s</td>
          <td class="rowodd"><%=$country_name %></td>
        </tr>
        <tr> 
          <td class="roweven">Telefon</td>
          <td class="roweven"><%=$phone %></td>
        </tr>
        <tr> 
          <td class="rowodd">Fax</td>
          <td class="rowodd"><%=$fax %></td>
        </tr>
        <tr> 
          <td class="rowodd">&nbsp;</td>
          <td class="rowodd">&nbsp;</td>
        </tr>
      </table>
    </td>
    <td align="left" valign="top"> 
      <table border="0" cellspacing="1" cellpadding="1">
        <tr> 
          <td colspan="2" class="rowtitle"></td>
        </tr>
        <tr> 
          <td class=roweven>Empresa</td>
          <td class=roweven>Verlag Automobil Wirtschaft S.L.</td>
        </tr>
        <tr> 
          <td class=roweven>NIF</td>
          <td class=roweven>B62753207</td>
        </tr>
        <tr> 
          <td class=roweven>Address</td>
          <td class=roweven>Alcalde Ferrer i Mon&eacute;s, 23</td>
        </tr>
        <tr> 
          <td class=roweven>Ciudad</td>
          <td class=roweven>08820 Barcelona</td>
        </tr>
        <tr> 
          <td class=rowodd>Pa&iacute;s</td>
          <td class=rowodd>Espa&ntilde;a</td>
        </tr>
        <tr> 
          <td class=roweven>Telefon</td>
          <td class=roweven>+34 934 787 971</td>
        </tr>
        <tr> 
          <td class=rowodd>Fax</td>
          <td class=rowodd>+34 934 788 255</td>
        </tr>
        <tr> 
          <td class=roweven>Correo</td>
          <td class=roweven>xpastor@vaw-online.com</td>
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
    <td><b><font size=2>Presupuesto No.</font></b></td>
    <td><font size=2><%=$invoice_nr %></font></td>
  </tr>
</table>
<br>

<table border="0" cellspacing="2" cellpadding="2">
<%=$item_html %>
</table>



<P>&nbsp;</P>
<table width="100%">
<tr valign=top>
<td>
	<font color="#606060" size="-4">
	Verlag Automobil Wirtschaft S.L. <br>
	Alcalde Ferrer i Mon&eacute;s, 23<br>
	08820 Barcelona<br>
	Espa&ntilde;a<br>
	</font>
</td>
<td>
	<table>
	<tr>
	  <td><font color="#606060" size="-4">Tel</font></td>
	  <td><font color="#606060" size="-4"><nobr>+34 934 787 971</nobr></td>
	</tr>
	<tr>
	  <td><font color="#606060" size="-4">Fax</td>
	  <td><font color="#606060" size="-4">+34 934 788 255</font></td>
	</tr>
	<tr><td colspan=2><font color="#606060" size="-4">vaw@vaw.es</font></td></tr>
	<tr><td colspan=2><font color="#606060" size="-4">http://www.vaw.es/</font></td></tr>
	</table>
</td>
<td>
	<font color="#606060" size="-4">
	Bank: Caixa Sabadell, Ctra. de la Marina 13<br>
	08820 El Prat de Llobregat<br>
	Bank Account: 2059-0440-44-8000120552<br>
	IBAN: ES68 2059 0440 2480 0012 0552<br>
	Swift/BIC: CECAESMM059<br>
	NIF: B62753207<br>
	</font>
</td>
<td>
        <font color="#606060" size="-4">
	General Managers:<br>
	Walter Bruckmann<br>
	David Garc&iacute;a Mart&iacute;nez<br>
        </font>
</td>
</tr>
</table>



</body>
</html>

<html>
<head>
<title>Untitled Document</title>
<link rel='stylesheet' href='http://www.project-open.com/css/invoice.css' type='text/css'>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>

<!-- <body text="#000000" background="/images/sls10.gif"> -->
<body text="#000000">
<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td> <img src="http://www.project-open.com/images/logos/logo.project-open.horiz.tra.gif" width=230 height=52><br>
      <P><b><font size="5">Orden de Compra</font></b></P>
    </td>
    <td align="right"> <p><font size="6"><b>]project-open[</b></font><br>
        <font size="4"><b>Gestiona tus proyectos online-<br>
        cuando se, donde sea</b></font></p>
      <b><font size="3">www.project-open.com</font></b> </td>
  </tr>
</table>
<hr>
<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td valign="top"> 

      <table border="0" cellspacing="1" cellpadding="1">
        <tr class=rowtitle> 
          <td colspan="2" class=rowtitle>Cliente</td>
        </tr>
        <tr> 
          <td class="roweven">Empresa</td>
          <td class="roweven"><%=$customer_name %></td>
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
          <td class="roweven">Direcci&oacute;n</td>
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
          <td class="rowodd">&nbsp;</td>
          <td class="rowodd">&nbsp;</td>
        </tr>
      </table>
    </td>
    <td align="left" valign="top"> <table border="0" cellspacing="1" cellpadding="1">
        <tr> 
          <td colspan="2" class="rowtitle">Provider Details</td>
        </tr>
        <tr> 
          <td class=roweven>Company</td>
          <td class=roweven>]project-open[</td>
        </tr>
        <tr> 
          <td class=roweven>Address</td>
          <td class=roweven>Avda. Felix Milletc 45</td>
        </tr>
        <tr> 
          <td class=roweven>Zip/City</td>
          <td class=roweven>08338 Barcelona</td>
        </tr>
        <tr> 
          <td class=rowodd>Country</td>
          <td class=rowodd>Spain</td>
        </tr>
        <tr> 
          <td class=roweven>Phone</td>
          <td class=roweven>+34 609 953 751</td>
        </tr>
        <tr> 
          <td class=rowodd>Fax</td>
          <td class=rowodd>+34 93 741 1235</td>
        </tr>
        <tr> 
          <td class=roweven>E-Mail</td>
          <td class=roweven>accounting@project-open.com</td>
        </tr>
      </table></td>
  </tr>
</table>
<br>

<table border="0" cellspacing="1" cellpadding="1">
  <tr> 
    <td><b><font size=2>Fecha</font></b></td>
    <td><font size=2><%=$invoice_date %></font></td>
  </tr>
  <tr> 
    <td><b><font size=2>Factura No. </font></b></td>
    <td><font size=2><%=$invoice_nr %></font></td>
  </tr>
</table>
<br>

<table border="0" cellspacing="2" cellpadding="2">
<%=$item_html %>
</table>

<P>&nbsp;</P>
<P>
<font size="-2">
Disclaimer: 
All our work is executed with the utmost professional care. However, we
disclaim all liability for any legal implications resulting from the use of
it. Our maximum liability, whether by negligence, contract or
otherwise, will not exceed the return of the amount invoiced for the work in
dispute. Under no circunstances will we be liable for specific, individual
or consequential damages.
</font>
</P>

</body>
</html>

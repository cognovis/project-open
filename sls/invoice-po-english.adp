<html>
<head>
<title>Untitled Document</title>
<link rel='stylesheet' href='/style/sls-invoice.css' type='text/css'>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>

<body text="#000000">
<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td>
      <P><b><font size="5">INVOICE</font></b></P>
    </td>
    <td align="right"> 
      <p><font size="6"><b>Project-Open.com</b></font><br>
        <font size="4"><b>Project Resource Planning</b></font></p>
      <b><font size="3">www.project-open.com</font></b>
    </td>
  </tr>
</table>
<hr>
<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td valign="top"> 

      <table border="0" cellspacing="1" cellpadding="1">
        <tr class=rowtitle> 
          <td colspan="2" class=rowtitle>Client Details </td>
        </tr>
        <tr> 
          <td class="roweven">Company</td>
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
          <td class="roweven">Zip/City</td>
          <td class="roweven"><%=$address_postal_code %> <%=$address_city %> </td>
        </tr>
        <tr> 
          <td class="rowodd">Country</td>
          <td class="rowodd"><%=$country_name %></td>
        </tr>
        <tr> 
          <td class="roweven">Phone</td>
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
          <td colspan="2" class="rowtitle">Provider Details</td>
        </tr>
        <tr> 
          <td class=roweven>Company</td>
          <td class=roweven>Project-Open</td>
        </tr>
        <tr> 
          <td class=roweven>Address</td>
          <td class=roweven>Avda. Felix Millet, 45</td>
        </tr>
        <tr> 
          <td class=roweven>Zip/City</td>
          <td class=roweven>08338 Premia de Dalt, Barcelona</td>
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
      </table>
    </td>
  </tr>
</table>
<br>

<table border="0" cellspacing="1" cellpadding="1">
  <tr> 
    <td><b><font size=2>Date</font></b></td>
    <td><font size=2><%=$invoice_date %></font></td>
  </tr>
  <tr> 
    <td><b><font size=2>Invoice No. </font></b></td>
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

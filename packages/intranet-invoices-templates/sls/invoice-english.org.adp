<html>
<head>
<title>Untitled Document</title>
<link rel='stylesheet' href='/style/sls-invoice.css' type='text/css'>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>

<body bgcolor="#FFFFFF" text="#000000">
<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td valign="bottom"><b><font size="5">INVOICE</font></b></td>
    <td align="right"> 
      <p><font size="6"><b>SLS international</b></font><br>
        <font size="4"><b>Spanish Language Services</b></font></p>
      <b><font size="3">www.sls-international.com</font></b>
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
        <tr> 
          <td class="rowodd">Contact Person</td>
          <td class="rowodd"><%=$customer_contact%></td>
        </tr>
        <tr> 
          <td class="roweven">Address</td>
          <td class="roweven"><%=$address_line1%></td>
        </tr>
        <tr> 
          <td class="rowodd">&nbsp;</td>
          <td class="rowodd"><%=$address_line2 %></td>
        </tr>
        <tr> 
          <td class="roweven">City/State/Zip</td>
          <td class="roweven"><%=$address_city %><%=$address_postal_cod %></td>
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
          <td class="roweven">E-Mail</td>
          <td class="roweven"><%=$customer_contact_email %></td>
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
          <td class=roweven>&nbsp;</td>
          <td class=roweven>SLS International</td>
        </tr>
        <tr> 
          <td class=rowodd>&nbsp;</td>
          <td class=rowodd>&nbsp;</td>
        </tr>
        <tr> 
          <td class=roweven>&nbsp;</td>
          <td class=roweven>Thos i Codina 15</td>
        </tr>
        <tr> 
          <td class=rowodd>&nbsp;</td>
          <td class=rowodd>&nbsp;</td>
        </tr>
        <tr> 
          <td class=roweven>&nbsp;</td>
          <td class=roweven>08302 Matar&oacute;, Barcelona</td>
        </tr>
        <tr> 
          <td class=rowodd>&nbsp;</td>
          <td class=rowodd>Spain</td>
        </tr>
        <tr> 
          <td class=roweven>Phone</td>
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
        <tr> 
          <td class=rowodd>Web</td>
          <td class=rowodd>www.sls-international.com</td>
        </tr>
      </table>
    </td>
  </tr>
</table>
<br>

<table border="0" cellspacing="1" cellpadding="1">
  <tr> 
    <td><b><font size=3>Date</font></b></td>
    <td><font size=3><%=$invoice_date %></font></td>
  </tr>
  <tr> 
    <td><b><font size=3>Invoice No. </font></b></td>
    <td><font size=3><%=$invoice_nr %></font></td>
  </tr>
</table>
<br>

<table border="0" cellspacing="2" cellpadding="2">
<%=$item_html %>
</table>

<p><br>
  <font size="3">This invoice is past due if unpaid after <%=$payment_days %> days.</font></p>
<p>&nbsp;</p>
<p>Active Member of the American Translators Association (ATA) <br>
  Member of the Society for Technical Communication (STC) and the Institute of 
  Scientific &amp; Technical Communicators (ISTC)<br>
  Professional Member of the Localization Research Centre (LRC), Member of CBTIP, 
  ITI, IoL and TTIG</p>
<p>&nbsp;</p>
</body>
</html>

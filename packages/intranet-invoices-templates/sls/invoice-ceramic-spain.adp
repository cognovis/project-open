<html>
<%=[cl_tradesign_head_header]%>
<title>View Invoice</title>

<META LANGUAGE='es'>


<script language="JavaScript">
<!--
function MM_reloadPage(init) {  //reloads the window if Nav4 resized
  if (init==true) with (navigator) {if ((appName=="Netscape")&&(parseInt(appVersion)==4)) {
    document.MM_pgW=innerWidth; document.MM_pgH=innerHeight; onresize=MM_reloadPage; }}
  else if (innerWidth!=document.MM_pgW || innerHeight!=document.MM_pgH) location.reload();
}
MM_reloadPage(true);
// -->
</script>
<%=[cl_tradesign_head_footer]%>

<body bgcolor="FFFFFF" text="#000000">
<div id="Layer1" style="position:absolute; width:243px; height:55px; z-index:1; left: 50px; top:25px">
  <div id="Layer2" style="position:absolute; left:250px; z-index:2; width: 338px; height: 46px; top:0px">

<table width="417" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td valign=top rowspan=3>
      <table cellSpacing=0 cellPadding=0 width=132 border=0>
        <tr>
          <td><a href="index">
            <img alt=""
               src="/images/bn4.gif"
               border=0 name=top_logo width="340"></a></td>
         </tr>
       </table>
     </td>
  </tr>
</table>

</div>
  <div id="Layer3" style="position:absolute; left:375px; top:130px; width:320px; height:56px; z-index:3">
    <font size="2"><b><%=$view_company_name%></b><br>
    <%=$view_company_address%>
    <br><%=$view_company_zip%> <%=$view_company_province%></font><br>
    <br>
    <br>
    NIF cliente: <%=$view_company_vat_nr%></div>
    <div id="Layer9" style="position:absolute; left:100px; top:130px; width:380px; height:56px; z-index:3">
    <table>
      <tr>
        <td><i><font face="Arial, Helvetica, sans-serif" color="#009900"><b>FECHA FACTURA :</b></font></i></td>
        <td><b><%=$view_invoice_date%></b></td>
      </tr>
      <tr>
        <td><i><font face="Arial, Helvetica, sans-serif" color="#009900"><b>FACTURA Nº :</b></font></i> </td>
        <td><b><%=$view_invoice_nr%></b></td>
      </tr>
    </table>
  </div>
</div>
</div>
<div id="Layer4" style="position:absolute; top:300; width:723px; height:320px; z-index:2; left: 20">

  <table border="0" cellpadding="4" cellspacing="0">

<table width=600 border="0" cellpadding="4" cellspacing="0">
  <tr>
        <td></td>
    <td>
      <p><font size="4">Servicios Facturados</font> <b>&nbsp;&nbsp;&nbsp; Valores en EUROS</b> <br><br></p>
    </td>
    <td width="13%" align="right"><b>Cantidad</b></td>
  </tr>
 <%= $view_bid_desc %>
        <%= $promotion_description %>
        </table>
 </div>
<div id="Layer8" style="position:absolute; top:650; width:623px; height:200px; z-index:2; left: 25">
<table width="600" border="0" cellpadding="0">
  <tr>
    <td width="34%" height="35">
      <div align="center"><font face="Verdana, Arial, Helvetica, sans-serif" color="#009900" size="2"><i>BASE
        IMPONIBLE (&euro;)</i></font></div>
    </td>
      <div align="center"></div>
    <td width="16%">
      <div align="center"><font size="2"><font face="Verdana, Arial, Helvetica, sans-serif" color="#009900"><i>%
        IVA </i></font></font> </div>
      <div align="center"></div>
    </td>
    <td width="16%" height="35">
      <div align="center"><font size="2"><font face="Verdana, Arial, Helvetica, sans-serif" color="#009900"><i>IVA
        (&euro;) </i></font></font></div>
    </td>
      <div align="center"></div>
    </td>
    <td width="40%" height="35">
      <div align="center"><font size="2"><font face="Verdana, Arial, Helvetica, sans-serif" color="#009900"><i>TOTAL
        FACTURA (&euro;)</i></font></font></div>
    </td>
  </tr>
  <tr>
    <td width="34%">
      <table width="85%" cellspacing="0" border="1" cellpadding="10" bordercolor="#009900" align="center">
        <tr>
          <td align="center"><font face="Verdana" size="2"><b><%= $view_invoice_total %></b></font></td>
        </tr>
      </table>
    </td>
      <td width="16%">
      <table width="75%" cellspacing="0" border="1" cellpadding="10" bordercolor="#009900" align="center">
        <tr>
          <td align="center"><font face="Verdana" size="2"><b><%= $view_invoice_vat %></b></font></td>
        </tr>
      </table>
    </td>
      <td width="16%">
      <table width="75%" cellspacing="0" border="1" cellpadding="10" bordercolor="#009900" align="center">
        <tr>
          <td align="center"><font face="Verdana" size="2"><b><%= $view_invoice_vat_amount %></b></font></td>
        </tr>
      </table>
    </td>
     <td width="40%">
      <table width="75%" border="2" cellspacing="0" cellpadding="10" bordercolor="#009900" align="center">
        <tr>
          <td align="center"><font face="Verdana" size="2"><b><%= $view_invoice_grand_total %></b></font></td>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td width="27%">
      <p>&nbsp; </p>
      <p><font size="2"><font face="Verdana, Arial, Helvetica, sans-serif" color="#009900"><i>
        CONDICIONES DE PAGO : </i></font></font></p>
    </td>
    <td colspan="3" valign="bottom"><%= $view_company_payment_type %> <%= $view_payment_days %> días fecha factura.<br></td>
  </tr>
  <tr>
    <td width="27%"><font size="2"><font face="Verdana, Arial, Helvetica, sans-serif" color="#009900"><i>
      BANCO : </i></font></font></td>

 <td colspan="3">Caja de Ahorros del Mediterráneo<br>2090-6900-60-0040464112<br></td>
  </tr>
  <tr>
    <td width="27%"><font size="2"><font face="Verdana, Arial, Helvetica, sans-serif" color="#009900"><i>
      VENCIMIENTO : </i></font></font></td>
        <td colspan="3"><%= $view_invoice_due_date %></td>
  </tr>
</table>




<br>
<hr noshade size="1" color="black">

</div>
<div id="Layer5" style="position:absolute; left:30; top:880px; width:340px; height:69px; z-index:3"><span class="small"><b><font face="Arial">
Ceramica
  Clusters, S.L.</font></b></span><font face="Arial, Helvetica, sans-serif"><span class="small"><br>
  Masia Can Fatj&oacute; del Mol&iacute;<br>
  Parc Tecnol&ograve;gic del Vall&egrave;s<br>
  08290 Cerdanyola del Vall&egrave;s (Barcelona)<br>
  <b>NIF: B62304514</b><br>
  Registro Mercantil de Barcelona - Tomo 32.738, Folio 156, Hoja B-215.478, Inscripci&oacute;n
  1&ordf;.<br>
  http://www.ceramicaclusters.com </span></font></div>

<div id="Layer6" style="position:absolute; left:416px; top:880px; width:329px; height:69px; z-index:4"><span class="small"><b><font face="Arial">Ceramicaclusters
  - Castellón</font></b></span><font face="Arial, Helvetica, sans-serif"><span class="small"><br>
  Avda. Hermanos Bou, 31<br>
  12003 Castellón<br>
  Tel.964 722 572<br>
  Fax 964 722 259<br>
  e-mail: info@ceramicaclusters.com </span></font></div>



  </body>
</html>

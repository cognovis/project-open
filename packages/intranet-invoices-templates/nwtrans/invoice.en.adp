<html>
<head>
<title>INVOICE</title>
<link rel='stylesheet' href='/intranet/style/invoice.css' type='text/css'>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">

<style type="text/css">
#border_allaround {
  border-width:1px;
  border-style:solid;
  border-color:black;
  padding:4px;
  text-align:left; }
}
</style>
</head>


<body>
<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td align="center"> <img src="/intranet/images/nwtrans.logo.350.107.gif" width="350" height="107"></td>
  </tr>
</table>
<br>

<table width="100%" border="0" cellspacing="1" cellpadding="1">
  <tr>
    <td width="70%">
	&nbsp;
    </td>
    <td width="30%" valign="top">
      <table border="0" cellspacing="1" cellpadding="1" width="70%">
        <tr width="50%"> 
          <td class=roweven><strong><font size="4">INVOICE</font></strong></td>
        </tr>
      </table>
      
      <br>
      
      <table width="100%" border="0" cellpadding="1" cellspacing="0" style="border-collapse:collapse">
        <tr width="50%"> 
          <td class=roweven id=border_allaround>  <strong>DATE</strong><br>
            <strong><%=$invoice_date_pretty %></strong>  </td>
          <td class=roweven id=border_allaround>  <strong>INVOICE#</strong><br>
            <strong> <%= $invoice_nr %> </strong>  </td>
        </tr>
      </table> 
    </td>
  </tr>
</table>

<br>


<table width="100%" cellspacing=0 cellpadding=0>
<tr valign=top>
  <td>

	<table width="80%" height=200 border="0" cellpadding="1" cellspacing="0" style="border-collapse:collapse">
	  <tr height=30> 
	    <td class="roweven" id=border_allaround>  <strong>INVOICE FROM</strong></td>
	  </tr>
	  <tr valign=top> 
	    <td id=border_allaround>
	
	      <table border="0" cellspacing="1" cellpadding="1" id="table1">
	        <tr width="50%"><td class=roweven>Northwest Translations, Inc.</td></tr>
	        <tr><td class=roweven>P.O. Box 171</td></tr>
	        <tr><td class=roweven>Eagle, PA 19480</td></tr>
	        <tr><td class=rowodd>Toll Free 1-800-270-5620</td></tr>
	        <tr><td class=rowodd>Fax (509) 351-7529</td></tr>
	        <tr><td class=rowodd>sales@nwtranslations.com</td></tr>
	      </table>
	
	    </td>
	  </tr>
	</table>

  </td>
  <td align=right>

	<table width="80%" height=200 border="0" cellpadding="1" cellspacing="0" style="border-collapse:collapse">
	  <tr height=30> 
	    <td class="roweven" id=border_allaround>  <strong>INVOICE FOR </strong></td>
	  </tr>
	  <tr valign=top> 
	    <td id=border_allaround>
	      <table border="0" cellpadding="1" cellspacing="0">
	        <tr><td class="roweven"><%=$company_name%></td></tr>
	        <tr><td class=roweven><%=$company_contact_name%></td></tr>
	        <tr><td class=roweven><%=$address_line1%></td></tr>
	        <tr><td class=roweven><%=$address_line2%></td></tr>
	        <tr><td class="roweven"><%=$address_postal_code %> <%=$address_city %> </td></tr>
	        <tr><td class="rowodd"><%=$country_name%> </td></tr>
	        <tr><td class="rowodd"><%=$account_nr%> </td></tr>
	      </table>
	    </td>
	  </tr>
	</table>


  </td>
</tr>
</table>

<br>

<%
    set source_language ""
    set target_language ""
    set company_contact_name ""
    set errmsg ""

    catch {[db_1row get_project_info "
	select
		p.project_name,
		p.project_nr,
		p.start_date,
		p.end_date,
		im_category_from_id(p.source_language_id) as source_language,
		im_name_from_user_id(p.company_contact_id) as company_contact_name
	from
		im_projects p
	where
		project_id = :rel_project_id
    "]} errmsg

    set start_date_pretty [lc_time_fmt $start_date "%x" $locale]
    set end_date_pretty [lc_time_fmt $end_date "%x" $locale]
%>

<%
    set errmsg ""
    catch {[db_foreach get_target_languagesproject_info "
	select	im_category_from_id(l.language_id) as language
	from	im_target_languages l
	where	l.project_id = :rel_project_id
    " {
	append target_language "$language"
    }]} errmsg

%>


<table width="100%" border="0" cellpadding="2" cellspacing="0" style="border-collapse:collapse">
  <tr> 
    <td class="roweven" id=border_allaround>  <strong>PROJECT INFORMATION</strong></td>
  </tr>
  <tr> 
    <td class="roweven" id=border_allaround>
	Projekt Name: <%=$project_name%><br>
        Source Language: <%=$source_language%><br>
        Target Language: <%=$target_language%><br>
        Project Duration: <%=$start_date_pretty%> - <%=$end_date_pretty%><br>
      </td>
  </tr>
</table>

<br>



<table border="1" cellspacing="0" cellpadding="2" bordercolor=black style="border-collapse:collapse" width="100%">
<%=$item_list_html %>
</table>

<br>
 
<p> Disclaimer: All our work is executed with the 
  utmost professional care. However, we disclaim all liability for any legal implications 
  resulting from the use of it. Our maximum liability, whether by negligence, 
  contract or otherwise, will not exceed the return of the amount invoiced for 
  the work in dispute. Under no circunstances will we be liable for specific, 
  individual or consequential damages. </p>

</body>
</html>

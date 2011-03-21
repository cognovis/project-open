<html>
<head>
<title>Invoice</title>
<link rel='stylesheet' href='/intranet/style/invoice.css' type='text/css'>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">

<style type="text/css">
#lup_allaround {
  border-width:1px;
  border-style:solid;
  border-color:black;
  padding:4px;
  text-align:left; }
}
</style>
</head>

<%
    # Calculate Leinhaeuser und Partner specific number
    set invoice_nr_lup "$invoice_nr"

catch {
    if {[regexp {^(.)(..)(..)_(....)$} $invoice_nr match lup_prefix lup_decade lup_year lup_nr]} {
	
	set invoice_nr_lup "$lup_year$lup_nr"

    } else {

	set invoice_nr_lup "$invoice_nr"

    }
    # Cleanup the errmsg variable
    set a ""

} errmsg

%>



<body>
<table border="0" cellspacing="1" cellpadding="1" width="100%">
  <tr> 
    <td align="center">
      <font face="Verdana"><font size="2"><br>
      &nbsp;</font></font><p>&nbsp;</td>
  </tr>
</table>
<font face="Verdana" size="2">
<br>

</font>

<pre><font face="Verdana"><%=$errmsg%></font></pre>

<table width="100%" border="0" cellspacing="1" cellpadding="1">
  <tr>
    <td width="40%">

<table width="100%" border="0" cellpadding="1" cellspacing="0" style="border-collapse:collapse" id="table1">
  <tr> 
    <td class="roweven" id=lup_allaround0>
      <font face="Verdana" size="2">
      <strong>Invoice for:</strong>
    </font>
    </td>
  </tr>
  <tr> 
    <td id=lup_allaround1>
      <table border="0" cellpadding="1" cellspacing="0" id="table2">
        <tr><td class="roweven"><font face="Verdana" size="2"><%=$company_name%></font></td></tr>
        <tr><td class=roweven><font face="Verdana" size="2"><%=$company_contact_name%></font></td></tr>
        <tr><td class=roweven><font face="Verdana" size="2"><%=$address_line1%></font></td></tr>
        <tr><td class=roweven><font face="Verdana" size="2"><%=$address_line2%></font></td></tr>
        <tr><td class="roweven"><font face="Verdana" size="2"><%=$address_postal_code %> <%=$address_city %></font></td></tr>
        <tr><td class="rowodd"><font face="Verdana" size="2"><%=$country_name%></font></td></tr>
      </table>
    </td>
  </tr>
</table>
    </td>
    <td width="60%" valign="top">
      <table border="0" cellspacing="1" cellpadding="1" width="70%">
        <tr width="50%"> 
          <td class=roweven><p><strong><font size="4" face="Verdana">Invoice</font></strong></p></td>
        </tr>
      </table>
      <font face="Verdana" size="2">
      <br>
      </font>
      <table width="100%" border="0" cellpadding="1" cellspacing="0" style="border-collapse:collapse">
        <tr width="50%"> 
          <td class=roweven id=lup_allaround>
	    <font face="Verdana" size="2">
	    <strong>VAT ID:</strong><br>
	    <strong>DE812266078</strong>
	  </font>
	  </td>
          <td class=roweven id=lup_allaround>
	    <font face="Verdana" size="2">
	    <strong>Date:</strong><br>
            <strong><%=$invoice_date_pretty %></strong>
	  </font>
	  </td>
          <td class=roweven id=lup_allaround>
	    <font face="Verdana" size="2">
	    <strong>Invoice Nr:</strong><br>
            <strong><%=$invoice_nr_lup %></strong>
	  </font>
	  </td>
        </tr>
      </table> 
    </td>
  </tr>
</table>
<font face="Verdana" size="2">
<br>

</font>
<p><font face="Verdana" size="2">
<br>

<%
    set source_language ""
    set target_language ""
    set target_languages [list]
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
	lappend target_languages "$language"
    }]} errmsg

    set target_language [join $target_languages ", "]

%>

</font></p>

<table width="100%" border="0" cellpadding="2" cellspacing="0" style="border-collapse:collapse">
  <tr> 
    <td id=lup_allaround>
      <font face="Verdana" size="2">
      <strong>Project Information</strong>
    </font>
    </td>
  </tr>
  <tr> 
    <td id=lup_allaround>
	<font face="Verdana" size="2">Project: <%=$project_name%><br>
        Source Language: <%=$source_language%><br>
        Target Language: <%=$target_language%><br>
        Contact: <%=$company_contact_name%><br>
        Project Duration: <%=$start_date_pretty%> - <%=$end_date_pretty%><br>
	<table cellspacing=0 cellpadding=0 border=0>
	<tr valign=top>
	<td>Note:</td>
	<td>&nbsp;</td>
	<td><pre><span style="font-family: verdana, arial, helvetica, sans-serif"><%=$cost_note %></font></pre></td>
	</tr>
	</table>
      </font>
      </td>
  </tr>
</table>
<font face="Verdana" size="2">
<br>

</font>

<table border="1" cellspacing="0" cellpadding="2" bordercolor=black style="border-collapse:collapse" width="100%">
<%=$item_list_html %>
</table>
<font face="Verdana" size="2">
<br>

</font>

<table border="0" cellspacing="0" cellpadding="2" bordercolor=black style="border-collapse:collapse" width="100%">

<%=$payment_terms_html %>
<%=$payment_method_html %>

</table>

</body>
</html>

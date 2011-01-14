<!-- ---------------------------------------------------------------------

Printer Friendly Template for Tickets

<--- ----------------------------------------------------------------- -->

<html>
<head>
<title><%=[lang::message::lookup "" intranet-helpdesk.Ticket "Ticket"]%></title>
<link rel='stylesheet' href='/intranet/style/invoice.css' type='text/css'>
<link rel=StyleSheet type=text/css href="/intranet/style/style.saltnpepper.css">
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body text="#000000">
<p style='text-align:left'><%=[im_logo]%></p>
<br>
<table width="650px" cellpadding="5" cellspacing="5">
  <tr>
  <td><h2><%=[lang::message::lookup "" intranet-helpdesk.Ticket "Ticket"]%></h2> </td>
  <td><h2><%=[lang::message::lookup "" intranet-helpdesk.Customer "Customer"]%></h2> </td>
  </tr>

  <tr valign="top"><td colspan="2"><hr></td></tr>
  <tr valign="top">
    <td>


<table>

<tr>
<td><%= [lang::message::lookup "" intranet-helpdesk.Name "Name"] %>:</td>
<td><%= $project_name %> </td>
</tr>

<tr>
<td><%= [lang::message::lookup "" intranet-helpdesk.Sla "Sla"] %>:</td>
<td><%= $sla_name %></td>
</tr>

<tr>
<td><%=[lang::message::lookup "" intranet-helpdesk.Customer_Contact "Customer Contact"]%>:</td>
<td><%= $ticket_customer_contact_name %></td>
</tr>

<tr>
<td><%=[lang::message::lookup "" intranet-helpdesk.Ticket_Type "Type"]%>:</td>
<td><%= $ticket_type %></td>
</tr>

<tr>
<td><%=[lang::message::lookup "" intranet-helpdesk.Ticket_Status "Status"]%>:</td>
<td><%= $ticket_status %></td>
</tr>

<tr>
<td><%=[lang::message::lookup "" intranet-helpdesk.Priority "Priority"] %>:</td>
<td><%= $ticket_prio %></td>
</tr>

<tr>
<td><%=[lang::message::lookup "" intranet-helpdesk.Customer_End_Date "Customer Deadline"] %>:</td>
<td><%= [lc_time_fmt $ticket_customer_deadline %x $locale] %></td>
</tr>

<tr>
<td><%=[lang::message::lookup "" intranet-helpdesk.Assignee "Assignee"] %>:</td>
<td><%= $ticket_assignee_name %></td>
</tr>

<tr>
<td><%=[lang::message::lookup "" intranet-helpdesk.Description "Description"] %>:</td>
<td><%= $ticket_description %></td>
</tr>

<tr>
<td><%=[lang::message::lookup "" intranet-helpdesk.Note "Note"] %>:</td>
<td><%= $ticket_note %></td>
</tr>

<tr>
<td><%=[lang::message::lookup "" intranet-helpdesk.Print_date "Print date"]%></td>
<td><%=[lc_time_fmt [db_string empname "select to_char(now(), 'YYYY-MM-DD')"] %x]%></td>
</tr>
</table>


</td>
<td>

<!-- Right table with Customer Information -->
<table>
<%
set html ""
set vars {cell_phone home_phone work_phone fax ha_line1 ha_line2 ha_city ha_country_name wa_line1 wa_line2 wa_city wa_country_name}
foreach var $vars {
    set val [set $var]
    if {"" != $val} {
	append html "<tr><td>[lang::message::lookup "" intranet-helpdesk.Template_$var $var]</td><td>$val</td></tr>\n"
    }
}
%>
<%= $html %>
</table>


<!-- End of outer table -->
</table>

<br>
<%= $forum_html %>


</body>
</html>
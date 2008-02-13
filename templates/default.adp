<html>
<head>
<title>Invoice</title>
<link rel='stylesheet' href='/intranet/style/invoice.css' type='text/css'>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body text="#000000">

<h2><%= $page_title%></h2>


<table width="100%">
  <tr valign="top">
    <td width="50%">

<table>
<tr>
<td>Employee Name:</td>
<td><%=[db_string empname "select im_name_from_user_id($owner_id)"]%></td>
</tr>

<tr>
<td>Expense Report:</td>
<td><%=$bundle_id%></td>
</tr>

<tr>
<td>Purpose:</td>
<td><%=[db_string effdate "note from
im_costs where cost_id = :bundle_id" -default ""]%></td>
</tr>

<tr>
<td>Submit Date:</td>
<td><%=[db_string effdate "select to_char(effective_date, 'YYYY-MM-DD') from
im_costs where cost_id = :bundle_id" -default ""]%></td>
</tr>

<tr>
<td>Approver:</td>
<td><%=[db_string empname "select 0"]%></td>
</tr>
<tr>
<td>Approval Status:</td>
<td><%=[db_string empname "select im_category_from_id(cost_status_id) from
im_costs where cost_id = :bundle_id" -default ""]%></td>
</tr>
<tr>
<td>Project:</td>
<td><%=[db_string empname "select acs_object__name(project_id) from
im_costs where cost_id = :bundle_id" -default ""]%></td>
</tr>
<tr>
<td>Amount Due Employee:</td>
<td><%=$amount%></td>
</tr>
<tr>
<td>Print Date:</td>
<td><%=[db_string empname "select to_char(now(), 'YYYY-MM-DD')"]%></td>
</tr>
<tr>
<td>Contains Billable Expenses:</td>
<td><%=[db_string empname "select count(*) from im_expenses e where
e.bundle_id = :bundle_id and e.billable_p = 't'"]%></td>
</tr>
</table>

    </td>
    <td width="50%">
    </td>
  </tr>
</table>


<%
	set expense_lines_sql "
	select
		c.*,
		e.*,
		to_char(effective_date, :date_format) as effective_date,
		im_category_from_id(expense_type_id) as expense_type,
		p.project_name,
		cat.aux_int1 as vat_code
	from
		im_expenses e
		LEFT OUTER JOIN im_categories cat ON (e.expense_type_id = cat.category_id),
		im_costs c
		LEFT OUTER JOIN im_projects p ON (c.project_id = p.project_id)
	where
		e.expense_id = c.cost_id and
		e.bundle_id = :bundle_id
	order by
		c.effective_date
	"
	set table ""
	db_foreach expense_lines $expense_lines_sql {
	    append table "<tr class=roweven>\n"
	    append table "<td>$effective_date</td>\n"
	    append table "<td>$expense_type</td>\n"
	    append table "<td>$amount</td>\n"
	    append table "<td>$vat_code</td>\n"
	    append table "<td>$note</td>\n"
	    append table "</tr>\n"
	}
%>


<table>
<tr class=rowtitle>
<td>Effective_date</td>
<td>Expense_type</td>
<td>Amount</td>
<td>Vat Code</td>
<td>Note</td>
</tr>
<%= $table %>
</table>

</body>
</html>

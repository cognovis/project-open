<%
    set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
%>
<html>
<head>
<title><%=[lang::message::lookup "" intranet-core.Expense_Bundle "Expense Bundle"]%></title>
<link rel='stylesheet' href='/intranet/style/invoice.css' type='text/css'>
<link rel=StyleSheet type=text/css href="/intranet/style/style.saltnpepper.css">
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body text="#000000">
<p style='text-align:left'><%=[im_logo]%></p>
<br>
<h2><%=[lang::message::lookup "" intranet-core.Expense_Bundle "Expense Bundle"]%></h2>
<table width="650px" cellpadding="5" cellspacing="5">
  <tr valign="top"><td colspan="2"><hr></td></tr>
  <tr valign="top">
    <td>
<table>
<tr>
<td><%=[lang::message::lookup "" intranet-core.Employee "Employee Name"]%>:</td>
<td><%=[db_string empname "select im_name_from_user_id($owner_id)"]%></td>
</tr>

<tr>
<td><%=[lang::message::lookup "" intranet-expenses.Expense_Report "Expense Report"]%>:</td>
<td><%=$bundle_id%></td>
</tr>

<tr>
<td><%=[lang::message::lookup "" intranet-core.Description "Description"]%>:</td>
<td><%=[db_string note "select note from im_costs where cost_id = :bundle_id" -default ""]%></td>
</tr>

<tr>
<td><%=[lang::message::lookup "" intranet-core.Date_submitted "Date submitted"]%>:</td>
<td><%=[lc_time_fmt [db_string effdate "select to_char(effective_date, 'YYYY-MM-DD') from im_costs where cost_id = :bundle_id" -default ""] %x]%></td>
</tr>
<!--
<tr>
<td><%=[lang::message::lookup "" intranet-core.rfc_hj_approvedby "Approved by"]%>:</td>
<td><%=[db_string empname "select 0"]%></td>
</tr>-->
<tr>
<td><%=[lang::message::lookup "" intranet-core.Status "Status"]%>:</td>
<td><%=[db_string empname "select im_category_from_id(cost_status_id) from
im_costs where cost_id = :bundle_id" -default ""]%></td>
</tr>
<tr>
<td><%=[lang::message::lookup "" intranet-core.Project "Project"]%>:</td>
<td><%=[db_string empname "select acs_object__name(project_id) from
im_costs where cost_id = :bundle_id" -default ""]%></td>
</tr>
<tr>
<td><%=[lang::message::lookup "" intranet-core.Customer "Customer"]%>:</td>
<td><%=[db_string empname "
        select  acs_object__name(p.company_id)
        from    im_costs c,
                im_projects p
        where
                c.cost_id = :bundle_id and
                c.project_id = p.project_id
" -default ""]%></td>
</tr>
<tr>
<td><%=[lang::message::lookup "" intranet-core.Amount_due "Amount due"]%>&nbsp;<%=[lang::message::lookup "" intranet-core.Employee "Employee"]%>:</td>
<td><%=[lc_numeric [db_string total "select
                trunc(sum(im_exchange_rate(c.effective_date::date, c.currency, :default_currency) * c.amount)::numeric, 2)
        from
                im_expenses e
                LEFT OUTER JOIN im_categories cat ON (e.expense_type_id = cat.category_id),
                im_costs c
                LEFT OUTER JOIN im_projects p ON (c.project_id = p.project_id)
        where
                e.expense_id = c.cost_id and
                e.bundle_id = :bundle_id
"] {} [lang::user::locale]] %>&nbsp;<%=$default_currency%></td>
</tr>
<tr>
<td><%=[lang::message::lookup "" intranet-core.Print_date "Print date"]%></td>
<td><%=[lc_time_fmt [db_string empname "select to_char(now(), 'YYYY-MM-DD')"] %x]%></td>
</tr>
<tr>
<td><%=[lang::message::lookup "" intranet-cost.Number_billable_expenses "Number billable expenses"]%>:</td>
<td><%=[db_string empname "select count(*) from im_expenses e where
e.bundle_id = :bundle_id and e.billable_p = 't'"]%></td>
</tr>

</table>

    </td>
  </tr>
  <tr valign="top"><td colspan="2"><hr></td></tr>
</table>
<%
        set expense_lines_sql "
        select
                c.*,
                e.*,
                trunc((im_exchange_rate(c.effective_date::date, c.currency, :default_currency) * c.amount)::numeric, 2) as amount_formatted,
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
            append table "<td>[lc_time_fmt $effective_date %x]</td>\n"
            append table "<td>$expense_type</td>\n"
            append table "<td>[lc_numeric $amount_formatted {} [lang::user::locale] ]&nbsp;$default_currency</td>\n"
            append table "<td>$vat_code</td>\n"
            append table "<td>$note</td>\n"
            append table "</tr>\n"
        }
%>
<br>
<table width="650px" cellpadding="5" cellspacing="5">
<tr class=rowtitle>
<td><%=[lang::message::lookup "" intranet-cost.Effective_Date "Effective Date"]%></td>
<td><%=[lang::message::lookup "" intranet-expenses.Expense_Type "Expense Type"]%></td>
<td><%=[lang::message::lookup "" intranet-cost.Amount "Amount"]%></td>
<td><%=[lang::message::lookup "" intranet-core.VAT_Number "VAT Number"]%></td>
<td><%=[lang::message::lookup "" intranet-core.Note "Note"]%></td>
</tr>
<%= $table %>
</table>

</body>
</html>
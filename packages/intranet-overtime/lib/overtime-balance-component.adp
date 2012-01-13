<form action="/intranet-overtime/booking">

<input type="hidden" name="user_id_from_form" value="@user_id_from_search@" />
<input type="hidden" name="type" value="overtime" />

<table>
<tr class=rowtitle>
	<td colspan=2 class=rowtitle><%= [lang::message::lookup "" intranet-overtime.Overtime_Balance "Overtime Balance"] %></td>
</tr>
<tr class=roweven>
	<td><%= [lang::message::lookup "" intranet-timesheet2.User User] %></td>
	<td>@user_name@</td>
</tr>
<tr class=rowodd>
	<td><%= [lang::message::lookup "" intranet-timesheet2.Time_Period "Period"] %></td>
	<td>@start_of_year@ - @end_of_year@</td>
</tr>

<tr class=roweven>
	<td><%= [lang::message::lookup "" intranet-overtime.Overtime_Days_Takeb "Days taken"] %></td>
	<td>@overtime_days_taken@</td>
</tr>

<tr class=rowodd>
        <td><%= [lang::message::lookup "" intranet-overtime.Overtime_Balance "Balance"] %></td>
        <td>@overtime_days_balance@</td>
</tr>

<tr class=rowodd>
        <td><%= [lang::message::lookup "" intranet-overtime.Add_Overtime "Add Overtime (days)"] %></td>
        <td><input name="overtime" size="4" /></td>
</tr>

<tr class=roweven>
        <td><%= [lang::message::lookup "" intranet-core.Comment "Comment"] %></td>
        <td><input name="comment" size="20" /></td>
</tr>

<tr align="left">
        <td colspan=2><input value="<%=[lang::message::lookup "" intranet-core.Submit "Submit"]%>" type="submit"></td>
</tr>
</table>
</form>

<br>
<listtemplate name="overtime_balance"></listtemplate>


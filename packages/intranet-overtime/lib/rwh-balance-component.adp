<table>
<tr class=rowtitle>
        <td colspan=2 class=rowtitle><%= [lang::message::lookup "" intranet-timesheet2.Rwh_Balance "RWH Balance"] %></td>
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
        <td><%= [lang::message::lookup "" intranet-timesheet2.Rwh_Days_per_Year "RWH Days this Year"] %></td>
        <td>@rwh_days_per_year@</td>
</tr>
<tr class=rowodd>
        <td><%= [lang::message::lookup "" intranet-timesheet2.Rwh_Balance_From_Last_Year "RWH Balance from Last Year"] %></td>
        <td>@rwh_days_last_year@</td>
</tr>
<tr class=rowodd>
        <td><%= [lang::message::lookup "" intranet-timesheet2.Rwh_Taken_This_Year "RWH Taken This Year"] %></td>
        <td>@rwh_days_taken@</td>
</tr>
<tr class=rowodd>
        <td><%= [lang::message::lookup "" intranet-timesheet2.Rwh_Left_for_Period "RWH Days Left for Period"] %></td>
        <td>@rwh_days_left@</td>
</tr>
</table>
<br>
<listtemplate name="rwh_balance"></listtemplate>

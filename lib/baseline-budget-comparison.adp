<table border=0 cellspacing=1 cellpadding=1>
<thead>
<tr class=rowtitle>
	<td class=rowtitle>&nbsp;</td>
	<td class=rowtitle>#intranet-baseline.Baseline_values#</td>
	<td class=rowtitle>#intranet-baseline.Current_values#</td>
</tr>
</thead>
<tbody>
<if "" ne @baseline_project_budget@ and "" ne @current_project_budget@>
<tr>
	<td class=rowodd align=left>#intranet-baseline.Budget#</td>
	<td class=rowodd align=right>@baseline_project_budget@ @baseline_project_budget_currency@</td>
	<td class=rowodd align=right>@current_project_budget@ @current_project_budget_currency@</td>
</tr>
</if>
<if "" ne @baseline_budget_hours@ and "" ne @current_budget_hours@>
<tr>
	<td class=roweven align=left>#intranet-baseline.Budget_Hours#</td>
	<td class=roweven align=right>@baseline_budget_hours@</td>
	<td class=roweven align=right>@current_budget_hours@</td>
</tr>
</if>
<tr>
	<td class=rowodd align=left>#intranet-baseline.Start_Date#</td>
	<td class=rowodd align=right>@baseline_start_date@</td>
	<td class=rowodd align=right>@current_start_date@</td>
</tr>
<tr>
	<td class=roweven align=left>#intranet-baseline.End_Date#</td>
	<td class=roweven align=right>@baseline_end_date@</td>
	<td class=roweven align=right>@current_end_date@</td>
</tr>
</tbody>
</table>
